-- Item Entity Manager
-- Deter
-- July 6, 2021

local ReplicatedStorage = game:GetService("ReplicatedStorage");
local Events = ReplicatedStorage:WaitForChild("Events");

export type Item = {ClassName:string, Id:string};
local ItemEntityManager = {
    Items = {},
    DroppedItems = {},
    Client = {}
}

local function GetSendableVersion(Item)
    return {
        Id = Item.Id,
        ClassName = Item.ClassName,
        Model = Item.Model,
        State = Item.State
    };
end

function ItemEntityManager:Start()
	local Crate = self.Shared.Items.Crate.new(self);
    Crate:Drop(Vector3.new(0, 5, 0));
end

function ItemEntityManager:GetAllDroppedItems()
    local DroppedItems = {};
    for _, Item in pairs(self.DroppedItems) do
        print("Sendable Item:", Item, GetSendableVersion(Item));
        table.insert(DroppedItems, GetSendableVersion(Item));
    end

    warn(DroppedItems);

    return DroppedItems;
end

function ItemEntityManager.Client:GetAllDroppedItems(...)
    return ItemEntityManager:GetAllDroppedItems(...);
end

function ItemEntityManager:ItemDropped(Item:Item)
    if (not self.DroppedItems[Item.ClassName]) then
        self.DroppedItems[Item.ClassName] = {};
    end

    self.DroppedItems[Item.ClassName][Item.Id] = Item;
    warn("Dropped item");
    Events:WaitForChild("ItemDropped"):FireAllClients(Item.GetSendableVersion and Item:GetSendableVersion() or GetSendableVersion(Item));
    warn("Sent event");
end

function ItemEntityManager:ReportItemMade(Item:Item)
	if (not self.Items[Item.ClassName]) then
        self.Items[Item.ClassName] = {};
    end

    self.Items[Item.ClassName][Item.Id] = Item;
end


return ItemEntityManager