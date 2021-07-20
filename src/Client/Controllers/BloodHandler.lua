-- Blood Handler
-- Deter
-- June 22, 2021

local ReplicatedStorage = game:GetService("ReplicatedStorage");
local CollectionService = game:GetService("CollectionService");

local Shared = ReplicatedStorage:WaitForChild("Aero"):WaitForChild("Shared");

local Thread = require(Shared:WaitForChild("Thread"));
local Ragdoll = require(Shared:WaitForChild("Ragdoll"));

local Fastcast = require(ReplicatedStorage:WaitForChild("FastCast"));
local PartCacheModule = require(ReplicatedStorage:WaitForChild("PartCache"));

local Events = ReplicatedStorage:WaitForChild("Events");
local ParticlesFolder = ReplicatedStorage:WaitForChild("Particles");

local BloodHandler = {
    ActiveRagdolls = {},
    ActiveParticles = {}
};

function BloodHandler:Start()
    self.Caster = Fastcast.new();

    self.CastParams = RaycastParams.new();
    self.CastParams.IgnoreWater = true;
    self.CastParams.FilterType = Enum.RaycastFilterType.Blacklist;
    self.CastParams.FilterDescendantsInstances = CollectionService:GetTagged("NotCollidable");

    self.BloodProvider = PartCacheModule.new(ParticlesFolder:WaitForChild("BloodHighFidelity"):WaitForChild("BloodPart"), 30, workspace:WaitForChild("Blood"));

    self.CastBehavior = Fastcast.newBehavior();
    self.CastBehavior.RaycastParams = self.CastParams;
    self.CastBehavior.MaxDistance = 100;
    self.CastBehavior.HighFidelityBehavior = Fastcast.HighFidelityBehavior.Default

    -- self.CastBehavior.CosmeticBulletTemplate = ParticlesFolder:WaitForChild("BloodHighFidelity"):WaitForChild("BloodPart") -- Uncomment if you just want a simple template part and aren't using PartCache
    self.CastBehavior.CosmeticBulletProvider = self.BloodProvider -- Comment out if you aren't using PartCache.

    self.CastBehavior.CosmeticBulletContainer = workspace.Blood;
    self.CastBehavior.Acceleration = Vector3.new(0, -workspace.Gravity, 0);
    self.CastBehavior.AutoIgnoreContainer = true;
    self.CastBehavior.AutoIgnoreContainer = false
    
    self.Caster.RayHit:Connect(function(...)
        self:OnBloodCastHit(...);
    end);

    self.Caster.CastTerminating:Connect(function(...)
        self:OnRayTerminated(...);
    end);

    self.Caster.LengthChanged:Connect(function(...)
        self:OnBloodRayUpdated(...);
    end);

	Events:WaitForChild("BloodEffect").OnClientEvent:Connect(function(...)
        self:CastBlood(...);
    end)

    -- game:GetService("ContextActionService"):BindAction("Clickity click click", function(_, State)
    --     if (State == Enum.UserInputState.Begin) then
    --         self:CastBlood(game:GetService("Players").LocalPlayer:GetMouse().Hit.Position);
    --     end
    -- end, false, Enum.UserInputType.MouseButton1)
    -- TODO : Ragdoll
end

local AllBones = {"l1", "l2", "l3", "l4", "r1", "r2", "r3", "r4"};
function BloodHandler:MakeParticle(Position:Vector3, Normal:Vector3, Ignore)
    
    local BloodModel = ParticlesFolder:WaitForChild("BloodHighFidelity"):WaitForChild("BloodRigged"):Clone();

    local NormalCFrame = CFrame.lookAt(Vector3.new(), Normal);
    BloodModel.PrimaryPart.CFrame = CFrame.fromMatrix(Position, Normal, NormalCFrame.RightVector, NormalCFrame.UpVector) * CFrame.Angles(0, 0, math.rad(90)); -- to lazy for fromMatrix cuz i forgot how to use it
    BloodModel.PrimaryPart.Size *= .3 + math.random();

    BloodModel.PrimaryPart.CFrame *= CFrame.Angles(0, math.random()*(math.pi*2), 0);

    print(Ignore);

    -- for _, BoneName in ipairs(AllBones) do
    --     local Bone = BloodModel.PrimaryPart:FindFirstChild(BoneName);

    --     if (Bone) then
    --         local RaycastDown = workspace:Raycast(Bone.WorldPosition, (Bone.WorldPosition - (CFrame.new(Bone.WorldPosition) * CFrame.new(0, -10, 0)).Position).Unit * -12, self.CastParams);

    --         if (RaycastDown) then
    --             Bone.WorldPosition = (CFrame.new((RaycastDown.Position)) * CFrame.new(0, .1, 0)).Position;
    --         end
    --     else
    --         warn(BoneName, "Not found");
    --     end
    -- end

    game:GetService("Debris"):AddItem(BloodModel, 60);

    BloodModel.Parent = workspace.Blood;
    -- TODO: Set it to the ground thing or whatever
end

local TAU = math.pi * 2;
function BloodHandler:RawCast(Position:Vector3, Ignore)
    local RandomDirection = math.random() * TAU;
    local Direction = Vector3.new(math.sin(RandomDirection), math.random()/3+.3, math.cos(RandomDirection));

    self.CastParams.FilterDescendantsInstances = {
        table.unpack(CollectionService:GetTagged("NotCollidable")),
        Ignore
    };

    self.CastBehavior.CastParams = self.CastParams;
    local Blood = self.Caster:Fire(Position, Direction, Direction * math.random(4, 10), self.CastBehavior);
    Blood.UserData.Ignore = Ignore;

    -- warn("Can do stuff with blood", Blood);
end

function BloodHandler:OnBloodCastHit(Cast, RaycastResult, SegmentVelocity, BloodObject)
    warn("Blood hit something !!!", RaycastResult.Instance);
    self:MakeParticle(RaycastResult.Position, RaycastResult.Normal, Cast.UserData.Ignore);
end


local BonesToMove = {"l1", "l2", "l3", "l4"};
function BloodHandler:OnBloodRayUpdated(Cast, SegmentOrigin, SegmentDirection, Length, SegmentVelocity, BloodObject)
    if (BloodObject == nil) then return; end;

    local BulletLength = BloodObject.Size.Z / 2 -- This is used to move the bullet to the right spot based on a CFrame offset
	local BaseCFrame = CFrame.lookAt(SegmentOrigin, SegmentOrigin + SegmentDirection)

    BloodObject.CFrame = BaseCFrame * CFrame.new(0, 0, -(Length - BulletLength)) * CFrame.Angles(0, math.pi/2, 0);
    BloodObject.Size = Vector3.new(7.538 + (SegmentVelocity.Magnitude/5), 0.189, 4.226)/3;

    -- warn("UPDATE RAY", SegmentVelocity);
end

function BloodHandler:OnRayTerminated(Cast)
    local Blood = Cast.RayInfo.CosmeticBulletObject;

    if (Blood) then
        if (self.CastBehavior.CosmeticBulletProvider ~= nil) then
			self.CastBehavior.CosmeticBulletProvider:ReturnPart(Blood);
		else
			Blood:Destroy();
		end
    end
end

function BloodHandler:CastBlood(Position:Vector3, Ignore)
    for _ = 1, 8 do
        self:RawCast(Position, Ignore);
    end
end

return BloodHandler