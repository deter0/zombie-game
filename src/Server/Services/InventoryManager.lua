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


function InventoryManager:Start()
    local PlayerInventoryStore = ProfileService.GetProfileStore("PlayerInventory", self:GetMockPlayerData());

	PlayerService.PlayerAdded:Connect(coroutine.wrap(function(Player)
        local Profile = PlayerInventoryStore:LoadProfileAsync(
            ("player-"..Player.UserId.."--v$test5"),
            "ForceLoad"
        );

        if (Profile ~= nil) then
            Profile:Reconcile();

            Profile:ListenToRelease(function()
                InventoryManager.Data[Player] = nil;
                Player:Kick("lol???? ?? idk");
            end)

             if (Player:IsDescendantOf(PlayerService)) then
                InventoryManager.Data[Player] = Profile;
                warn("PROFILe", Profile);
            else
                Profile:Release();
            end
        end
    end));

    PlayerService.PlayerRemoving:Connect(function(Player)
        InventoryManager.Data[Player] = nil;
    end)
end

function InventoryManager.Client:GetInventory(Player:Player)
    repeat wait(0);
        print("Waiting for inventory");
    until InventoryManager.Data[Player].Data.Inventory;

    return InventoryManager.Data[Player].Data.Inventory;
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
                Class = "Ammo"
            }
            Slot.Quantity = math.random(1, 10);
        elseif (Chance == 2) then
            Slot.Item = {
                Icon = "rbxassetid://6840728426",
                Class = "Rock"
            }
            Slot.Quantity = math.random(1, 10);
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