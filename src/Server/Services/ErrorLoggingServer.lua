-- Error Logging Server
-- deter
-- August 19, 2021

local RunService = game:GetService("RunService");

local DataStoreService = game:GetService("DataStoreService");
local Success, ErrorsDataStore = pcall(function()
	return DataStoreService:GetOrderedDataStore(RunService:IsStudio() and "ErrorLogs-Studio" or "ErrorLogs");
end)

local ErrorLoggingServer = {
	Client = {},
	Uploads = {},
}

-- 	local RunService = game:GetService("RunService");
--  local DataStoreService = game:GetService("DataStoreService");
-- 	local ErrorsDataStore = DataStoreService:GetOrderedDataStore(RunService:IsStudio() and "ErrorLogs-Studio" or "ErrorLogs");
--  print(ErrorsDataStore:GetSortedAsync(false, 15):GetCurrentPage())

function ErrorLoggingServer:ClientDidSendData(Player, Data)
	if (not Success) then return; end;
	
	for Error, ErrorCount in pairs(Data.Errors) do
		ErrorsDataStore:IncrementAsync(Error, ErrorCount);
	end
end

function ErrorLoggingServer.Client:Post(Player, Data)
	ErrorLoggingServer:ClientDidSendData(Player, Data);
end

return ErrorLoggingServer