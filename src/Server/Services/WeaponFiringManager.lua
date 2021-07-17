local ReplicatedStorage = game:GetService("ReplicatedStorage");
local Shared = ReplicatedStorage:WaitForChild("Aero"):WaitForChild("Shared");

local Thread = require(Shared:WaitForChild("Thread"));
local Base64 = require(Shared:WaitForChild("Base64"));
local CanRayPierce = require(Shared:WaitForChild("CanRayPierce"));
local FastCast = require(ReplicatedStorage:WaitForChild("FastCast"));

local Events = ReplicatedStorage:WaitForChild("Events");

local RunService = game:GetService("RunService");
local PlayerService = game:GetService("Players");

local FiringHandler = {};

function FiringHandler:CanRayPierce(Cast, RaycastResult, ...) -- TODO
	local CanPierce = CanRayPierce(Cast, RaycastResult, ...);

	Cast.UserData.Damaged = Cast.UserData.Damaged or {};

	
	if (CanPierce and not Cast.UserData.Damaged[RaycastResult.Instance.Parent]) then
		local Humanoid = RaycastResult.Instance.Parent:FindFirstChild("Humanoid");

		if (Humanoid) then
			Cast.UserData.Damaged[RaycastResult.Instance.Parent] = true;
			Events:WaitForChild("Shot"):FireServer(Cast.UserData.RaycastOrigin, Cast.UserData.RaycastDirection);
		end
	end
end

local TAU = math.pi * 2;
local RNG = Random.new();
--* Main
function FiringHandler:Fire(Player, Direction:Vector3, MuzzlePosition:Vector3, CastBehavior) -- TODO
	if (not self.WeaponManager.Equipped) then
		warn("Tried to shoot with no weapon equipped.");
		return;
	end

	local WeaponCastingConfig = self.WeaponManager:GetWeaponConfig(Player).CastingConfig;

	if (not WeaponCastingConfig) then
		warn("No casting config found.");
		return;
	end

	self.CastBehavior.Acceleration = WeaponCastingConfig.BulletGravity or Vector3.new(0, -workspace.Gravity, 0);
	self.CastBehavior.MaxDistance = WeaponCastingConfig.MaxDistance or 400;
	CastBehavior.CanPierceFunction = WeaponCastingConfig.CanPierceFunction or function(...)
		return self:CanRayPierce(...);
	end;

	local Cast = self.Caster:Fire(MuzzlePosition, Direction, math.huge, self.CastBehavior);

	Cast.UserData.RayOrigin = MuzzlePosition;
	Cast.UserData.Direction = Direction;
end

function FiringHandler:OnRayHit(Cast, RaycastResult) -- TODO
	if (RaycastResult.Instance.Parent:FindFirstChild("Humanoid")) then
		-- RaycastResult.Instance.Parent:FindFirstChild("Humanoid"):TakeDamage(15);
	end
	print("Ray hit something -----", RaycastResult.Instance);
end

function FiringHandler:OnRayTerminated(Cast) -- TODO
	self:ReturnBullet(Cast.UserData.Bullet);
end

function FiringHandler:CreateCaster()
	self.Caster = FastCast.new();
	self.CastBehavior = FastCast.newBehavior();

	local CollectionService = game:GetService("CollectionService");

	local RaycastParams = RaycastParams.new();
	RaycastParams.FilterType = Enum.RaycastFilterType.Blacklist;
	RaycastParams.FilterDescendantsInstances = {
		table.unpack(CollectionService:GetTagged("NotCollidable")),
	};
	CollectionService:GetInstanceAddedSignal("NotCollidable"):Connect(function()
		RaycastParams.FilterDescendantsInstances = {
			table.unpack(CollectionService:GetTagged("NotCollidable")),
		};
	end);

	self.CastBehavior.RaycastParams = RaycastParams;
	self.CastBehavior.HighFidelityBehavior = FastCast.HighFidelityBehavior.Default;
	self.CastBehavior.Acceleration = Vector3.new(0, -workspace.Gravity, 0);

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


function FiringHandler:Start()
	self:CreateCaster();

	Events:WaitForChild("Shot").OnServerEvent:Connect(function(Player, OriginPosition, Direction)
		
	end)

	print("Firing handler inited");
end

return FiringHandler;