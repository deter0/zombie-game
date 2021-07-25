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
	});

	local s = os.clock();
	for i = 1, 100000 do
		local Ball = EntityManager:CreateEntityFromTemplate("Ball");

		if (i % 50000 == 0) then wait(.2); end;
	end
	print("Generated entities in", os.clock() - s);

	wait(50000); -- dont clear them from memory for testing

	-- function Ball2:Update()
	-- 	print("a");
	-- end
end

return EntityTester;