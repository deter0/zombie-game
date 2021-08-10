local ReplicatedStorage = game:GetService("ReplicatedStorage");
local PlayerService = game:GetService("Players");
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Aero"):WaitForChild("Shared");

local Player = PlayerService.LocalPlayer;
local Mouse = Player:GetMouse();

local Graph = {};

function Graph:Start()
	-- local PlayerGui = Player:WaitForChild("PlayerGui");

	-- local GraphGui = PlayerGui:WaitForChild("Graph"):WaitForChild("Frame");
	-- local TargetGui = PlayerGui:WaitForChild("Graph"):WaitForChild("Frame2");


	-- RunService.RenderStepped:Connect(function(DeltaTime:number)
	-- 	local Position = Vector2.new(
	-- 		GraphGui.AbsolutePosition.Y - GraphGui.AbsoluteSize.Y/2,
	-- 		GraphGui.AbsolutePosition.X
	-- 	);

	-- 	TargetGui.Position = UDim2.fromOffset(200, math.sin(time()*2)*100+300)

	-- 	GraphGui.Rotation = math.atan2(TargetGui.AbsolutePosition.Y - Position.Y, TargetGui.AbsolutePosition.X - Position.X) * (180/math.pi);
	-- end)
end

return Graph;