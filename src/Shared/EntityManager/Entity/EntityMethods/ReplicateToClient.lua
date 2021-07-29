local ReplicatedStorage = game:GetService("ReplicatedStorage");
local Shared = ReplicatedStorage:WaitForChild("Aero"):WaitForChild("Shared");

local Signal = require(Shared:WaitForChild("Signal"));

local Events = ReplicatedStorage:WaitForChild("Events");
local EntityCreated:RemoteEvent = Events:WaitForChild("EntityCreated");

local ReplicateToClient = {};

function ReplicateToClient:Remove()
	self.ReplicatedToClient:Destroy();
end

function ReplicateToClient:Apply()
	self.ReplicatedToClient = Signal.new();

	if (not self.Manager.Pause) then
		local temp = self.Manager;
		self.Manager = nil;
		EntityCreated:FireAllClients(self);
		self.Manager = temp;

		self.DidReplicate = true;
		self.ReplicatedToClient:Fire();
	else
		self.Manager.Pause:AddToReplicationQueue(self.Id);
	end

	return true, {};
end

return ReplicateToClient;