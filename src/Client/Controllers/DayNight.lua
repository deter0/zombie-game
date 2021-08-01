local RunService = game:GetService("RunService");
local LightingService = game:GetService("Lighting");

local Cycle = {};

local ColorShiftColors = {
	[0] = Color3.fromRGB(171, 182, 255),
	[4] = Color3.fromRGB(171, 182, 255),
	[5] = Color3.fromRGB(255, 136, 32),
	[7] = Color3.fromRGB(255, 136, 32),
	[8] = Color3.fromRGB(255, 153, 93),
	[15] = Color3.fromRGB(255, 245, 235),
	[17] = Color3.fromRGB(255, 136, 32), -- 255, 136, 32
	[18] = Color3.fromRGB(171, 182, 255),
	[24] = Color3.fromRGB(171, 182, 255),
};
local Exposures = { 
	[0] = 0.27,
	[6] = 0.27,
	[7] = 0.6,
	[17] = 0.6,
	[19] = 0.27,
	[24] = 0.27
};

local function GetNext(Table, Value)
	local Next = Table[Value];

	local len = 0;
	for _, _ in pairs(Table) do len += 1; end;

	while (not Next and Value <= len) do
		Value += 1;
		Next = Table[Value];
	end
end

local function Lerp(a:number, b:number, alpha:number):number
	return a + (b - a) * alpha;
end

function Cycle:Start()
	if (true) then return; end; -- TODO(deter): Enable this and make night settings look good
	RunService.Heartbeat:Connect(function(DeltaTime)
		local Now = tick();
		local CurrentGameTime = (Now * 1/15) % 24; -- Now * 1/60 = real time, 1/15 = a good game day time

		LightingService.ClockTime = CurrentGameTime;

		local CurrentTimeRounded = math.round(LightingService.ClockTime);

		local Closest = GetNext(ColorShiftColors, CurrentTimeRounded);
		if (Closest) then
			LightingService.ColorShift_Top = LightingService.ColorShift_Top:Lerp(Closest, 5 * DeltaTime);
		end

		local Exposure = GetNext(Exposures, CurrentTimeRounded);
		if (Exposure) then
			print(Exposure);
			LightingService.ExposureCompensation = Lerp(LightingService.ExposureCompensation, Exposure, 5 * DeltaTime);
		end
	end)
end

return Cycle;