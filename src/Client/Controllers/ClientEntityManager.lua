-- Client Entity Manager
-- Deter
-- July 27, 2021

local ReplicatedStorage = game:GetService("ReplicatedStorage");
local Shared = ReplicatedStorage:WaitForChild("Aero"):WaitForChild("Shared");

local Events = ReplicatedStorage:WaitForChild("Events");
local EntityCreated = Events:WaitForChild("EntityCreated");

local ClientEntityManager = {
	Entities = {}
};

function ClientEntityManager:Start()
	local GetEntities:RemoteFunction = Events:WaitForChild("GetEntities");
	self.Entities = GetEntities:InvokeServer();

	EntityCreated.OnClientEvent:Connect(function(...)
		self:EntityCreated(...);
	end)
end

function ClientEntityManager:EntityCreated(Entity)
	print("Entity created!", Entity);
	if (type(Entity) == "table" and not Entity.IsEntity) then -- * Single Entity was created
	else
		print("Multiple entities created.", Entity);
	end
end

return ClientEntityManager;