local ReplicatedStorage = game:GetService("ReplicatedStorage");
local Shared = ReplicatedStorage:WaitForChild("Aero"):WaitForChild("Shared");

local RunService = game:GetService("RunService")

local InverseKinematics = require(Shared:WaitForChild("InverseKinematics"));
local CharacterIK = {};

function CharacterIK:Start()
	local A1 = workspace:WaitForChild("a1");
	local A2 = workspace:WaitForChild("a2");

	local Start = workspace:WaitForChild("start");
	local Target = workspace:WaitForChild("end");

	local LegInverseKinematics = InverseKinematics.new(Start.Position, Target.Position, {A1, A2}, true);

	RunService.Heartbeat:Connect(function(DeltaTime)
		LegInverseKinematics.start = Start.Position;
		LegInverseKinematics.target = Target.Position;

		local results = LegInverseKinematics:Calculate();
		A1.CFrame = results[1];
		A2.CFrame = results[2];
	end)
end

return CharacterIK;