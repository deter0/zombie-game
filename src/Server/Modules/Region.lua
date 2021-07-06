-- Region
-- Deter
-- June 30, 2021


local Vertex = {};
Vertex.__index = Vertex;

function Vertex.new(Position:Vector3?, Normal:Vector3?)
	assert(typeof(Position) == "Vector3", ("invalid argument #1 (Vector3 expected, got %s)"):format(typeof(Position)));
	local self = setmetatable({
		Position = Position,
		Normal = Normal,
		Connections = {},
		ConnectedTo = {}
	}, Vertex);

	return self;
end

function Vertex:AddConnection(Origin, OtherVertex, Opposing)
	self.ConnectedTo[Origin] = OtherVertex;
	OtherVertex:VertexConnectedTo(Opposing, self);
end

function Vertex:VertexConnectedTo(Origin, OtherVertex)
	self.Connections[Origin] = OtherVertex;
end

local Region = {}
Region.__index = Region


function Region.new()
	local self = setmetatable({
		Vertices = {}
	}, Region);

	return self;
end

function Region:AddVertex(VertexPosition:Vector3, Normal:Vector3?)
	local NewVertex = Vertex.new(VertexPosition, Normal);

	if (#self.Vertices > 0) then
		NewVertex:AddConnection("From", self.Vertices[#self.Vertices], "To");
	end

	self.Vertices[#self.Vertices + 1] = NewVertex;
end

function Region:ToggleVerticesAsAttachments(Toggle:boolean)
	self.DisplayingVertices = Toggle;
	
	local Container:BasePart = workspace:FindFirstChild("RegionContainer") or Instance.new("Part");

	Container.Name = "RegionContainer";
	Container.Anchored = true;
	Container.CanCollide = false
	Container.Position = Vector3.new();
	Container.Size = Vector3.new();
	Container.Parent = workspace;

	for index, CurrentVertex in ipairs(self.Vertices) do
		local ExistingAttachment = Container:FindFirstChild(tostring(index));
		if (ExistingAttachment) then
			ExistingAttachment:Destroy();
		end

		if (Toggle) then
			local Attachment = Instance.new("Attachment");
			
			Attachment.Visible = true;
			Attachment.WorldPosition = CurrentVertex.Position;
			Attachment.Name = tostring(index);
			CurrentVertex.Attachment = Attachment;

			if (CurrentVertex.ConnectedTo.From) then
				local Beam:Beam = Instance.new("Beam");
				
				Beam.Attachment0 = Attachment;
				Beam.Attachment1 = CurrentVertex.ConnectedTo.From.Attachment;

				Beam.FaceCamera = true;
				Beam.Width0 = .2;
				Beam.Width1 = Beam.Width0;

				Beam.Parent = Attachment;
			end

			Attachment.Parent = Container;
		end
	end
end

function Region.ConstructFromData(Data)
	return; -- TODO
end

return Region