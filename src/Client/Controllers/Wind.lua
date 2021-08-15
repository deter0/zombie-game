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
	WindSpeed = .5,
	WindStrength = 3,
	UpdateStreamDistance = 25,
	WindDirection = Vector3.new(1, 1, 1),
	Streaming = {},
	NoiseLayers = 24
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

	local Angles, rad = CFrame.Angles, math.rad;

	self.Profile = StreamingModule.Classes.Profile.new({
		Name = "Wind",
		Config = {
			ChunkSize = 128,
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
		debug.profilebegin("Wind update");
		CameraPosition = Camera.CFrame.Position;

		if ((LastCameraPosition - CameraPosition).Magnitude >= self.UpdateStreamDistance and (time() - LastUpdated) > .8) then
			self:UpdateStream(CameraPosition);
			LastCameraPosition = CameraPosition;
			LastUpdated = time();
		end

		local now = time() * self.WindSpeed;

		local PartList = self.Streaming;
		if (#PartList < 1) then return; end;

		local CFrameList = table.create(#PartList);

		for index, Part in ipairs(PartList) do
			if (not self.Original[Part]) then
				self.Original[Part] = Part.CFrame;
			end

			local WindNoise = rad(noise(Part.Position.X, now, Part.Position.Z));
			local WindNoise2 = rad(noise(Part.Position.X, now+Part.Position.X, Part.Position.Z));
			local WindNoise3 = rad(noise(Part.Position.X, now+Part.Position.Z, Part.Position.Z));

			local Noise = Vector3.new(WindNoise2, WindNoise3, -WindNoise * .4) * self.WindStrength;
			CFrameList[index] = self.Original[Part] * Angles(Noise.X, Noise.Y, Noise.Z);
		end

		workspace:BulkMoveTo(PartList, CFrameList, Enum.BulkMoveMode.FireCFrameChanged);

		debug.profileend();
	end)
end

return Wind