-- Pathfinder Tester
-- Deter
-- July 8, 2021


local PathfinderTester = {};

function PathfinderTester:Start()
	-- if (not game:IsLoaded()) then game.Loaded:Wait(); end;

	-- for i = 1, 4 do
	-- 	print("Waiting" .. i);
	-- 	wait(1);
	-- end

	-- local Pathfinder = self.Shared.Pathfinder.new();

	-- local gui = Instance.new("ScreenGui");
	-- gui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui");

	-- local textbox = Instance.new("TextBox");
	-- textbox.Parent = gui;
	-- textbox.ZIndex = 100;
	-- textbox.BackgroundTransparency = 0;
	-- textbox.Position = UDim2.new(.5, 0, .1, 0);
	-- textbox.Size = UDim2.fromOffset(200, 100);

	-- local textbox2 = Instance.new("TextBox");
	-- textbox2.Parent = gui;
	-- textbox2.ZIndex = 100;
	-- textbox2.BackgroundTransparency = 0;
	-- textbox2.Position = UDim2.new(.5, 0, .2, 0);
	-- textbox2.Size = UDim2.fromOffset(200, 100);
	-- textbox2.PlaceholderText = "quality";

	-- local button = Instance.new("TextButton");
	-- button.Size = UDim2.fromOffset(200, 100);
	-- button.Text = "recalculate";
	-- button.Position = UDim2.new(.5, 0, .3, 0);
	-- button.Parent = gui;

	-- button.MouseButton1Click:Connect(function()
	-- 	Pathfinder.FalloffRadius = tonumber(textbox.Text);
	-- 	Pathfinder.Distance = tonumber(textbox2.Text);
	-- 	Pathfinder:Compute();
	-- end)
end


return PathfinderTester;