-- Region Controller
-- Deter
-- June 30, 2021

local Region = require(script.Parent.Parent:WaitForChild("Modules"):WaitForChild("Region"));

local RegionController = {Client = {}}


function RegionController:Start()
	self.Region = Region.new();
end

function RegionController.Client:AddVertexToRegion(Player, Position:Vector3, Normal:Vector3)
    RegionController.Region:AddVertex(Position, Normal);
    RegionController.Region:ToggleVerticesAsAttachments(true);
end

function RegionController:Init()
	
end


return RegionController