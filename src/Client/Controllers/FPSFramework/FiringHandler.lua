local ReplicatedStorage = game:GetService("ReplicatedStorage");
local Shared = ReplicatedStorage:WaitForChild("Aero"):WaitForChild("Shared");

local Thread = require(Shared:WaitForChild("Thread"));
local Base64 = require(Shared:WaitForChild("Base64"));

local CanRayPierce = require(Shared:WaitForChild("CanRayPierce"));
local FastCast = require(ReplicatedStorage:WaitForChild("FastCast"));

FastCast.VisualizeCasts = false;
FastCast.DebugLogging = false;

local BulletImpacts = require(script.Parent:WaitForChild("BulletImpacts"));
BulletImpacts:Start();

local Hitmarker = require(Shared:WaitForChild("Hitmarker"));

local CollectionService = game:GetService("CollectionService");

local Events = ReplicatedStorage:WaitForChild("Events");

local RunService = game:GetService("RunService");
local PlayerService = game:GetService("Players");

local Player = PlayerService.LocalPlayer;
local Controllers:Folder = Player:WaitForChild("PlayerScripts"):WaitForChild("Aero"):WaitForChild("Controllers");

local Indicator = require(Controllers:WaitForChild("Indicator"));

local FiringHandler = {
	Bullets = {},
	BulletsInUse = 0,
	FastCastFunctions = {},
};

