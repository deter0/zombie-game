local ClimbingManager = {};

function ClimbingManager:Start()
	-- local Player = game:GetService("Players").LocalPlayer;

	-- Player.CharacterAdded:Connect(function(Character)
	-- 	local original = Character:WaitForChild("UpperTorso"):WaitForChild("Waist").C0
	-- 	game:GetService("RunService").Heartbeat:Connect(function()
	-- 		Character.UpperTorso.Waist.C0 = original * CFrame.Angles(math.atan(workspace.CurrentCamera.CFrame.LookVector.Y), 0, 0);
	-- 	end)
	-- end)
end

return ClimbingManager;