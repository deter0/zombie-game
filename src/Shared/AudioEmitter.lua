-- Audio Emitter
-- Deter
-- May 23, 2021

local ReplicatedStorage = game:GetService("ReplicatedStorage");
local RunService = game:GetService("RunService");

local Shared = ReplicatedStorage:WaitForChild("Aero"):WaitForChild("Shared");
local Config = {AudioModule = {
	ReverbEnabled = true,
	DampeningEnabled = true,
}};

local Maid = require(Shared:WaitForChild("Maid"));
local Camera = workspace.CurrentCamera;

-- local Signal = require(Shared:WaitForChild("Signal"));
local AudioModule = require(Shared:WaitForChild("AudioModule"));

local AudioEmitter = {
	Materials = {
		[Enum.Material.Wood] = .9
	}
};
AudioEmitter.__index = AudioEmitter;

function AudioEmitter.new(origin:BasePart|Vector3)
	local self = setmetatable({
		originPart = typeof(origin) == "Instance" and origin or nil,
		originPosition = (typeof(origin) == "Instance" and origin.Position) or (typeof(origin) == "Vector3" and origin) or nil,
		maid = Maid.new()
	}, AudioEmitter);

	return self;
end

local function publicCoroutine(wrappingFunction)
	local success, result = coroutine.resume(coroutine.create(wrappingFunction));

	if (not success) then
		error(result);
	end
end

type config = {volume:number, distance:number, disableReverb:bool?};
function AudioEmitter:Play(audioId, config:config, autoUpdatePosition:boolean, callback)
	self.audio = AudioModule:GetInstanceFromId(audioId);

	local audio = self.audio;

	local equalizer = audio:FindFirstChildWhichIsA("EqualizerSoundEffect");
	if (not equalizer) then
		equalizer = Instance.new("EqualizerSoundEffect");
		equalizer.MidGain = 0;
		equalizer.LowGain = 0;
		equalizer.HighGain = 0;
	end

	equalizer.Parent = audio;

	local reverb = audio:FindFirstChildWhichIsA("ReverbSoundEffect");
	if (not reverb) then
		reverb = Instance.new("ReverbSoundEffect");
		reverb.DecayTime = .3;
		reverb.DryLevel = 0;
		reverb.WetLevel = 0;
	end

	reverb.Parent = audio;


	local raycastParams = RaycastParams.new();
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist;
	local Player = game.Players.LocalPlayer;

	raycastParams.FilterDescendantsInstances = {
		self.originPart,
		Player.Character or Player.CharacterAdded:Wait()
	};

	local function reflectRay(d, raycast)
		local norm = raycast.Normal;
		return (d - (2 * d:Dot(norm) * norm));
	end

	
	-- local function displayPartAsRay(v1, v2)
	-- 	local p = Instance.new("Part")
	-- 	p.Anchored = true
	-- 	p.CanCollide = false
	-- 	p.Size = Vector3.new();
	-- 	p.Position = Vector3.new();
	-- 	p.Parent = workspace;
		
	-- 	local a1, a2 = Instance.new("Attachment");
	-- 	a1.WorldPosition = v1;
	-- 	a2 = a1:Clone();
	-- 	a2.WorldPosition = v2;
	-- 	a1.Parent = p;
	-- 	a2.Parent = p;
		
	-- 	local b = Instance.new("Beam");
	-- 	b.Attachment1 = a1;
	-- 	b.Attachment0 = a2;
		
	-- 	b.Parent = p;
	-- end

	local maxReflects = 5;
	local raycastReflectDistance = 50;
	local function castReflectedRay(v_:Vector3, d_:Vector3)
		local reflects = 0;
		local distances = {};
		local v = v_;
		local d = d_;

		local function x(v, d)
			local hit = workspace:Raycast(v, d * raycastReflectDistance, raycastParams);

			if (hit) then
				reflects += 1;
				table.insert(distances, (v - hit.Position).Magnitude);
				return reflectRay(d, hit), hit;
			else
				return -1;
			end
		end

		while (reflects <= maxReflects) do
			local r, raycast = x(v, d);
			if (r == -1) then break end;

			v = raycast.Position;
			d = r;
		end

		return reflects, distances;
	end

	local function getEchoInformation()
		local raysToCast = 3;
		local all = {};

		for y = -5, 5 do
			for i = 0, math.pi, math.pi / raysToCast do
				local dir = (Vector3.new(math.cos(i), y/3, math.sin(i))/y).Unit;
				local reflect, distances = castReflectedRay(self.originPosition, dir);

				table.insert(all, {reflect, distances});
			end
		end

		local averageDistance = 0;
		local i_2 = 0;

		local average = 0;
		local i = 0;
		for _, v in ipairs(all) do
			average += v[1];

			for _, z in ipairs(v[2]) do
				averageDistance += z;
				i_2 += 1;
			end
		end

		averageDistance /= i_2;

		return average, averageDistance;
	end

	publicCoroutine(function()
		local counter = 90;

		self.maid.renderLoop = RunService.RenderStepped:Connect(function()
			local distanceFromEmitter = (self.originPosition - Camera.CFrame.Position).Magnitude;
			local volume = math.clamp(1/((distanceFromEmitter/config.distance)^2), 0, config.distance);
			
			local raycast;
			local raycast2;

			if (Config.AudioModule.DampeningEnabled) then
				local a = self.originPosition-Camera.CFrame.Position;
				local b = Camera.CFrame.Position-self.originPosition;
				raycast = workspace:Raycast(Camera.CFrame.Position, (a.Unit * (a.Magnitude - .5)), raycastParams);
				raycast2 = workspace:Raycast(self.originPosition, (b.Unit * b.Magnitude), raycastParams);
			else
				equalizer.MidGain = 0;
				equalizer.LowGain = 0;
				equalizer.HighGain = 0;
			end
				
			if (autoUpdatePosition) then
				self:UpdatePosition();
			end
			
			if (raycast and raycast2) then
				local dampening = (raycast.Position - raycast2.Position).Magnitude;
				local x = math.clamp(dampening/10, 0, math.huge) * (self.Materials[raycast.Material] or 1);
				equalizer.HighGain = -(x * 16);
				equalizer.MidGain = -(x * 8);
				
				volume *= 1 - math.clamp(dampening/100, 0, math.huge);
			end
			
			if (Config.AudioModule.ReverbEnabled and not config.disableReverb) then
				counter += 1;
				if (counter >= 90) then
					counter = 0;
					local bounces, averageDistance = getEchoInformation();
					local bounceFactor = ((bounces *  (1 - (averageDistance/50)))/230);

					reverb.DryLevel = -(55 * (bounceFactor));
					reverb.DecayTime = (20 * (bounceFactor))
					reverb.WetLevel =  (10*(1 - averageDistance/50));
				end
			else
				reverb.DecayTime = .3;
				reverb.DryLevel = 0;
				reverb.WetLevel = 0;
			end

			audio.Volume = (volume/config.distance) * config.volume;
		end)
	end)

	self.audio:Play();
	self.audio.Stopped:Connect(function()
		self.maid:DoCleaning();

		if (callback) then
			callback();
		end
	end)

	return function()
		self.Maid:DoCleaning();
	end
end

function AudioEmitter:UpdatePosition(origin)
	-- self.originPart = origin and (type(origin) == "Instance" and origin) or self.originPart;
	self.originPosition = self.originPart.Position;
end

return AudioEmitter;