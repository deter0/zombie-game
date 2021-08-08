local ReplicatedStorage = game:GetService("ReplicatedStorage");
local Shared = ReplicatedStorage:WaitForChild("Aero"):WaitForChild("Shared");

local Thread = require(Shared:WaitForChild("Thread"));

local RunService = game:GetService("RunService");

local Particles = ReplicatedStorage:WaitForChild("Particles");
local SoundsEffects = ReplicatedStorage:WaitForChild("SFX");

local CollectionService = game:GetService("CollectionService");

local ImpactPart:BasePart = Instance.new("Part");
ImpactPart.Anchored = true;
ImpactPart.CanCollide = false;
ImpactPart.Transparency = 1;

ImpactPart.Parent = workspace;

local Fastcast = require(ReplicatedStorage:WaitForChild("FastCast"));
local PartCacheModule = require(ReplicatedStorage:WaitForChild("PartCache"));

local BulletImpacts = {
	Sounds = {
		[Enum.Material.Grass] = "Grass",

		[Enum.Material.Concrete] = "Concrete",
		[Enum.Material.Brick] = "Concrete",
		[Enum.Material.Rock] = "Concrete",
		[Enum.Material.Asphalt] = "Concrete",
		[Enum.Material.Slate] = "Concrete",
		[Enum.Material.Cobblestone] = "Concrete",

		[Enum.Material.Wood] = "Wood",
		[Enum.Material.WoodPlanks] = "Wood",

		[Enum.Material.Metal] = "Metal",
		[Enum.Material.CorrodedMetal] = "Metal",

		[Enum.Material.Ground] = "Ground",
		[Enum.Material.LeafyGrass] = "Ground",
		[Enum.Material.Grass] = "Grass",

		[Enum.Material.Glass] = "Glass",

		["Default"] = "Concrete"
	}
};

local BulletImpactSounds:Folder = SoundsEffects:WaitForChild("BulletImpacts");

