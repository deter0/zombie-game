local ReplicatedStorage = game:GetService("ReplicatedStorage");
local Shared = ReplicatedStorage:WaitForChild("Aero"):WaitForChild("Shared");

local RunService = game:GetService("RunService");
local Signal = require(Shared:WaitForChild("Signal"));

local EntityTester = {};

function EntityTester:Start()
	local EntityManager = self.Shared.EntityManager;

	EntityManager:CreateTemplateEntity("Ball", {
		Model = workspace:WaitForChild("CoolBall"),
		Droppable = true, -- Appends method :Drop and :Pickup
		ModelAnchorWhenDropped = false,
		ReplicateToClient = true,
	});

	local MyCoolBall  = EntityManager:CreateEntityFromTemplate("Ball");
	MyCoolBall:Drop(Vector3.new(0, 5, 0));
end

return EntityTester;