-- Pathfinder
-- Deter
-- July 8, 2021

local ReplicatedStorage = game:GetService("ReplicatedStorage");

local Shared = ReplicatedStorage:WaitForChild("Aero"):WaitForChild("Shared");
local TableUtil = require(Shared:WaitForChild("TableUtil"));

local Tau = math.pi*2;

export type Weight = {
	Instance:Instance,
	Weight:number
};

local Pathfinder = {
	Weights = {},
	PathPoints = {},

	CenterPosition = Vector3.new(0, 5, 0),
	Bounds = 256,

	Distance = 2,

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

function Pathfinder:Compute()
	local nodes = {};

	local raycastParams = RaycastParams.new();
	raycastParams.IgnoreWater = true;
	raycastParams.FilterDescendantsInstances = game:GetService("CollectionService"):GetTagged("NotCollidable");
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist;

	if (not game:IsLoaded()) then game.Loaded:Wait(); end;
	wait(5);

	local start = os.clock();
	local nodeCount = 0;

	for x = 1, self.Bounds, self.Distance do
		local index = #nodes + 1;
		nodes[index] = {};

		for y = 1, self.Bounds, self.Distance do
			local index2 = #nodes[index]+1;

			local position = Vector3.new(x, 0, y);

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
			att.Visible = true;
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
			child.forwardConnector = forwardConnector;

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

	local dots = 0;
	local dotsCount = 0;

	for indexA, xNode in ipairs(nodes) do
		for index, child in ipairs(xNode) do
			if (not xNode[index - 1] or not xNode[index + 1]) then continue; end;
			local lastPosition = (child.data - xNode[index - 1].data);
			local nextPosition = (child.data - xNode[index + 1].data);

			local directionToNext = (child.data-nextPosition).Unit;
			local Dot = directionToNext:Dot(Vector3.new(0, 1, 0));
			local Up = (child.data - Vector3.new(0, 50000, 0)).Unit;

			dots += Dot * 90;
			dotsCount += 1;

			if ((directionToNext:Dot(Up) * 90) > -5) then
				child.att:Destroy();
			end
		end
	end

	print("Average dot:", dots/dotsCount);

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

	self.PathsVisible = true;
	self:Compute();

	return self;
end


return Pathfinder;