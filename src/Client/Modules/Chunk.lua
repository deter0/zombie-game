-- Performence Rendering
-- Deter
-- May 19, 2021


--> ** Render And Unrender props **
--> *Creates chunks of all useless objects and renders or unrenders them depending on some factors, like streaming enabled*

local Thread = require(game:GetService("ReplicatedStorage"):WaitForChild("Aero"):WaitForChild("Shared"):WaitForChild("Thread"));
local CollectionService = game:GetService("CollectionService");
local PerformanceRendering = {
	Chunks = {}
};

function PerformanceRendering.new(config)
	local self = setmetatable({
		config = config,
	}, {__index = PerformanceRendering});

	return self;
end

function PerformanceRendering:Initialize()
	self.Player = game:GetService("Players").LocalPlayer;
	self.config = self.config or {
		ChunkSize = 512,
		ObjectTag = "streaming_part",
		debug_mode = false, --> displays parts and stuff to show where chunks are
		RenderDistance = 768
	};

	if (not game:IsLoaded()) then
		game.Loaded:Wait();
	end

	self.Chunks = PerformanceRendering.BuildChunks(self.config.ObjectTag, self.config);

	self:StartStreaming();
end

local ChunkDataClass = {};

function ChunkDataClass.new(c, ce, _p, p)
	local self = setmetatable({
		Children = {},
		center = ce,
		_p = _p,
		p = p,
		st = Instance.new("Model"),
		notRendering = nil;
	}, {__index = ChunkDataClass});

	local Children = Instance.new("Model");
	Children.Name = "Chunk";

	for _, v in ipairs(self.Children) do
		v.Parent = Children;
	end

	Children.Parent = workspace;
	self.ChildrenParent = Children;

	self.st.Name = "chunk_storage";
	self.st.Parent = game.ReplicatedStorage:WaitForChild("Chunk_Storage");

	return self;
end

