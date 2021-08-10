-- FPS Graph
-- deter
-- August 9, 2021

local ReplicatedStorage = game:GetService("ReplicatedStorage");
local Shared = ReplicatedStorage:WaitForChild("Aero"):WaitForChild("Shared");

local RunService = game:GetService("RunService")

local GraphModule = require(Shared:WaitForChild("GraphModule"));

local FPSGraph = {}

function FPSGraph:Start()
	GraphModule:Start();
end

return FPSGraph