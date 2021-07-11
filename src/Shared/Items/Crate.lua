local ServerStorage = game:GetService("ServerStorage");

local Crate = {
    ClassName = "Crate",
    State = nil,
    Model = ServerStorage:WaitForChild("ItemModels"):WaitForChild("WoodCrate")
};
Crate.__index = Crate;

function Crate:Drop(Position:Vector3)
    self.Model.PrimaryPart.CFrame = CFrame.new(Position);
    -- self.Model.Parent = workspace:WaitForChild("DroppedItems");
    
    self.State = "Dropped";
    self.Reporter:ItemDropped(self);
end

function Crate.new(Reporter)
    local HTTPService = game:GetService("HttpService");

    local self = setmetatable({
        Id = HTTPService:GenerateGUID(false),
        State = "Active",
        Reporter = Reporter
    }, Crate);
    self.Model = self.Model:Clone();

    Reporter:ReportItemMade(self);

    return self;
end


return Crate;