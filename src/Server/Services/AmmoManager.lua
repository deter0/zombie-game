-- Ammo Handler
-- deter
-- July 30, 2021

local ReplicatedStorage = game:GetService("ReplicatedStorage");
local Shared = ReplicatedStorage:WaitForChild("Aero"):WaitForChild("Shared");

local Base64 = require(Shared:WaitForChild("Base64"));

local AmmoHandler = {Data = {}};

function AmmoHandler:Start()
	local PlayerService = game:GetService("Players");

	PlayerService.PlayerAdded:Connect(coroutine.wrap(function(Player)
		local PlayerName = Base64:Encode(tostring(Player.UserId));
		local AmmoFolder:Folder = Instance.new("Folder");
		AmmoFolder.Name = PlayerName;

		local ToCreate = {["ClipAmmo"] = 0, ["ClipSize"] = 0, ["AmmoInInventory"] = self.Services.InventoryManager:GetItemQuantity(Player, "Ammo")};
		local AmmoData = {
			Weapons = {},
			CurrentWeapon = nil,
		};

		for index, value in pairs(ToCreate) do
			local ValueInstance:IntValue = Instance.new("IntValue");
			ValueInstance.Name = index;
			ValueInstance.Value = value;

			AmmoData[index] = ValueInstance;

			ValueInstance.Parent = AmmoFolder;
		end

		AmmoFolder.Parent = ReplicatedStorage:WaitForChild("Ammo");
		self.Data[Player] = AmmoData;
	end));
end

local HttpService = game:GetService("HttpService");
function AmmoHandler:PlayerEquippedWeapon(Player:Player, WeaponName:string, WeaponConfig, WeaponIdentifier:string?):string
	local PlayerWeaponData = self.Data[Player];

	WeaponIdentifier = WeaponIdentifier or HttpService:GenerateGUID(false);

	-- TODO(deter): Add a max ammo capacity with a large limit

	PlayerWeaponData.Weapons[WeaponIdentifier] = PlayerWeaponData.Weapons[WeaponIdentifier] or {
		ClipAmmo = 30,
		ClipSize = WeaponConfig.ClipSize or 30,
		Name = WeaponName,
		Identifier = WeaponIdentifier
	};

	print(PlayerWeaponData.Weapons[WeaponIdentifier]);
	PlayerWeaponData.CurrentWeapon = WeaponIdentifier;

	self:SetData(Player, PlayerWeaponData.Weapons[WeaponIdentifier]);

	return WeaponIdentifier;
end

function AmmoHandler:SetData(Player:Player, Data):nil
	local PlayerData = self.Data[Player];
	-- local CurrentWeapon = PlayerData.CurrentWeapon;
	PlayerData.Weapons[PlayerData.CurrentWeapon].ClipAmmo = PlayerData.ClipAmmo.Value;

	PlayerData.ClipAmmo.Value = Data.ClipAmmo;
	PlayerData.ClipSize.Value = Data.ClipSize;
end

function AmmoHandler:SubtractAmmo(Player:Player, Count:number):boolean
	Count = Count or 1;

	local Data = self.Data[Player];

	if (Data.ClipAmmo.Value - Count > 0) then
		Data.ClipAmmo.Value -= Count;

		return true;
	end
end

function AmmoHandler:GetAmmoData(Player:Player)
	return self.Data[Player];
end

return AmmoHandler