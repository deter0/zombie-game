-- Server Diagnostics
-- Deter
-- July 25, 2021

local ReplicatedStorage = game:GetService("ReplicatedStorage");
local Events = ReplicatedStorage:WaitForChild("Events");
local Shared = ReplicatedStorage:WaitForChild("Aero"):WaitForChild("Shared");

local RunService = game:GetService("RunService")

local ServerDiagnostics = {Client = {}}


function ServerDiagnostics:Start()
	local Ping = Events:WaitForChild("Ping");

	Ping.OnServerInvoke = function(_, Data)
		return {
			TimeOfSending = os.clock(),
		}
	end;
end


function ServerDiagnostics:Init()
	
end


return ServerDiagnostics