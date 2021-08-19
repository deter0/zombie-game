local PlayerService = game:GetService("Players");
local LogService = game:GetService("LogService");

local ReplicatedStorage = game:GetService("ReplicatedStorage");
local Events = ReplicatedStorage:WaitForChild("Events");

local ErrorLogging = {
	SessionData = {
		Errors = {},
		FPS = {},
		Ping = {},
	},
	LastError = 0,
	ScheduledPost = nil,

	ErrorPostIntervals = 8,
};

function ErrorLogging:Start()
	LogService.MessageOut:Connect(function(Message, MessageType)
		if (MessageType == Enum.MessageType.MessageError) then
			local ErrorCount = self.SessionData.Errors[Message];
			self.SessionData.Errors[Message] = ErrorCount and ErrorCount + 1 or 1;

			self:Errored();
		end
	end)

	local RunService = game:GetService("RunService");
	RunService.Heartbeat:Connect(function()
		if (self.ScheduledPost) then
			if (tick() >= self.ScheduledPost) then
				self.LastError = tick();
				self.ScheduledPost = nil;
				self:SendToServer();
			end
		end
	end)

	return;
end

function ErrorLogging:Errored()
	if ((tick() - self.LastError) < self.ErrorPostIntervals) then
		self.ScheduledPost = tick() + self.ErrorPostIntervals;
	else
		self:SendToServer();
		self.LastError = tick();
	end
end

function ErrorLogging:SendToServer()
	self.Services.ErrorLoggingServer:Post(self.SessionData);
end

return ErrorLogging;