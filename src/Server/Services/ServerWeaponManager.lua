local ReplicatedStorage = game:GetService("ReplicatedStorage");
local Shared = ReplicatedStorage:WaitForChild("Aero"):WaitForChild("Shared");
local ServerStorage = game:GetService("ServerStorage");

local Aero = ServerStorage:WaitForChild("Aero");
local Modules = Aero:WaitForChild("Modules");

local Weapon = require(Modules:WaitForChild("Weapon"));

local Weapons = game:GetService("ServerStorage"):WaitForChild("Weapons");
local FastCast = require(ReplicatedStorage:WaitForChild("FastCast"));
local Cast = require(Shared:WaitForChild("Cast"));

local CollectionService = game:GetService("CollectionService");
local HttpService = game:GetService("HttpService");

local Events = ReplicatedStorage:WaitForChild("Events");

local Thread = require(Shared:WaitForChild("Thread"));
local Status = require(Shared:WaitForChild("Status"));
local CanRayPierce = require(Shared:WaitForChild("CanRayPierce"));

local PlayerService = game:GetService("Players");

local WeaponManager = {
	Client = {},
	Data = {},
	Ragdolls = {},
};

function WeaponManager:GetPlayerData(Player:Player)
	return self.Data[Player] or self:CreateStockData(Player);
end

function WeaponManager:Start()
	PlayerService.PlayerRemoving:Connect(function(Player:Player)
		if (not self.Data[Player]) then return; end;

		local PlayerData = self.Data[Player];

		PlayerData.Maid:Destroy();
		table.clear(PlayerData);

		self.Data[Player] = nil;
		PlayerData = nil;
	end)

	local Fired:RemoteEvent = Events:WaitForChild("Fired");
	Fired.OnServerEvent:Connect(function(...)
		self:FiredRequest(...);
	end)

	Events:WaitForChild("Shot").OnServerInvoke = (function(...)
		return self:PlayerDidHitSomeone(...);
	end)

	Thread.Spawn(function()
		local RunService = game:GetService("RunService");

		self.ServerUpdateTick = RunService.Heartbeat:Connect(function() -- TODO: Maybe calculate how many times the player shot based on delta time
			for Player:Player, PlayerData in pairs(self.Data) do
				if (PlayerData.Firing) then
					self:Fired(Player);
				end
			end
		end)
	end)
end

function WeaponManager:PlayerDidHitSomeone(Player:Player, CastUserData, Character:Model, HitPosition:Vector3, HitPart:BasePart, Origin, Direction)
	local PlayerData = self:GetPlayerData(Player);
	local ShotPlayer = PlayerService:GetPlayerFromCharacter(Character);

	if (ShotPlayer and ShotPlayer == Player) then
		return;
	end

	if (Character:GetAttribute("Ragdolled") ~= true and Character and PlayerData.WeaponConfig and Character.PrimaryPart) then
		PlayerData.LastShot = time();
		local Humanoid = Character:FindFirstChildWhichIsA("Humanoid");

		if (Humanoid) then
			local RaycastParams = RaycastParams.new();
			RaycastParams.FilterType = Enum.RaycastFilterType.Blacklist;
			RaycastParams.FilterDescendantsInstances = {
				workspace.CurrentCamera,
				Player.Character,
				table.unpack(CollectionService:GetTagged("NotCollidable")),
			};

			local CastingConfig = PlayerData.WeaponConfig.CastingConfig;
			local _, _Cast = Cast:Raycast(
				Origin,
				Direction * CastingConfig.BulletDistance, nil, {
					Precison = CastingConfig.BulletPrecison or 45,
					StudsPerSecond = CastingConfig.BulletSpeed or 2600,
					CanRayPierce = function(...)
						return self:CanRayPierce(...);
					end,
					Instant = true,
					Acceleration = CastingConfig.BulletAcceleration
				}, RaycastParams, {
					RayOrigin = Origin,
					Direction = Direction,
					Humanoids = {},
				}
			);

			local Hit = false;
			Hit = (table.find(_Cast.UserData.Humanoids, Humanoid));

			if (Hit == nil) then return; end;

			local Distance = (CastUserData.RayOrigin - Character.PrimaryPart.Position).Magnitude;
			if (Distance > (PlayerData.WeaponConfig.CastingConfig.BulletMaxDist + 25)) then -- Error margin of 25 just because
				print("Player shot too far"); -- TODO: Cheat detection
				return;
			end

			local Damage = PlayerData.WeaponConfig.Damage or 0;
			Damage *= math.clamp((5-((CastUserData.Hits and CastUserData.Hits - 1) or 0))/5, 0.1, 1);
			-- Damage *=

			local DistancePercentage = (Distance/PlayerData.WeaponConfig.CastingConfig.BulletMaxDist); -- Damage drop off over distance
			local Falloff = 1 - (DistancePercentage ^ 2 * (3 - 2 * DistancePercentage));
			Damage *= Falloff;

			Humanoid:TakeDamage(Damage);

			Thread.Spawn(function()
				-- Events:WaitForChild("BloodEffect"):FireAllClients(HitPosition, Character);

				if (Character and Character:FindFirstChildWhichIsA("Humanoid")) then
					self:Ragdoll(Character, CastUserData.Direction, HitPosition, HitPart);
				end
			end)

			return Damage;
		end
	end
