local RunService = game:GetService("RunService");
local Cast = {};
Cast.Visualize = true;

local function PreciseWait(t)
	local target = os.clock() + (t or 1/30);
	repeat RunService.Stepped:Wait();
	until os.clock() >= target;
end

local GREEN, RED = Color3.new(0, 1, 0), Color3.new(1, 0, 0);
function Cast:Raycast(Start, Direction, OnRayUpdated, Config, RaycastParams:RaycastParams, UserData)
	self:DrawPosition(GREEN, Start, Start + Direction);

	local _Cast = {
		UserData = UserData or {},
	};

	local Trajectory = self:CalculateTrajectory(Start, Direction, Config);
	do
		local temp = RaycastParams.FilterDescendantsInstances;
		temp[#temp+1] = self:GetDrawingDirectory();

		RaycastParams.FilterDescendantsInstances = temp;
	end

	local LastPosition = Start;
	for index, Node in ipairs(Trajectory) do
		if (index == 1) then continue; end;

		local LastNode = Trajectory[index - 1];

		if (Node.Position - LastPosition).Magnitude > 10 then
			PreciseWait(Config.TimeBetweenNodes);
			LastPosition = Node.Position;
		end

		if (not LastNode) then
			warn("LAST NODE NOT FOUND", index - 1, index);
			continue;
		end

		local NodeDirection = (Node.Position - LastNode.Position);

		local Raycast = workspace:Raycast(LastNode.Position, NodeDirection, RaycastParams);
		if (Raycast) then
			if (not Config.CanRayPierce or not Config.CanRayPierce(_Cast, Raycast, NodeDirection, Node, LastNode)) then
				self:DrawRaycast(LastNode.Position, Raycast.Position, true);
				return Raycast, _Cast;
			end
		end

		if (OnRayUpdated) then
			OnRayUpdated(_Cast, Node, LastNode, Direction);
		end

		self:DrawRaycast(LastNode.Position, Node.Position);
	end

	return nil, _Cast;
end

-- Roblox gravity m/s -> studs/s
local GRAVITY = (9.8206 * 0.28); -- 1 stud = 0.28 meters
local GRAVITY_VECTOR = Vector3.new(0, GRAVITY, 0);
function Cast:CalculateTrajectory(Origin, Direction, Config)
	debug.profilebegin("Calculate cast trajectory");
	local InitialAcceleration = Config.Acceleration or Vector3.new();
	local DirectionNormalized = Direction.Unit;

	local Trajectory = {
		{Position = Origin, Acceleration = InitialAcceleration, Direction = DirectionNormalized}, -- Initial Position
	};

	local Distance = (Origin - (Origin + Direction)).Magnitude;
	local RayLength = Distance / Config.Precison;

	for t = 1, Distance, RayLength do
		local LastPosition = Trajectory[#Trajectory].Position;
		local Velocity = (DirectionNormalized * RayLength);
		local Position = LastPosition + Velocity;

		local ElapsedTime = (Origin - Position).Magnitude * (1/Config.StudsPerSecond); -- Hacky way to get elapsed time since we're not running this in real time
		local Acceleration = InitialAcceleration + -GRAVITY_VECTOR * ElapsedTime;

		Position += Acceleration;

		Trajectory[#Trajectory + 1] = {
			Position = Position,
			Direction = Velocity,
			Acceleration = Acceleration
		};
	end

	debug.profileend();
	return Trajectory;
end

function Cast:DrawPosition(Color, ...)
	if (self.Visualize) then
		local Directory = self:GetDrawingDirectory();

		for _, Position in ipairs({...}) do
			local DisplayPart = Instance.new("Part");
			DisplayPart.Transparency = .5;
			DisplayPart.Color = Color;
			DisplayPart.Size = Vector3.new(2.25, 2.25, 2.25);
			DisplayPart.Anchored = true;
			DisplayPart.CastShadow = false;
			DisplayPart.CanCollide = false;

			DisplayPart.Position = Position;

			DisplayPart.Parent = Directory;

			game:GetService("Debris"):AddItem(DisplayPart, 1);
		end
	end
end

function Cast:DrawRaycast(Origin, Hit, Highlight)
	if (self.Visualize) then
		local Directory = self:GetDrawingDirectory();

		local DisplayPart = Instance.new("Part");
		DisplayPart.Transparency = 0;
		DisplayPart.Material = Enum.Material.Neon;
		DisplayPart.Color = Highlight and Color3.new(1, 0, 0) or Color3.new(0.4, 0.4, 0.4);
		DisplayPart.Size = Vector3.new(2.25, 2.25, 2.25);
		DisplayPart.Anchored = true;
		DisplayPart.CastShadow = false;
		DisplayPart.CanCollide = false;

		DisplayPart.CFrame = CFrame.lookAt(Origin, Hit);
		DisplayPart.Shape = Enum.PartType.Ball;

		local Cone = Instance.new("ConeHandleAdornment");
		Cone.Adornee = DisplayPart;
		Cone.Height = (Origin - Hit).Magnitude - (2.25/2);
		Cone.Radius = .75;
		Cone.Color3 = Highlight and Color3.new(0.15, 0.074, 0.074) or Color3.new(0, 0, 0);

		Cone.Parent = DisplayPart;

		DisplayPart.Parent = Directory;

		game:GetService("Debris"):AddItem(DisplayPart, 1);
	end
end

function Cast:GetDrawingDirectory():Model
	local Directory = workspace.Terrain:FindFirstChild("CastVisualization") or Instance.new("Model");
	Directory.Name = "CastVisualization";
	Directory.Parent = workspace.Terrain;

	return Directory;
end

return Cast;