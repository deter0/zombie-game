-- Pathfinder
-- Deter
-- July 8, 2021

local ReplicatedStorage = game:GetService("ReplicatedStorage");

local Shared = ReplicatedStorage:WaitForChild("Aero"):WaitForChild("Shared");
local TableUtil = require(Shared:WaitForChild("TableUtil"));
local Thread = require(Shared:WaitForChild("Thread"));

local Tau = math.pi*2;

export type Weight = {
	Instance:Instance,
	Weight:number
};

local Pathfinder = {
	Weights = {},
	PathPoints = {},

	CenterPosition = Vector3.new(-50, 5, -50),
	Bounds = 256,

	Distance = 4,

	BackwardsRayMargin = 1,
	MaxRayLength = 200,
	DownCastOrigin = 150,

	VisualizePoints = true
};
Pathfinder.__index = Pathfinder;

local Node = {
	children = {},
	data = nil
};
Node.__index = Node;

function Node:forEach(callback)
	local function t(x)
		for _, v in ipairs(x.children) do
			callback(v);
			t(v);
		end
	end

	t(self);
end

function Node.new(data, parent)
	 return setmetatable({data = data, parent = parent, children = {}}, Node);
end

function Node:append(data)
	self.children[#self.children + 1] = Node.new(data, self);
	self.children[#self.children].index = #self.children;
	return self.children[#self.children];
end

local function DisplayRay(Origin:Vector3, Direction:Vector3?, Position:Vector3?)
	local AttachmentOne = Instance.new("Attachment");
	local AttachmentTwo = Instance.new("Attachment");

	AttachmentOne.WorldPosition = Origin;
	AttachmentTwo.WorldPosition = Position or (Origin + Direction);
	
	AttachmentOne.Parent = workspace:WaitForChild("PathWaypoints");
	AttachmentTwo.Parent = workspace:WaitForChild("PathWaypoints");

	local Beam = Instance.new("Beam");

	Beam.Attachment0 = AttachmentOne;
	Beam.Attachment1 = AttachmentTwo;

	Beam.Width0 = .2;
	Beam.Width1 = .2;

	Beam.FaceCamera = true;

	Beam.Parent = AttachmentOne;
end

function Pathfinder:AStar(StartPosition:Vector3, EndPosition:Vector3, PathFindingRaycastParams:RaycastParams?)
	if (not PathFindingRaycastParams) then PathFindingRaycastParams = RaycastParams.new(); end;

	local function CastRay(Origin:Vector3, Direction:Vector3)
		local Raycast = workspace:Raycast(Origin, Direction, PathFindingRaycastParams);
		DisplayRay(Origin, Direction, Raycast and Raycast.Position);
		return Raycast;
	end

	local foundPath;

	local function recurse(Position:Vector3, Direction:Vector3?)
		if (foundPath) then return; end;
		wait(.1);

		local Raycast = CastRay(Position, Direction or (Position - EndPosition));

		if (Raycast) then
			local CenterBetweenPositionAndRayHit = Raycast.Position:Lerp(Position, .5);

			Thread.Spawn(function()
				recurse(CenterBetweenPositionAndRayHit, CenterBetweenPositionAndRayHit - ((CFrame.new(Raycast.Position) * CFrame.new(5, 0, 0)).Position));
			end)
			Thread.Spawn(function()
				recurse(CenterBetweenPositionAndRayHit, CenterBetweenPositionAndRayHit - ((CFrame.new(Raycast.Position) * CFrame.new(-5, 0, 0)).Position));
			end)
		elseif (not Direction and not Raycast) then
			foundPath = true;
			warn("Found path");
		else
			recurse(Position + (Position - EndPosition));
		end
	end

	recurse(StartPosition);
end

function Pathfinder:Compute() -- ! Deprecated & Incomplete see method :AStar instead
	workspace:WaitForChild("PathWaypoints"):ClearAllChildren();
	
	local nodes = {};

	local raycastParams = RaycastParams.new();
	raycastParams.IgnoreWater = true;
	raycastParams.FilterDescendantsInstances = game:GetService("CollectionService"):GetTagged("NotCollidable");
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist;

	if (not game:IsLoaded()) then game.Loaded:Wait(); end;

	local start = os.clock();
	local nodeCount = 0;

	for x = 1, self.Bounds, self.Distance do
		local index = #nodes + 1;
		nodes[index] = {};

		for y = 1, self.Bounds, self.Distance do
			local index2 = #nodes[index]+1;

			local position = self.CenterPosition + Vector3.new(x, 0, y) - Vector3.new(self.Bounds/2, 0, self.Bounds/2);

			local raycastDown = workspace:Raycast(position + Vector3.new(1, self.DownCastOrigin, 1), Vector3.new(0, -self.MaxRayLength, 0), raycastParams);
			if (raycastDown) then
				position = raycastDown.Position;
			end;

			nodeCount += 1;
			nodes[index][index2] = {data = position + Vector3.new(0, .1, 0)};

			if (nodeCount % 1000000 == 0) then wait(.5); end;
		end
	end
	
	for _, x in ipairs(nodes) do
		for _, child in ipairs(x) do
			local att = Instance.new("Attachment");
			-- att.Visible = true;
			att.WorldPosition = (child.data);
			att.Parent = workspace:WaitForChild("PathWaypoints");
			child.att = att;
		end
	end

	local GREEN = Color3.new(0, .75, 0);

	local function createAttachment(att1, att2)
		local beam = Instance.new("Beam");
		beam.Attachment1 = att1;
		beam.Attachment0 = att2;
		beam.Segments = 1;
		beam.FaceCamera = true;
		beam.Width0 = .125;
		beam.Width1 = .1;
		beam.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 0)});
		beam.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, GREEN), ColorSequenceKeypoint.new(1, GREEN)});
		beam.Parent = att1;
	end

	for indexA, x in ipairs(nodes) do
		local s = false;

		for index, child in ipairs(x) do
			if (s) then s = false; continue; end;
			if (not x[index + 1]) then break; end;
			
			local forwardConnector = x[index + 1].att;
			createAttachment(child.att, forwardConnector);
			
			child.forward = x[index + 1];
			child.backward = x[index - 1];

			child.right =  nodes[indexA + 1] and nodes[indexA + 1][index];
			child.left =  nodes[indexA - 1] and nodes[indexA - 1][index];

			if (nodes[indexA + 1]) then
				if (nodes[indexA + 1][index]) then
					local sideConnector = nodes[indexA + 1][index].att;
					createAttachment(child.att, sideConnector);
					child.sideConnector = sideConnector;
				end
			end
		end
	end

	print(string.format("Made %d nodes in %s seconds.", nodeCount, os.clock() - start));

	local average = 0;
	local toAverageCount = 0;

	for indexA, xNode in ipairs(nodes) do -- * Filter one
		for index, child in ipairs(xNode) do
			if (not xNode[index - 1] or not xNode[index + 1]) then continue; end;
			
			local directions = {
				forwads = child.forwards and child.data - child.forwards.data,
				backwards = child.backwards and child.data - child.backwards,
				left = child.left and child.data - child.left.data,
				right = child.right and child.data - child.right.data
			};

			local averageDirectionMagnitude = 0;

			do
				local temp = 0;
				for _, direction in pairs(directions) do averageDirectionMagnitude += direction.Magnitude; temp += 1; end;

				averageDirectionMagnitude /= temp;
			end

			average += averageDirectionMagnitude;
			toAverageCount += 1;

			if (averageDirectionMagnitude > (self.FalloffRadius or 5.6)) then
				child.att:Destroy();
			end
		end
	end

	for indexA, xNode in ipairs(nodes) do -- * Filter two
		for index, child in ipairs(xNode) do
			if (not xNode[index - 1] or not xNode[index + 1]) then continue; end;
			
			local directions = {
				forwad = child.forwards and child.data - child.forwards.data,
				backward = child.backwards and child.data - child.backwards,
				left = child.left and child.data - child.left.data,
				right = child.right and child.data - child.right.data
			};

			local RaycastOrigin = child.data + Vector3.new(0, 4, 0);
			for directionIndex, direction in pairs(directions) do
				local Raycast = workspace:Raycast(RaycastOrigin, direction, raycastParams);

				if (Raycast) then
					print("Filtered", Raycast.Instance);
					child[directionIndex].att:Destroy();
				end
			end
		end
	end

	print("Average dot:", average/toAverageCount);

	-- local function forEach(node, count)
	-- 	if (count > 50) then return; end;
	-- 	for ind, current in ipairs(node.children) do
	-- 		local att = Instance.new("Attachment");
	-- 		att.Visible = true;
	-- 		att.WorldPosition = current.data;
	-- 		att.Parent = workspace:WaitForChild("PathWaypoints");

	-- 		forEach(current, count + ind);
	-- 	end
	-- end

	-- forEach(head, 1);
end

function Pathfinder.new(CenterPosition:Vector3, Bounds:number)
	local self = setmetatable({
		CenterPosition = CenterPosition
	}, Pathfinder);

	shared.Distance = self.Distance;
	shared.Bounds = self.Bounds;

	shared.Update = function()
		self.Distance = shared.Distance;
		self.Bounds = shared.Bounds;

		self:Compute();
	end

	self.PathsVisible = true;
	self:Compute();

	return self;
end


return Pathfinder;