local ReplicatedStorage = game:GetService("ReplicatedStorage");
local ServerStorage = game:GetService("ServerStorage");

local ServerWeapons = ServerStorage:WaitForChild("Weapons"):WaitForChild("Server");
local ClientWeapons = ServerStorage:WaitForChild("Weapons"):WaitForChild("Client");

local PreferConfig = 0;
local Weapon = {
	AmmoInClip = 0,
};
Weapon.__index = Weapon;

function Weapon.new(Player:Player, WeaponName:string, AmmoData, Config)
	local self = setmetatable({
		WeaponName = WeaponName,
		Player = Player,
		AmmoInClip = AmmoData.AmmoInClip
	}, Weapon);

	self.ClientModel = ClientWeapons:FindFirstChild(WeaponName);
	self.ServerModel = ServerWeapons:FindFirstChild(WeaponName);

	--print(self.ClientWeapon, ClientWeapons, self.ServerModel);

	if (not self.ClientWeapon and not self.ServerModel) then
		return 404;
	elseif (not self.ClientWeapon and self.ServerModel) then
		self.ClientModel = self.ServerModel;
	elseif (not self.ServerModel) then
		self.ServerModel = self.ClientWeapon;
	end

	self.ClientModel = self.ClientModel:Clone();
	self.ServerModel = self.ServerModel:Clone();

	self.ServerModel.Name = self.Player.Name;
	self.ServerModel:WaitForChild("Handle").CFrame = CFrame.new(0, 45, 0);
	self.ClientModel:WaitForChild("Handle").CFrame = CFrame.new(0, 45, 0);

	self.ServerModel.Parent = ReplicatedStorage.Cache;
	self.ClientModel.Parent = ReplicatedStorage.Cache;

	self.PreferredWeapon = PreferConfig == 0 and self.ClientModel or self.ServerModel;

	local Module = self.PreferredWeapon:FindFirstChild("Config");
	self.Config = Config or (Module and require(Module));

	if (not self.Config) then
		return 400;
	end

	print("RETURNING MODEL", self);

	return self;
end

function Weapon:Fire()
	self.AmmoInClip -= self.Config.CastingConfig.BulletsPerShot;
end

function Weapon:CanFire()
	return self.AmmoInClip > 0;
end

return Weapon;