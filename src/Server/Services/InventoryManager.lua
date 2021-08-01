-- Inventory Manager
-- Deter
-- June 20, 2021

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Aero"):WaitForChild("Shared");
local InventorySlot = require(Shared:WaitForChild("InventorySlot"));
local TableUtil = require(Shared:WaitForChild("TableUtil"));

local ProfileService = require(game:GetService("ServerStorage"):WaitForChild("Aero"):WaitForChild("Modules"):WaitForChild("ProfileService"));

local PlayerService = game:GetService("Players");

local InventoryManager = {
	Data = {},
	Client = {},
}

export type Item = {
	Class: string,
	Quantity: number,
	Icon: string,
};

function InventoryManager:Start()
	local PlayerInventoryStore = ProfileService.GetProfileStore("PlayerInventory", self:GetMockPlayerData());

	PlayerService.PlayerAdded:Connect(coroutine.wrap(function(Player)
		local Profile = PlayerInventoryStore:LoadProfileAsync(
			("player-"..Player.UserId.."-v6"),
			"ForceLoad"
		);

		if (Profile ~= nil) then
			Profile:Reconcile();

			Profile:ListenToRelease(function()
				InventoryManager.Data[Player] = nil;
				Player:Kick("Game data is being utilized in another server.");
			end)

			 if (Player:IsDescendantOf(PlayerService)) then
				InventoryManager.Data[Player] = Profile;
			else
				Profile:Release();
			end
		end
	end));

	PlayerService.PlayerRemoving:Connect(function(Player)
		InventoryManager.Data[Player] = nil;
	end)
end

local RunService = game:GetService("RunService");

export type Inventory = {[number]:{Item}};

--- Get a Player's inventory
--@param Player The Player whom's inventory we should get.
function InventoryManager:GetInventory(Player:Player):Inventory
	if (not InventoryManager.Data[Player]) then -- to stop it from waiting cuz roblox bad
		repeat RunService.Heartbeat:Wait();
			print("Waiting for inventory");
		until InventoryManager.Data[Player];
	end
	
	return InventoryManager.Data[Player].Data;
end
InventoryManager.Client.GetInventory = InventoryManager.GetInventory;


export type ReadableInventory = {[number]: Item};

--- Get a players inventory in a readable format
--@param Player the player to get the player's inventory
function InventoryManager:GetReadableInventory(Player:Player):GetReadableInventory
	local PlayerData = self:GetInventory(Player);
	local ReadableInventory = {};

	print(PlayerData.Inventory);

	for i = 1, 25 do -- TODO(deter): Make a variable for all inventory slots
		local Item = PlayerData.Inventory[i];

		print(Item, Item.Quantity);

		if (Item and Item.Item) then
			ReadableInventory[#ReadableInventory+1] = Item;
		end
	end

	return ReadableInventory;
end

function InventoryManager:GetItemDataFromClass(Player:Player, ClassName:string)
	local ReadablePlayerData = self:GetReadableInventory(Player);

	for _, Item in ipairs(ReadablePlayerData) do
		if (Item.Item.ClassName == ClassName) then
			return Item.Item;
		end
	end
end

--- Get An Item's Quantity
-- @param Player the player's inventory to search
-- @param The Item to search for
function InventoryManager:GetItemQuantity(Player:Player, ItemClass:string):number
	local ReadableInventory = self:GetReadableInventory(Player);

	local Quantity = 0;

	print(ReadableInventory);

	for _, Item in ipairs(ReadableInventory) do
		if (Item.Item.Class == ItemClass) then
			Quantity += Item.Quantity;
		end
	end

	return Quantity;
end

function InventoryManager:GetMockPlayerData()
	local MockData =  {
		Inventory = {}
	};

	for index = 1, 25 do
		local Chance = math.random(1, 4);
		local Slot = InventorySlot.new(index);

		if (Chance == 1) then
			Slot.Item = {
				Icon = "rbxassetid://267895468",
				Class = "Ammo",
				Quantity = math.random(1, 10);
			};
		elseif (Chance == 2) then
			Slot.Item = {
				Icon = "rbxassetid://6840728426",
				Class = "Rock",
				Quantity = math.random(1, 10);
			};
		end

		MockData.Inventory[index] = Slot;
	end

	return MockData;
end

function InventoryManager.Client:ExchangeSlot(Player:Player, SlotAIndex:number, SlotBIndex:number)
	local Inventory = InventoryManager.Data[Player].Data.Inventory;

	local SlotA = Inventory[SlotAIndex];
	local SlotB = Inventory[SlotBIndex];

	if (SlotAIndex == SlotBIndex) then return; end;

	if (SlotA and SlotB) then
		local SlotABefore = TableUtil.Copy(SlotA);
		Inventory[SlotAIndex].Item = Inventory[SlotBIndex].Item;
		Inventory[SlotAIndex].Quantity = Inventory[SlotBIndex].Quantity;

		Inventory[SlotBIndex].Item = SlotABefore.Item;
		Inventory[SlotBIndex].Quantity = SlotABefore.Quantity;

		if (SlotA.Item and SlotB.Item and SlotA.Item.ClassName == SlotB.Item.ClassName) then
			Inventory[SlotAIndex].Item = nil;
			Inventory[SlotBIndex].Quantity += Inventory[SlotAIndex].Quantity;
			Inventory[SlotAIndex].Quantity = 0;
		end

		SlotABefore = nil;
	end

	InventoryManager.Data[Player].Data.Inventory = Inventory;
end

return InventoryManager