-- Wind
-- Deter
-- July 1, 2021

local RunService = game:GetService("RunService");
local CollectionService = game:GetService("CollectionService");

local Camera = workspace.CurrentCamera or workspace:WaitForChild("Camera");
local Tag = "WindShake";

local StreamingModule;
do
	local PlayerService = game:GetService("Players");
	local Player = PlayerService.LocalPlayer;
	StreamingModule = require(Player:WaitForChild("PlayerScripts"):WaitForChild("StreamHandler"):WaitForChild("StreamingModule"));
end

local Wind = {
	Range = 140,
	Noises = {},
	Original = {},
	WindSpeed = 2,
	WindStrength = .08,
	UpdateStreamDistance = 50,
	WindDirection = CFrame.Angles(0, 0, 0),
	Streaming = {},
	NoiseLayers = 12
};

local function Find(b, v)
	for _, value in next, b do
		if (value == v) then
			return true;
		end
	end

	return false;
end

function Wind:UpdateStream(CameraPosition)
	local Streaming = self.Profile:GetObjectsAroundPosition(CameraPosition, self.Range);
	for _, v in ipairs(self.Streaming) do
		if (not Find(Streaming, v)) then
			v.CFrame = self.Original[v] or v.CFrame;
			self.Original[v] = nil;
		end
	end

	self.Streaming = Streaming;

	-- for _, TaggedPart:BasePart|Bone in next, self.AllParts do
	-- 	if (TaggedPart:IsA("BasePart") and TaggedPart:IsDescendantOf(workspace)) then -- * Is decendant of workspace to ensure that it is not being offloaded by streaming module
	-- 		TaggedPart.CanCollide = false;
	-- 		TaggedPart.Massless = true;
	-- 		TaggedPart.Anchored = true;

	-- 		local Distance = (CameraPosition - (TaggedPart.Position)).Magnitude;

	-- 		if (Distance <= self.Range) then
	-- 			self.Streaming[#self.Streaming + 1] = TaggedPart;
	-- 		elseif (self.Original[TaggedPart]) then
	-- 			TaggedPart.CFrame = self.Original[TaggedPart];
	-- 			self.Original[TaggedPart] = nil;
	-- 		end
	-- 	end
	-- end
end

local noise = math.noise;
function Wind:GetNoise(now, Variation)
	return noise(
		(now * self.WindSpeed)*.2,
		Variation * 10
	) * self.WindStrength;
end

function Wind:Start()
	if (not game:IsLoaded()) then game.Loaded:Wait(); end;

	local LastCameraPosition = Vector3.new(1e7, 1e7, 1e7);
	local LastUpdated = -math.huge;

	self.Noises = {};

	local Angles = CFrame.Angles;

	self.Profile = StreamingModule.Classes.Profile.new({
		Name = "Wind",
		Config = {
			ChunkSize = 40,
			StreamingDistance = self.Range,
			Pack = false,
		},
		CollectionServiceTag = Tag,
		DebugMode = false,
		Paused = true,
	});

	local CameraPosition = Camera.CFrame.Position;
	self:UpdateStream(CameraPosition);

	RunService.Heartbeat:Connect(function()
		CameraPosition = Camera.CFrame.Position;

		if ((LastCameraPosition - CameraPosition).Magnitude >= self.UpdateStreamDistance and (time() - LastUpdated) > .8) then
			self:UpdateStream(CameraPosition);
			LastCameraPosition = CameraPosition;
			LastUpdated = time();
		end

		local now = time();

		for i = 1, self.NoiseLayers do
			self.Noises[i] = self:GetNoise(now, i);
		end

		local PartList = self.Streaming;
		if (#PartList < 1) then return; end;

		local CFrameList = table.create(#PartList);

		debug.profilebegin("Wind update");
		for index, Part in ipairs(PartList) do
			local WindNoise = self.Noises[(index % self.NoiseLayers) + 1];
			local WindNoise2 = self.Noises[((index - 1) % self.NoiseLayers) + 1];

			if (not self.Original[Part]) then
				self.Original[Part] = Part.CFrame;
			end

			CFrameList[index] = (self.Original[Part] * Angles(WindNoise2, WindNoise, -WindNoise * .4) * self.WindDirection);
		end

		workspace:BulkMoveTo(PartList, CFrameList, Enum.BulkMoveMode.FireCFrameChanged);

		debug.profileend();
	end)
end

return Wind