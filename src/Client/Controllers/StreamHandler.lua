-- Stream Handler
-- deter
-- August 10, 2021

local ReplicatedStorage = game:GetService("ReplicatedStorage");
local Shared = ReplicatedStorage:WaitForChild("Aero"):WaitForChild("Shared");

local RunService = game:GetService("RunService");
local StreamingModule = require(Shared:WaitForChild("StreamingModule"));

local StreamHandler = {};

function StreamHandler:Start()
	local Streams = require(game:GetService("ReplicatedStorage"):WaitForChild("Streams"));

	for _, Stream in ipairs(Streams) do
		print("created stream", Stream.Name, Stream.Config);
		StreamingModule:CreateProfile(Stream.Name, Stream.Config, {}, Stream.Tag, Stream.VisualizeChunks);
	end

	StreamingModule:StartStreamingAllSimultanously();
end

return StreamHandler;