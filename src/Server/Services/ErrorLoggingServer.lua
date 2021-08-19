-- Error Logging Server
-- deter
-- August 19, 2021

local RunService = game:GetService("RunService");

local DataStoreService = game:GetService("DataStoreService");
local ErrorsDataStore = DataStoreService:GetOrderedDataStore(RunService:IsStudio() and "ErrorLogs-Studio" or "ErrorLogs");

local ErrorLoggingServer = {
	Client = {},
	Uploads = {},
}

function ErrorLoggingServer:ClientDidSendData(Player, Data)
	for Error, ErrorCount in pairs(Data.Errors) do
		ErrorsDataStore:IncrementAsync(Error, ErrorCount);
	end
end

function ErrorLoggingServer.Client:Post(Player, Data)
	ErrorLoggingServer:ClientDidSendData(Player, Data);
end

return ErrorLoggingServer