end

function WeaponManager:CanRayPierce(Cast, RaycastResult:RaycastResult, ...) -- TODO
	local CanPierce = CanRayPierce(Cast, RaycastResult, ...);

	Cast.UserData.Damaged = Cast.UserData.Damaged or {};

	local Humanoid = RaycastResult.Instance.Parent:FindFirstChildWhichIsA("Humanoid") or RaycastResult.Instance.Parent.Parent:FindFirstChildWhichIsA("Humanoid");
	Cast.UserData.Humanoids[#Cast.UserData.Humanoids+1] = Humanoid;

	return Humanoid and true or CanPierce;
end

local Ragdoll = require(Shared:WaitForChild("Ragdoll"));
function WeaponManager:Ragdoll(Character:Model, Direction:Vector3, HitPosition:Vector3, HitPart:BasePart)
	local Humanoid = Character:FindFirstChildWhichIsA("Humanoid");
	if (Humanoid and Character:GetAttribute("Ragdolled") ~= true) then
		if (Humanoid.Health <= 0) then
			local CharacterRagdoll = Ragdoll.new(Character);

			CharacterRagdoll:setRagdolled(true);

			self.Ragdolls[#self.Ragdolls+1] = {CharacterRagdoll, time()};
			self:DidRagdoll();

			Character:SetAttribute("Ragdolled", true);
			Character.UpperTorso:ApplyImpulseAtPosition(Direction * 700, HitPosition); --TODO(deter): Make it not a constant force.

			Thread.Delay(50, function()
				CharacterRagdoll:destroy();
				CharacterRagdoll = nil;
				Character:Destroy();
				Character = nil;
			end)
		end
	end
end

function WeaponManager:DidRagdoll()
	if (#self.Ragdolls > 15) then
		local lowest, currentObject = math.huge, nil;
		for i, v in ipairs(self.Ragdolls) do
			if (v[2] < lowest) then lowest = v[2]; currentObject = i; end;
		end

		if (lowest and currentObject) then
			self.Ragdolls[currentObject][1]:destroy();
			table.remove(self.Ragdolls, currentObject);
		end
	end
end

function WeaponManager:FiredRequest(Player, State:boolean|nil)
	local PlayerData = self:GetPlayerData(Player);

	if (State ~= nil) then
		PlayerData.Firing = State;
		return;
	else
		self:Fired(Player);
	end
end

function WeaponManager:Fired(Player:Player)
	local PlayerData = self:GetPlayerData(Player);

	if (not PlayerData.WeaponConfig) then return Status(400); end;
	if (not PlayerData.Equipped) then return Status(400); end;
	if (not PlayerData.Weapon) then return Status(400); end;

	if (not PlayerData.Weapon:CanFire()) then
		return;
	else
		PlayerData.Weapon:Fire();
	end

	if (not PlayerData.LastShot or (time() - PlayerData.LastShot >= 60/PlayerData.WeaponConfig.FireRate)) then
		PlayerData.LastShot = time();

		local Muzzle = PlayerData.Weapon.ServerModel:WaitForChild("Handle"):FindFirstChild("Muzzle");

		if (PlayerData.WeaponConfig.OnFired) then
			PlayerData.WeaponConfig.OnFired(PlayerData);
		end

		if (Muzzle) then
			for _, ParticleEmitter:ParticleEmitter|Light in ipairs(Muzzle:GetChildren()) do
				if (ParticleEmitter:IsA("ParticleEmitter")) then
					ParticleEmitter:Emit(ParticleEmitter:GetAttribute("Emit"));
				elseif (ParticleEmitter:IsA("Light")) then
					ParticleEmitter.Enabled = true;
				end
			end

			Thread.Delay(PlayerData.WeaponConfig.MuzzleFlashTime or .15, function()
				for _, ParticleEmitter:ParticleEmitter|Light in ipairs(Muzzle:GetChildren()) do
					if (ParticleEmitter:IsA("Light")) then
						ParticleEmitter.Enabled = false;
					end
				end

				Muzzle = nil; -- release from memory
			end)
		end

		local Sound = PlayerData.Weapon.ServerModel:WaitForChild("Sounds", 2):FindFirstChild("Fire");
		if (Sound) then
			Sound = Sound:Clone();
			Sound.Parent = PlayerData.Weapon.ServerModel.Handle;
			Sound:Play();

			local Stopped; Stopped = Sound.Stopped:Connect(function()
				Stopped:Disconnect();
				Sound:Destroy();
				Sound = nil;
				Stopped = nil;

				return;
			end)
		end

		return;
	end
end

function WeaponManager:CreateStockData(Player:Player)
	local PlayerData = {
		Weapon = nil,
		WeaponConfig = nil,
		WeaponData = {},
		Maid = self.Shared.Maid.new(),
		CachedAnimations = {},
		LoadedAnimations = {},
		WeaponAmmo = {},
		Aiming = false,
	};

	-- local AmmoDirectory = Instance.new("Folder");

	-- local InClip:IntValue = Instance.new("IntValue");
	-- local Reserve:IntValue = Instance.new("IntValue");

	-- InClip.Name = "InClip";
	-- Reserve.Name = "Reserve";

	-- AmmoDirectory.Name = Player.Name;

	-- Reserve.Value = self.Services.InventoryManager:GetItemQuantity(Player, "Ammo");
	-- InClip.Value = -1;

	-- InClip.Parent = AmmoDirectory;
	-- Reserve.Parent = AmmoDirectory;

	-- AmmoDirectory.Parent = ReplicatedStorage:WaitForChild("Ammo");

	-- PlayerData.AmmoDirectory = AmmoDirectory;

	Player.CharacterAdded:Connect(function(Character:Model)
		table.clear(self.Data[Player].CachedAnimations);

		for _, AnimationTrack:AnimationTrack in ipairs(PlayerData.LoadedAnimations) do
			AnimationTrack:Destroy();
		end

		self.Data[Player].Firing = false;

		table.clear(PlayerData.LoadedAnimations);
	end)

	self.Data[Player] = PlayerData;
	return self.Data[Player];
end

function WeaponManager:EquipWeapon(Player:Player, WeaponName:string)
	WeaponName = type(WeaponName) == "number" and ServerStorage:WaitForChild("Weapons"):WaitForChild("Client"):GetChildren()[WeaponName].Name or WeaponName;
	if (not Player.Character or not Player.Character.PrimaryPart or not Player.Character:FindFirstChild("Humanoid")) then return 400; end;

	local PlayerData = self:GetPlayerData(Player);
	local PlayerWeapon = Weapon.new(Player, WeaponName, {AmmoInClip = 300});

	print(WeaponName);

	if (type(PlayerWeapon) == "number") then
		return PlayerWeapon;
	end

	PlayerData.Equipped = WeaponName;
	PlayerData.Weapon = PlayerWeapon;

	PlayerData.WeaponConfig = PlayerWeapon.Config;

	local WeaponMotor6DDirectory = Player.Character:WaitForChild("RightHand");
	local WeaponMotor6D = WeaponMotor6DDirectory:FindFirstChild("Weapon") or Instance.new("Motor6D");

	WeaponMotor6D.Name = "Weapon";

	WeaponMotor6D.Part0 = WeaponMotor6DDirectory;
	WeaponMotor6D.Part1 = PlayerWeapon.ServerModel.Handle;

	WeaponMotor6D.Parent = WeaponMotor6DDirectory;

	for _, Animation:Animation in ipairs(PlayerWeapon.PreferredWeapon:WaitForChild("ServerAnimations"):GetChildren()) do
		local CachedAnimation = PlayerData.CachedAnimations[Animation.AnimationId];

		if (CachedAnimation) then
			PlayerData.LoadedAnimations[Animation.Name] = CachedAnimation;
		else
			local LoadedAnimation = Player.Character.Humanoid:WaitForChild("Animator"):LoadAnimation(Animation);

			PlayerData.LoadedAnimations[Animation.Name] = LoadedAnimation;
			PlayerData.CachedAnimations[Animation.AnimationId] = LoadedAnimation;
		end
	end

	if (PlayerData.LoadedAnimations.Idle) then
		PlayerData.LoadedAnimations.Idle:Play();
	end

	return PlayerWeapon;
end

function WeaponManager:GetAmmoData(PlayerData, WeaponConfig)
	return {
		InClip = 30,
	};
end

function WeaponManager:SetAiming(Player:Player, IsAiming:boolean)
	local PlayerData = self:GetPlayerData(Player);

	if (not PlayerData.WeaponConfig.DisableAiming) then
		PlayerData.Aiming = IsAiming;

		local AimingAnimation = PlayerData.LoadedAnimations.Aiming;

		if (AimingAnimation) then
			if (PlayerData.Aiming) then
				AimingAnimation:Play();
			else
				AimingAnimation:Stop();
			end
		end

		return 200, PlayerData.Aiming;
	end

	return 400;
end

function WeaponManager:GetWeaponConfig(Player:Player, WeaponName:string)
	-- TODO: Verify if the player can access this config

	local Weapon = Weapons:FindFirstChild(WeaponName);

	if (Weapon) then
		return 200, require(Weapon:FindFirstChild("Config"));
	end

	return 404;
end

-- Client functions

function WeaponManager.Client:Equipped(...)
	return WeaponManager:EquipWeapon(...);
end

function WeaponManager.Client:SetAiming(...)
	return WeaponManager:SetAiming(...);
end

return WeaponManager;