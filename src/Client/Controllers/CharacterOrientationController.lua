-- Character Orientation Controller
-- Deter
-- July 12, 2021


local RunService = game:GetService("RunService");
local PlayerService = game:GetService("Players");

local CharacterOrientationController = {};

function CharacterOrientationController:Start()
	self.OrientationPart = workspace:WaitForChild("CharacterOrientations"):WaitForChild(game:GetService("Players").LocalPlayer.UserId);

	self.OrientationPart.Position = Vector3.new(0, 1000, 0);

	local Original = {};

	RunService.Heartbeat:Connect(function(DeltaTime)
		local Orientation = math.atan(workspace.CurrentCamera.CFrame.LookVector.Y);

		self.OrientationPart.AssemblyLinearVelocity = Vector3.new();
		self.OrientationPart.Position = Vector3.new(0, 1000, 0);
		self.OrientationPart.Orientation = Vector3.new(Orientation, 0, 0);

		for _, Part in ipairs(workspace.CharacterOrientations:GetChildren()) do
			local Player = PlayerService:GetPlayerByUserId(tonumber(Part.Name));

			if (Player and Player.Character and Player.Character:FindFirstChild("UpperTorso") and Player.Character.UpperTorso:FindFirstChild("Waist")) then
				local UpperTorso = Player.Character.UpperTorso.Waist;

				if (not Original[Player.Name]) then Original[Player.Name] = UpperTorso.C0; end;

				UpperTorso.C0 = Original[Player.Name] * CFrame.Angles(Part.Orientation.X, 0, 0);
			else
				Original[Player.Name] = nil;
			end
		end
	end)
end

return CharacterOrientationController;