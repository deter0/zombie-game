local ReplicatedStorage = game:GetService("ReplicatedStorage");
local CollectionService = game:GetService("CollectionService");

if (ReplicatedStorage:FindFirstChild("Chunks")) then
	ReplicatedStorage.Chunks:Destroy();
end

local ParentDirectory = Instance.new("Folder");
ParentDirectory.Name = "Chunks";
ParentDirectory.Parent = ReplicatedStorage;

local Classes = {
	Chunk = require(script:WaitForChild("Chunk"))
};

do
	local Profile = {
		Name = "Profile",
		Id = 0,
		Chunks = {},
		Config = {
			ChunkSize = 45,
			StreamingDistance = 45
		},
	};
	Profile.__index = Profile;

	function Profile.new(ObjectData)
		local self = setmetatable(ObjectData or {}, Profile);

		if (self.InitialObjects) then
			self:ObjectsAdded(self.InitialObjects);
		end

		if (self.CollectionServiceTag) then
			self:ObjectsAdded(CollectionService:GetTagged(self.CollectionServiceTag));

			CollectionService:GetInstanceAddedSignal(self.CollectionServiceTag):Connect(function(Object:Instance)
				self:ObjectAdded(Object);
			end)
		end

		self.Directory = Instance.new("Folder");
		self.Directory.Name = self.Name;
		self.Directory.Parent = ParentDirectory;

		return self;
	end

	function Profile:ObjectsAdded(Objects:{Instance}):nil
		for _, Object:Instance in ipairs(Objects) do
			self:ObjectAdded(Object);
		end
	end

	function Profile:ObjectMoved(Object:Instance, Callback:(nil)->nil)
		local QueueData = {Object, Callback, self:GetObjectCFrame(Object).Position};

		if (not self.ObjectMovedLoop) then -- * Create loop and queue
			self.ObjectMovedQueue = {QueueData};
			local RunService = game:GetService("RunService");
			local Margin = self.Config.ChunkSize/12;

			self.ObjectMovedLoop = RunService.Heartbeat:Connect(function()
				for index, ObjectQueueData in ipairs(self.ObjectMovedQueue) do
					local Object_ = ObjectQueueData[1];
					local Callback_ = ObjectQueueData[2];
					local LastCFrame = ObjectQueueData[3];

					local CurrentCFrame = self:GetObjectCFrame(Object_);

					if ((CurrentCFrame.Position - LastCFrame).Magnitude >= Margin) then
						Callback_();
						self.ObjectMovedQueue[index] = {
							Object_,
							Callback_,
							CurrentCFrame.Position
						};
					end
				end
			end)
		else -- * Add to queue
			self.ObjectMovedQueue[#self.ObjectMovedQueue+1] = QueueData;
		end
	end

	function Profile:ObjectAdded(Object:Instance) -- * Where we assign an object it's chunk
		local ObjectCFrame = self:GetObjectCFrame(Object);

		if (not ObjectCFrame) then return; end;

		local Chunk = self:GetAssignedChunkForPosition(ObjectCFrame.Position);
		local Index = Chunk:AppendObject(Object);

		if (self.Config.ArePartsMoving) then
			self:ObjectMoved(Object, function()
				ObjectCFrame = self:GetObjectCFrame(Object);
				local NewChunk = self:GetAssignedChunkForPosition(ObjectCFrame.Position);

				if (NewChunk.Position ~= Chunk.Position) then
					Chunk:RemoveObject(Index);
					Index = NewChunk:AppendObject(Object);
					Chunk = NewChunk;
				end
			end);
		end
	end

	function Profile:GetObjectCFrame(Object:Instance)
		local IsAModel:boolean = Object:IsA("Model");
		local IsABasePart:boolean = Object:IsA("BasePart");

		local ObjectCFrame:CFrame? = nil;

		if (IsABasePart) then
			ObjectCFrame = Object.CFrame;
		elseif (IsAModel) then
			if (Object.PrimaryPart) then
				ObjectCFrame = Object.PrimaryPart.CFrame;
			else
				local BoundingBoxCFrame, BoundingSize = Object:GetBoundingBox();
				ObjectCFrame = BoundingBoxCFrame;
			end
		end

		return ObjectCFrame;
	end

	--@http://lua-users.org/wiki/SimpleRound
	-- Igor Skoric (i.skoric@student.tugraz.at)
	function Round(n, mult)
		mult = mult or 1
		return math.floor((n + mult/2)/mult) * mult
	end

	function Profile:GetAssignedChunkForPosition(Position:Vector3)
		local ToRoundTo:number = self.Config.ChunkSize or 45;
		local ChunkPosition:Vector3 = Vector3.new(
			Round(Position.X, ToRoundTo),
			Round(Position.Y, ToRoundTo),
			Round(Position.Z, ToRoundTo)
		);

		local Chunk = self.Chunks[ChunkPosition];

		if (not Chunk) then
			self.Chunks[ChunkPosition] = Classes.Chunk.new(ChunkPosition, ToRoundTo, self.Directory, self.Config.Pack);
			Chunk = self.Chunks[ChunkPosition];
			Chunk.Position = ChunkPosition;

			if (self.DebugMode) then
				Chunk:Visualize(true);
			end
		end

		return Chunk;
	end

	function Profile:UpdateStream(TargetPosition:Vector3)
		for _, Chunk in pairs(self.Chunks) do
			if ((Chunk.Position - TargetPosition).Magnitude > self.Config.StreamingDistance + self.Config.ChunkSize) then
				Chunk:Offload();
			else
				Chunk:Reload();
			end
		end
	end

	Classes.Profile = Profile;
end

local Streaming = {
	AllProfiles = {},
};

function Streaming:CreateProfile(ProfileName:string, ProfileConfig, Objects:{Instance}?, CollectionServiceTag:string?, DebugMode:boolean?)
	local Profile = Classes.Profile.new({
		Name = ProfileName or "Profile",
		InitialObjects = Objects or {},
		CollectionServiceTag = CollectionServiceTag,
		Id = #self.AllProfiles + 1,
		Config = ProfileConfig and setmetatable(ProfileConfig, {__index = Classes.Profile.Config}) or Classes.Profile.Config,
		DebugMode = DebugMode,
	});

	self.AllProfiles[#self.AllProfiles+1] = Profile;
end

--- Starts streaming all profiles in the same thread please note that this access to the player's camera
function Streaming:StartStreamingAllSimultanously(IsPlugin:boolean?)
	local Camera = workspace.CurrentCamera or workspace:WaitForChild("Camera");

	local UpdatePosition;
	local LastUpdate = 0;

	local RunService = game:GetService("RunService");

	while task.wait() do -- ? Similar to heartbeat?
		if (IsPlugin and RunService:IsRunning()) then continue; end;

		local CameraPosition:Vector3 = Camera.CFrame.Position;

		if ((tick() - LastUpdate) > 0.45) then
			if (not UpdatePosition or (CameraPosition - UpdatePosition).Magnitude >= 25) then
				for _, Profile in ipairs(self.AllProfiles) do
					if (Profile.Paused) then continue; end;

					Profile:UpdateStream(CameraPosition);
				end
				UpdatePosition = CameraPosition;
				LastUpdate = tick();
			end
		end
	end
end

function Streaming:PauseAll()
	for _, v in ipairs(self.AllProfiles) do
		v.Paused = true;
		for _, Chunk in pairs(v.Chunks) do
			Chunk:Reload();
		end
	end
end

function Streaming:ResumeAll()
	for _, v in ipairs(self.AllProfiles) do
		v.Paused = false;
	end
end

function Streaming:Revert()
	for _, v in ipairs(self.AllProfiles) do
		for _, Chunk in pairs(v.Chunks) do
			Chunk:RevertOffload();
		end
	end
end

return Streaming;