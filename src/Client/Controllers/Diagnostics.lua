local ReplicatedStorage = game:GetService("ReplicatedStorage");
local Shared = ReplicatedStorage:WaitForChild("Aero"):WaitForChild("Shared");
local Events = ReplicatedStorage:WaitForChild("Events");

local RunService = game:GetService("RunService")

local Diagnostics = {
	PingUpdateIncrements = 3.5,
	RemoteFunctionsInvoke = 0,
	RemoteEventsFired = 0,
	FrameRate = 60,
	DisplayFrameRate = 60,
	FrameData = {},
};

function Diagnostics:Start()
	local PlayerService = game:GetService("Players");
	local Player = PlayerService.LocalPlayer;

	local PlayerGui = Player:WaitForChild("PlayerGui");

	local DiagnosticsGUI = PlayerGui:WaitForChild("Diagnostics");

	local FPSText = DiagnosticsGUI:WaitForChild("FPS");
	local FrameTimeText = DiagnosticsGUI:WaitForChild("FrameTime");
	local PingText = DiagnosticsGUI:WaitForChild("Ping");

	self.RemoteFunctionsText = DiagnosticsGUI:WaitForChild("RemoteFunctions");
	self.RemoteEventsText = DiagnosticsGUI:WaitForChild("RemoteEvents");

	local PingRemoteFunction = Events:WaitForChild("Ping");

	local Updated = 0;
	local LastPingRequest = 0;

	local function Lerp(a:number, b:number, alpha:number):number
		return a + (b - a) * alpha;
	end

	local c = 0;
	RunService.RenderStepped:Connect(function(DeltaTime:number)
		if ((time() - Updated) > .25) then
			self.FrameRate = (DeltaTime);
			Updated = time();
		end
		
		table.insert(self.FrameData, self.FrameRate);
		if (#self.FrameData > 250) then
			table.remove(self.FrameData, 1);
		end

		local AverageFPS = 0;
		for _, v in ipairs(self.FrameData) do
			AverageFPS += v;
		end
		AverageFPS /= #self.FrameData;

		self.DisplayFrameRate = Lerp(self.DisplayFrameRate, self.FrameRate, .1);
		FPSText.Text = string.sub(1/self.DisplayFrameRate, 1, 5).. " FPS, average: ".. string.sub(1/AverageFPS, 1, 5);
		FrameTimeText.Text = string.sub(self.DisplayFrameRate * 1000, 1, 5) .. "ms";

		if ((time() - LastPingRequest) > self.PingUpdateIncrements) then
			LastPingRequest = time();

			local Data = {
				CurrentTime = os.clock(), -- os.clock() for high precision
			};

			local Response = PingRemoteFunction:InvokeServer(Data);
			self:InvokedRemoteFunction();
			local TimeOfResponse = os.clock();

			local Ping = (TimeOfResponse - Data.CurrentTime) * 1000;
			PingText.Text = math.round(Ping).."ms Ping";
		end
	end)
end

function Diagnostics:InvokedRemoteFunction()
	self.RemoteFunctionsInvoke += 1;
	self.RemoteFunctionsText.Text = ("%d Remote Functions Invoked"):format(self.RemoteFunctionsInvoke);
end

function Diagnostics:FiredRemoteEvent()
	self.RemoteEventsFired += 1;
	self.RemoteEventsText.Text = ("%d Remote Events Sent"):format(self.RemoteEventsFired);
end

return Diagnostics;