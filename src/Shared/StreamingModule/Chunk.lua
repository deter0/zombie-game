local Chunk = {
	Children = {},
	ParentData = {},
	State = 1,
	ProfileDirectory = nil,
};
Chunk.__index = Chunk;

function Chunk.new(Position:Vector3, ChunkSize:Vector3, ProfileDirectory:Folder|Model, Pack:boolean)
	local self = setmetatable({
		Position = Position,
		Size = ChunkSize,
		Children = {},
		ParentData = {},
		ProfileDirectory = ProfileDirectory,
		Pack = Pack,
	}, Chunk);

	if (self.Pack) then
		self.Pack = Instance.new("Model");
		self.Pack.Name = tostring(self.Position);
		self.Pack.Parent = workspace;
	end

	return self;
end

function Chunk:AppendObject(Object:Instance)
	if (not Object:IsDescendantOf(workspace)) then return; end;

	local ParentString = "";
	local Parent = Object.Parent;
	while Parent ~= game do
		ParentString = Parent.Name.."/"..ParentString;
		Parent = Parent.Parent;
	end
	Object:SetAttribute("OriginalParent", ParentString);

	self.Children[#self.Children + 1] = Object;
	self.ParentData[Object] = Object.Parent;
	if (self.Pack) then
		Object.Parent = self.Pack;

		if (Object.Parent ~= self.Pack) then
			repeat task.wait();
				print("Waiting");
				Object.Parent = self.Pack;
			until Object.Parent == self.Pack;
		end
	end

	self:UpdateVisualization();
	return #self.Children;
end

function Chunk:RemoveObject(Index:number)
	if (self.Children[Index]) then
		self.ParentData[self.Children[Index]] = nil;
	end
	self.Children[Index or -1] = nil;

	self:UpdateVisualization();
end

function Chunk:UpdateVisualization()
	if (not self.VisualizePart) then return; end;

	self.VisualizePart.Transparency = #self.Children > 0 and .95 or 1;
end

function Chunk:Offload()
	if (self.State == -2) then
		for _, v in ipairs(self.Children) do v.Parent = self.Pack; end;
	end
	if (self.State == -1) then return; end; -- * Return because its already offloaded
	if (self.Pack) then
		self.Pack.Parent = self.ProfileDirectory;
	else
		for index, Object:Instance in ipairs(self.Children) do
			Object.Parent = self.ProfileDirectory;
		end
	end

	self.State = -1; -- * Meaning offloaded
end

function Chunk:RevertOffload()
	if (self.State == -2) then return; end;
	for index, Object:Instance in ipairs(self.Children) do
		Object.Parent = self.ProfileDirectory;
	end

	self.State = -2;
end

function Chunk:Reload()
	if (self.State == -2) then
		for _, v in ipairs(self.Children) do v.Parent = self.Pack; end;
	end
	if (self.State == 1) then return; end; -- * Return because it's already loaded
	if (self.Pack) then
		self.Pack.Parent = workspace;
	else
		for index, Object:Instance in ipairs(self.Children) do
			if (index % 50 == 0) then task.wait(); end;
			if (not self.ParentData[Object]) then -- * Parent destroyed meaning it must be destroyed
				Object:Destroy();
				self.Children[index] = nil;
			end
			Object.Parent = self.ParentData[Object];
		end
	end

	self.State = 1;
end

function Chunk:Visualize(State:boolean)
	if (not State) then State = true; end;

	local VisualizePart = self.VisualizePart or Instance.new("Part");

	if (State) then
		VisualizePart.Anchored = true;
		VisualizePart.CanCollide = false;
		VisualizePart.Transparency = #self.Children > 0 and .5 or 1;
		VisualizePart.Material = Enum.Material.Neon;
		VisualizePart.Color = Color3.new(1, 0, 1);

		VisualizePart.Position = self.Position;
		VisualizePart.Size = Vector3.new(self.Size, self.Size, self.Size);

		VisualizePart.Parent = workspace;
	else
		VisualizePart:Destroy();
	end

	self.VisualizePart = VisualizePart;
end

return Chunk;