function FiringHandler:GetBullet()
	-- warn("Trying to get bullet", self.Bullets, self.BulletsInUse);
	local Bullet = self.Bullets[((self.BulletsInUse + 1) % #self.Bullets) + 1];
	Bullet:SetAttribute("Active", true);
	Bullet.Transparency = 0;

	if (not Bullet) then
		warn("All bullets in use can't do anything.");
		return nil;
	end

	self.BulletsInUse += 1;

	return Bullet;
end

local VERY_FAR = Vector3.new(90, -50, 0);
function FiringHandler:ReturnBullet(Bullet)
	local Trail = Bullet:FindFirstChildWhichIsA("Trail");
	if (Trail) then
		Trail.Enabled = false;
	end
	
	Bullet:SetAttribute("Active", false);
	Bullet.CFrame = CFrame.new(VERY_FAR);
end

function FiringHandler:CanRayPierce(Cast, RaycastResult:RaycastResult, ...) -- TODO
	local CanPierce = CanRayPierce(Cast, RaycastResult, ...);

	Cast.UserData.Damaged = Cast.UserData.Damaged or {};

	local Humanoid = RaycastResult.Instance.Parent:FindFirstChildWhichIsA("Humanoid") or RaycastResult.Instance.Parent.Parent:FindFirstChildWhichIsA("Humanoid");
	
	if (not Cast.UserData.Damaged[RaycastResult.Instance.Parent]) then
		if (Humanoid) then
			Cast.UserData.Damaged[RaycastResult.Instance.Parent] = true;
			Cast.UserData.Hits = Cast.UserData.Hits and Cast.UserData.Hits + 1 or 1;

			Thread.SpawnNow(function()
				local Damage = Events:WaitForChild("Shot"):InvokeServer(
					Cast.UserData,
					Humanoid.Parent,
					RaycastResult.Position,
					RaycastResult.Instance
				);
				
				if (Damage) then
					Hitmarker:Hit(RaycastResult.Position, Damage);

					if (Humanoid.Health <= 0 and not Humanoid:GetAttribute("Dead")) then
						Humanoid:SetAttribute("Dead", true);
						
						local KilledPlayer:Player = PlayerService:GetPlayerFromCharacter(Humanoid.Parent);
						Indicator:Indicate("Killed %s [+100]", KilledPlayer and KilledPlayer.DisplayName or Humanoid.Parent.Name);
					end
				end
			end)
		end
	end

	if (not Humanoid) then
		BulletImpacts:Impacted(RaycastResult.Position, RaycastResult.Normal);
		BulletImpacts:BulletHole(RaycastResult.Position, RaycastResult.Normal, RaycastResult.Instance);
	end

	return Humanoid and true or CanPierce;
end

local TAU = math.pi * 2;
local RNG = Random.new();
local RNG2 = Random.new();

local Camera = workspace.CurrentCamera or workspace:WaitForChild("Camera");
--* Main
function FiringHandler:Fire(Direction:Vector3, MuzzlePosition:Vector3, MinSpread:number, MaxSpread:number) -- TODO
	if (not self.WeaponManager.Equipped) then
		warn("Tried to shoot with no weapon equipped.");
		return;
	end

	self.WeaponCastingConfig = self.WeaponManager.WeaponConfig.CastingConfig;

	if (not self.WeaponCastingConfig) then
		warn("No casting config found.");
		return;
	end

	self.CastBehaviour.Acceleration = self.WeaponCastingConfig.BulletGravity or Vector3.new(0, -workspace.Gravity, 0);
	self.CastBehaviour.MaxDistance = self.WeaponCastingConfig.BulletMaxDist or 400;
	self.CastBehaviour.CanPierceFunction = self.WeaponCastingConfig.CanPierceFunction or function(...)
		return self:CanRayPierce(...);
	end;
	self.CastBehaviour.RaycastParams.FilterDescendantsInstances = {
		Camera,
		Player.Character,
		table.unpack(CollectionService:GetTagged("NotCollidable")),
	};

	local DirectionCFrame = CFrame.lookAt(Vector3.new(), Direction);

	for _ = 1, self.WeaponCastingConfig.BulletsPerShot do
		local x = math.rad(RNG:NextNumber(MinSpread, MaxSpread));
		local y = math.rad(RNG2:NextNumber(MinSpread, MaxSpread));

		local NewDirection = (
			DirectionCFrame * CFrame.fromOrientation(
				x,
				y,
				0
			)
		).LookVector;

		local Cast = self.Caster:Fire(MuzzlePosition, NewDirection, self.WeaponCastingConfig.BulletSpeed, self.CastBehaviour);

		local Bullet = self:GetBullet();

		Bullet.AssemblyLinearVelocity = Vector3.new();
		Bullet.AssemblyAngularVelocity = Vector3.new();
		Bullet.CFrame = CFrame.lookAt(MuzzlePosition, MuzzlePosition + NewDirection) * CFrame.new(0, 0, -(Bullet.Size.Z*0.5));

		local Trail = Bullet:FindFirstChildWhichIsA("Trail");
		if (Trail) then
			Trail.Enabled = true;
		end

		Cast.UserData.Bullet = Bullet;
		Cast.UserData.RayOrigin = MuzzlePosition;
		Cast.UserData.Direction = NewDirection;
	end
end

function FiringHandler:OnRayHit(Cast, RaycastResult) -- TODO
	BulletImpacts:BulletSparks(RaycastResult.Position, RaycastResult.Normal, RaycastResult.Material);
end

function FiringHandler:OnRayTerminated(Cast) -- TODO
	self:ReturnBullet(Cast.UserData.Bullet);
	Cast.UserData.Bullet = nil;
end

-- * Can use OnRayPierced for velocity changes

function FiringHandler:OnRayUpdated(Cast, SegmentOrigin, SegmentDirection, Length)
	local Bullet = Cast.UserData.Bullet;

	if (Bullet) then
		local BulletLength = Bullet.Size.Z / 2;
		local baseCFrame = CFrame.lookAt(SegmentOrigin, SegmentOrigin + SegmentDirection);
		
		Bullet.CFrame = baseCFrame * CFrame.new(0, 0, -(Length - BulletLength));
	end
end

function FiringHandler:CreateCaster()
	self.Caster = FastCast.new();
	self.CastBehaviour = FastCast.newBehavior();

	local RaycastParams = RaycastParams.new();
	RaycastParams.FilterType = Enum.RaycastFilterType.Blacklist;
	RaycastParams.FilterDescendantsInstances = {
		workspace.CurrentCamera,
		Player.Character,
		table.unpack(CollectionService:GetTagged("NotCollidable")),
	};
	CollectionService:GetInstanceAddedSignal("NotCollidable"):Connect(function()
		RaycastParams.FilterDescendantsInstances = {
			workspace.CurrentCamera,
			Player.Character,
			table.unpack(CollectionService:GetTagged("NotCollidable")),
		};
	end);

	self.CastBehaviour.RaycastParams = RaycastParams;
	self.CastBehaviour.HighFidelityBehavior = FastCast.HighFidelityBehavior.Default;
	self.CastBehaviour.Acceleration = Vector3.new(0, -workspace.Gravity, 0);

	self.Caster.RayHit:Connect(function(...)
		self:OnRayHit(...);
	end)
	self.Caster.LengthChanged:Connect(function(...)
		self:OnRayUpdated(...);
	end)
	self.Caster.CastTerminating:Connect(function(...)
		self:OnRayTerminated(...);
	end)
	-- self.Caster.RayPierced:Connect(function(...) self:OnRayPierced(...); end; -- * Make sure to connect this event if you put in ray pierecd function
end


function FiringHandler:Start(WeaponManager)
	self.WeaponManager = WeaponManager;

	self:CreateCaster();

	local BulletsContainer = ReplicatedStorage:WaitForChild("Bullets"):WaitForChild(Base64:Encode(tostring(Player.UserId)));
	self.Bullets = BulletsContainer:GetChildren();
	BulletsContainer.ChildAdded:Connect(function(Child)
		self.Bullets[#self.Bullets + 1] = Child;
	end)
	BulletsContainer.Parent = workspace:WaitForChild("Bullets");
	Events:WaitForChild("Bullets"):InvokeServer(BulletsContainer);

	-- warn("Bullets:", self.Bullets);

	self:MaintainBulletPositions();

	print("Firing handler inited");
end

function FiringHandler:MaintainBulletPositions()
	Thread.Spawn(function()
		RunService.Heartbeat:Connect(function()
			for _, Bullet:BasePart in ipairs(self.Bullets) do
				if (not Bullet:GetAttribute("Active")) then
					Bullet.CFrame = CFrame.new(VERY_FAR); -- force update
				end
			end
		end)
	end)
end

return FiringHandler;