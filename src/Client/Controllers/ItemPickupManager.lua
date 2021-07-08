local Camera = workspace.CurrentCamera or workspace:WaitForChild("Camera");
local RunService = game:GetService("RunService");
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local Adornments = ReplicatedStorage:WaitForChild("Adornments");

local ItemPickupManager = {
    Range = 24,
    DroppedItems = {}
};

function ItemPickupManager:Start()
    for _, Item in pairs(self.Services.ItemEntityManager:GetAllDroppedItems()) do
        warn(Item);

        if (not Item.Id or not Item.ClassName) then return; end;
        
        self.DroppedItems[Item.Id] = Item;
        print("ITem already exists");
    end

    ReplicatedStorage:WaitForChild("Events"):WaitForChild("ItemDropped").OnClientEvent:Connect(function(Item)
        warn("Item Dropped", Item);
        self.DroppedItems[Item.Id] = Item;
    end)

    self.Shared.Thread.Spawn(function()
        RunService.Heartbeat:Connect(function(...)
            self:Update(...);
        end)
    end)
end

function ItemPickupManager:GetIndicatorGui()
    local Gui = Adornments:WaitForChild("PickableItems"):WaitForChild("IndicatorGuiOriginal"):Clone();
    Gui.Name = "Indicator";

    Gui.Parent = Adornments.PickableItems;

    return Gui;
end

function ItemPickupManager:Update(DeltaTime:number)
    local DroppedItems = self.DroppedItems;

    for _, Item in pairs(DroppedItems) do
        local Close = (Item.Model.PrimaryPart.Position - Camera.CFrame.Position).Magnitude <= 24;

        print((Item.Model.PrimaryPart.Position - Camera.CFrame.Position));

        local IndicatorGui = Item.IndicatorGui;

        if (not Item.IndicatorGui) then
            if (Close) then
                IndicatorGui = self:GetIndicatorGui();
            else
                continue;
            end;
        end
        Item.IndicatorGui = IndicatorGui;

        IndicatorGui.Adornee = Item.Model;
        
        local UIStroke = IndicatorGui.KeybindContainer.UIStroke;
        UIStroke.Transparency = UIStroke.Transparency:Lerp(Close and .15 or 1);
    end
end

return ItemPickupManager;