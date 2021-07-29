local ReplicatedStorage = game:GetService("ReplicatedStorage");
local Shared = ReplicatedStorage:WaitForChild("Aero"):WaitForChild("Shared");

local Events = ReplicatedStorage:WaitForChild("Events");

local Status = require(Shared:WaitForChild("Status"));
local TableUtil = require(Shared:WaitForChild("TableUtil"));

local Entity = require(script:WaitForChild("Entity"));

local EntityManager = {
	Entities = {},
	Templates = {},
	ReplicatedEntities = {},
	Client = {},
};

function EntityManager:CreateTemplateEntity(EntityClassName:string, CreatedEntity)
	if (self.Templates[EntityClassName]) then
		return Status(409, "Entity Already Exists.")
	end

	self.Templates[EntityClassName] = CreatedEntity;
end

function EntityManager:EntityDidReplicate(EntityThatReplicated)
	self.ReplicatedEntities[EntityThatReplicated.Id] = EntityThatReplicated;
end

function EntityManager:EntityDestroyed(EntityThatDestroyed)
	self.ReplicatedEntities[EntityThatDestroyed.Id] = nil;
	self.Entities[EntityThatDestroyed.Id] = nil;
end

function EntityManager:CreateEntityFromTemplate(EntityTemplateName:string, ...)
	if (self.Templates[EntityTemplateName]) then
		local NewEntity = Entity.new(self.Templates[EntityTemplateName], self, ...);

		if (NewEntity.ReplicatedToClient) then
			if (NewEntity.DidReplicate) then -- If it's already replicated
				self:EntityDidReplicate(NewEntity);
			end

			NewEntity.ReplicatedToClient:Connect(function()
				print("Entity did replicate");
				self:EntityDidReplicate(NewEntity);
			end)
		end

		self.Entities[NewEntity.Id] = NewEntity;

		return NewEntity;
	else
		return Status(404, "Entity Not Found.");
	end
end

function EntityManager:PauseEntityReplication()
	local Pause = {
		ToReplicate = {};
	};

	local this = self;
	function Pause:Release()
		this:ReplicateMultiple(self.ToReplicate);
		this.Pause = nil;
		this = nil;
		table.clear(self);
	end

	function Pause:AddToReplicationQueue(Id:string)
		self.ToReplicate[#self.ToReplicate+1] = Id;
	end

	self.Pause = Pause;

	return Pause;
end

function EntityManager:ReplicateMultiple(Multiple)
	print("REPLICATING MULTIPLe:", Multiple);
	local Entities = {};

	for _, EntityId in ipairs(Multiple) do
		Entities[EntityId] = self.Entities[EntityId];
	end

	local Clean = self:GetClean(Entities);

	Events:WaitForChild("EntityCreated"):FireAllClients(Clean);
end

-- * Start Function

function EntityManager:Start()
	-- * Hookups
	local GetEntities:RemoteFunction = Events:WaitForChild("GetEntities");

	GetEntities.OnServerInvoke = function(...)
		return self:RequestAllEntities(...);
	end
end

-- * Client functions

function EntityManager:GetClean(Entities)
	local Clean = {};

	for i, v in pairs(Entities) do
		Clean[i] = v;
		
		for index, _v in pairs(Clean[i]) do
			if (type(_v) == "table" and _v._connections) then -- if it's a signal.
				Clean[i][index] = nil;
			end
		end
		Clean[i].Manager = nil;
	end

	return Clean;
end

function EntityManager:RequestAllEntities(Player:Player)
	local ToReplicate = self:GetClean(self.ReplicatedEntities);

	return ToReplicate;
end

return EntityManager;