function ChunkDataClass:Add(Part)
	self.Children[#self.Children+1] = Part;
	Part.Parent = self.ChildrenParent;
end

function ChunkDataClass:Render()
	self.notRendering = false;
	self.ChildrenParent.Parent = workspace;
end

function ChunkDataClass:UnRender()
	self.notRendering = true;
	self.ChildrenParent.Parent = game.ReplicatedStorage:WaitForChild("Chunk_Storage");
end

local function part(x, y, c)
	local Part = Instance.new("Part");
	CollectionService:AddTag(Part, "debug_part");

	Part.Position = x;
	Part.Size = y;
	Part.Color = c;
	Part.Transparency = .8;
	Part.Anchored = true;
	Part.CanCollide = false;

	Part.Parent = workspace;

	return Part;
end


function PerformanceRendering.BuildChunks(tag:string, config)
	local objectsUnverfied = CollectionService:GetTagged(tag); --> Cannot verify authencity of this

	local debugParts = CollectionService:GetTagged("debug_part");
	for _, v in ipairs(debugParts) do v:Destroy(); end;

	local objects = {}; --> Verfied objects

	for _, v in ipairs(objectsUnverfied) do --> Build verfied objects
		local Part = v:IsA("BasePart") and v or v:IsA("Model") and v.PrimaryPart;

		if (Part and Part:IsA("BasePart") and Part.Anchored) then
			table.insert(objects, v);
		end
	end

	local highest = table.create(3, nil); --> Highest vector for highest X, Y & Z positions
	local lowest = table.create(3, nil); --> Highest ...> lowest

	local finished = setmetatable({}, {__mode = "kv"});

	local function loopThroughObjects(callback)
		for i, v in ipairs(objects) do
			callback(i, v); --> Loop with next and previous values
		end
	end

	loopThroughObjects(function(_, baseObject)
		local object = baseObject:IsA("BasePart") and baseObject or baseObject:IsA("Model") and baseObject.PrimaryPart;

		if (object) then
			--> Check if it's the highest
			if (not highest[1] or object.Position.X > highest[1].Position.X) then
				highest[1] = object;
			end
			if (not highest[2] or object.Position.Y > highest[2].Position.Y) then
				highest[2] = object;
			end
			if (not highest[3] or object.Position.Z > highest[3].Position.Z) then
				highest[3] = object;
			end

			--> Check if it's the lowest
			if (not lowest[1] or object.Position.X < lowest[1].Position.X) then
				lowest[1] = object;
			end
			if (not lowest[2] or object.Position.Y < lowest[2].Position.Y) then
				lowest[2] = object;
			end
			if (not lowest[3] or object.Position.Z < lowest[3].Position.Z) then
				lowest[3] = object;
			end
		end
	end)

	local function rv3(x)
		return Vector3.new(x, x, x);
	end

	warn("L, H:", lowest, highest);
	if (not lowest[1] or not highest[1]) then
		return {};
	end

	local Chunks = {};
	local index = 0;

	for x = lowest[1].Position.X, highest[1].Position.X + config.ChunkSize, config.ChunkSize do
		local _x = x - config.ChunkSize;

		for z = lowest[3].Position.Z, highest[3].Position.Z + config.ChunkSize, config.ChunkSize do
			local _z = z - config.ChunkSize;

			for y = lowest[2].Position.Y, highest[2].Position.Y + config.ChunkSize, config.ChunkSize do
				index += 1;
				if (index % 1000 == 0) then
					wait(.5);
					print("yeilding");
				end

				local _y = y - config.ChunkSize;
				local center = Vector3.new(x, y, z) - rv3(config.ChunkSize/2);

				local _v, v = Vector3.new(_x, _y, _z), Vector3.new(x, y, z);

				local ChunkData = ChunkDataClass.new({}, center, _v, v);

				loopThroughObjects(function(_, object)
					local Part = object:IsA("BasePart") and object or object:IsA("Model") and object.PrimaryPart;

					if (Part and not finished[Part]) then
						if (PerformanceRendering.intersecting(Part.Position, _v, v)) then
							ChunkData:Add(object);
							object:SetAttribute("ActiveChunk", true);
							finished[Part] = true;
						end
					end
				end)

				local Part;
				if (config.debug_mode) then
					Part = part(center, rv3(config.ChunkSize), Color3.new(1, 1, 1));
				end

				if (#ChunkData.Children < 1) then
					continue;
				end

				if (Part) then
					Part.Color = Color3.new(0, 1, 0);
				end

				Chunks[#Chunks+1] = ChunkData;
			end
		end
	end

	print("FINISHED")
	table.clear(finished);
	finished = nil;
	return Chunks;
end

function PerformanceRendering.intersecting(p1, s1, s2)
	return (
		(p1.X > s1.X and p1.X < s2.X) --> X
			and
			(p1.Y > s1.Y and p1.Y < s2.Y) --> Y
			and
			(p1.Z > s1.Z and p1.Z < s2.Z) --> Z
	);
end

local RunService = game:GetService("RunService");
function PerformanceRendering:Update()
	Thread.Spawn(function()
		local renderDistance = self.config.RenderDistance;
		local cameraPosition = self.CameraPosition;
		for _, Chunk in ipairs(self.Chunks) do
			if ((cameraPosition - Chunk.center).Magnitude >= renderDistance) then
				if (not Chunk.notRendering) then
					Chunk:UnRender();
				end
			else
				if (Chunk.notRendering) then
					Chunk:Render();
				end
			end

			RunService.Heartbeat:Wait();
		end
	end)
end

function PerformanceRendering:StartStreaming()

    self.Camera = workspace.CurrentCamera or workspace:WaitForChild("Camera");
    local CameraPosition = self.Camera.CFrame.Position;

    self.CameraPosition = CameraPosition;
    self:Update();

	local lastUpdate = time();

	Thread.Spawn(function()
		RunService.Heartbeat:Connect(function()
			if (time() - lastUpdate < .5) then return; end;
	
			local CurrentCameraPosition = self.Camera.CFrame.Position;
			self.CameraPosition = CurrentCameraPosition;
	
			if ((CurrentCameraPosition - CameraPosition).Magnitude >= (self.config.RenderDistance/2)) then
				self:Update();
				lastUpdate = time();
			end
		end)
	end)
end

return PerformanceRendering