local VERY_FAR = Vector3.new(1e6, 1e6, 1e6);
local BulletHoles = {};
for i = 1, 50 do
	local BulletHole = workspace:WaitForChild("BulletHole"):Clone();
	BulletHole.Position = VERY_FAR;
	BulletHole.Parent = workspace:WaitForChild("Ignore");
	BulletHoles[#BulletHoles + 1] = BulletHole;
end

local CurrentBulletHole = 1;
local function GetBulletHole()
	local Bullet = BulletHoles[(CurrentBulletHole % #BulletHoles)+1];
	CurrentBulletHole += 1;

	return Bullet;
end

function BulletImpacts:Impacted(Position:Vector3, Normal:Vector3, Material:Enum.Material)
	local Attachment:Attachment = Instance.new("Attachment");
	Attachment.WorldPosition = Position;
	local SoundFolder = BulletImpactSounds:FindFirstChild(self.Sounds[Material] or "Concrete") or BulletImpactSounds:FindFirstChild("Concrete");
	if (SoundFolder) then
		local Sounds = SoundFolder:GetChildren();
		local Sound = Sounds[math.random(#Sounds)]:Clone();
		Sound.Parent = Attachment;

		Sound:Play();
		Sound.Ended:Connect(function()
			Attachment:Destroy();
		end)
	end

	Attachment.Parent = ImpactPart;

	-- self:BulletSparks(Position, Normal);
end

function BulletImpacts:BulletHole(Position:Vector3, Normal:Vector3, Part:BasePart)
	local BulletHole = GetBulletHole();
	BulletHole:FindFirstChildWhichIsA("WeldConstraint").Part0 = Part;
	BulletHole.Anchored = Part.Anchored;
	BulletHole.CFrame = CFrame.lookAt(Position, Position + Normal) * CFrame.new(0, 0, -0.01);
end

function BulletImpacts:Start()
	self.Caster = Fastcast.new();

	self.CastParams = RaycastParams.new();
	self.CastParams.IgnoreWater = true;
	self.CastParams.FilterType = Enum.RaycastFilterType.Blacklist;
	self.CastParams.FilterDescendantsInstances = CollectionService:GetTagged("NotCollidable");

	self.SparkProvider = PartCacheModule.new(workspace:WaitForChild("BulletSpark"), 60, workspace:WaitForChild("Sparks"));

	self.CastBehavior = Fastcast.newBehavior();
	self.CastBehavior.RaycastParams = self.CastParams;
	self.CastBehavior.MaxDistance = 25;
	self.CastBehavior.HighFidelityBehavior = Fastcast.HighFidelityBehavior.Default;

	self.CastBehavior.CosmeticBulletProvider = self.SparkProvider;

	self.CastBehavior.CosmeticBulletContainer = workspace.Sparks;
	self.CastBehavior.Acceleration = Vector3.new(0, -196.6/3, 0);
	self.CastBehavior.AutoIgnoreContainer = true;

	-- self.Caster.RayHit:Connect(function(...)
	-- 	self:OnSparkCastHit(...);
	-- end);

	self.Caster.CastTerminating:Connect(function(...)
		self:OnRayTerminated(...);
	end);

	self.Caster.LengthChanged:Connect(function(...)
		self:OnSparkRayUpdated(...);
	end);

	self.CastBehavior.CanPierceFunction = function(...)
		return self:CanRayPierce(...);
	end

	self.Caster.RayPierced:Connect(function(...)
		self:OnRayPierced(...);
	end)
end

local function Reflect(surfaceNormal, bulletNormal)
	return bulletNormal - (2 * bulletNormal:Dot(surfaceNormal) * surfaceNormal)
end

function BulletImpacts:CanRayPierce(cast, rayResult, segmentVelocity)
	local hits = cast.UserData.Hits;
	if (hits == nil) then
		cast.UserData.Hits = 1;
	else
		cast.UserData.Hits += 1;
	end
	
	if (cast.UserData.Hits > 1) then
		return false;
	end

	return true;
end

function BulletImpacts:OnRayPierced(cast, raycastResult, segmentVelocity, cosmeticBulletObject)
	local position = raycastResult.Position
	local normal = raycastResult.Normal
	
	local newNormal = Reflect(normal, segmentVelocity.Unit)
	cast:SetVelocity(newNormal * segmentVelocity.Magnitude)
	
	-- It's super important that we set the cast's position to the ray hit position. Remember: When a pierce is successful, it increments the ray forward by one increment.
	-- If we don't do this, it'll actually start the bounce effect one segment *after* it continues through the object, which for thin walls, can cause the bullet to almost get stuck in the wall.
	cast:SetPosition(position)
end

function BulletImpacts:OnRayTerminated(Cast)
	local Spark = Cast.RayInfo.CosmeticBulletObject;

	if (Spark) then
		if (self.CastBehavior.CosmeticBulletProvider ~= nil) then
			self.CastBehavior.CosmeticBulletProvider:ReturnPart(Spark);
		else
			Spark:Destroy();
		end
	end
end

function BulletImpacts:OnSparkRayUpdated(Cast, SegmentOrigin, SegmentDirection, Length, SegmentVelocity, SparkObject)
	if (SparkObject == nil) then return; end;

	local BulletLength = SparkObject.Size.Z / 2 -- This is used to move the bullet to the right spot based on a CFrame offset
	local BaseCFrame = CFrame.lookAt(SegmentOrigin, SegmentOrigin + SegmentDirection)

	local Velocity = (SegmentVelocity.Magnitude/70);
	SparkObject.Size = Vector3.new(SparkObject.Size.X, SparkObject.Size.Y, 2 + Velocity);
	SparkObject.CFrame = BaseCFrame * CFrame.new(0, 0, -(Length - BulletLength));
end

local TweenService = game:GetService("TweenService");
local FadeOutTweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Cubic, Enum.EasingDirection.InOut, 0, false, 0);

local RNG = Random.new();
local Camera = workspace.CurrentCamera or workspace:WaitForChild("Camera");
function BulletImpacts:BulletSparks(Position:Vector3, Normal:Vector3)
	local NumOfSparks = 3;

	local OriginalDirection = Reflect(Normal, (Position - Camera.CFrame.Position).Unit);
	local DirectionalCFrame = CFrame.lookAt(Vector3.new(), OriginalDirection);

	for _ = 1, NumOfSparks do
		local Direction = DirectionalCFrame * CFrame.fromOrientation(
			math.rad(RNG:NextNumber(-15, 15)),
			math.rad(RNG:NextNumber(-15, 15)),
			0
		).LookVector;

		local Cast = self.Caster:Fire(Position, Direction, 120, self.CastBehavior);
		local Bullet = Cast.RayInfo.CosmeticBulletObject;

		Bullet.Transparency = workspace.BulletSpark.Transparency;

		local FadeOutTween = TweenService:Create(Bullet, FadeOutTweenInfo, {Transparency = 1});
		FadeOutTween:Play();
		local Completed; Completed = FadeOutTween.Completed:Connect(function()
			Completed:Disconnect();
			Completed = nil;

			FadeOutTween:Destroy();
			FadeOutTween = nil;
		end)
	end
end

return BulletImpacts;