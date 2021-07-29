-- Profile Manager
-- Deter
-- July 27, 2021

-- ! Deprecated

local VERSION = 0;
local PROD = false; -- ! Set production to true when publishing for production builds

local ReplicatedStorage = game:GetService("ReplicatedStorage");
local Shared = ReplicatedStorage:WaitForChild("Aero"):WaitForChild("Shared");

local PlayerData = {};
PlayerData.__index = PlayerData;

function PlayerData.new(Player:Player)
	local self = setmetatable({
		Player = Player,
		Key =  string.format("%s-%d-%s", PROD and "PROD" or "DEV", Player.UserId, tostring(VERSION)) -- * Main store key generation
	}, PlayerData);

	return self;
end

function UNSET_PROFILE(Name:string)
	return {
		MockData = {},
		Name = Name,
		Unset = true,
	}
end

local ProfileManager = {
	Client = {},
	Profiles = {
		["Inventory"] = UNSET_PROFILE("Inventory"),
	},
}


function ProfileManager:Start()
	local PlayerService = game:GetService("Players");
	
	PlayerService.PlayerAdded:Connect(function(...)
		self:PlayerAdded(...);
	end)
end

function ProfileManager:PlayerAdded(Player:Player)
	coroutine.resume(coroutine.create(function()
		local AddedPlayerData = PlayerData.new(Player);
	end))
end

function ProfileManager:Init()
	self.ProfileService = self.Modules.ProfileService;
end

function ProfileManager:SetProfile(ProfileData)
	self.Profiles[ProfileData.Name] = ProfileData;
end

return ProfileManager