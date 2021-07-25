local ReplicatedStorage = game:GetService("ReplicatedStorage");
local Shared = ReplicatedStorage:WaitForChild("Aero"):WaitForChild("Shared");

local Status = require(Shared:WaitForChild("Status"));

local Entity = require(script:WaitForChild("Entity"));

local EntityManager = {
	Entities = {},
	Templates = {},
};

function EntityManager:CreateTemplateEntity(EntityClassName:string, CreatedEntity)
	if (self.Templates[EntityClassName]) then
		return Status(409, "Entity Already Exists.")
	end

	self.Templates[EntityClassName] = CreatedEntity;
end

function EntityManager:CreateEntityFromTemplate(EntityTemplateName:string, ...)
	if (self.Templates[EntityTemplateName]) then
		return Entity.new(self.Templates[EntityTemplateName], ...);
	else
		return Status(404, "Entity Not Found.");
	end
end

return EntityManager;