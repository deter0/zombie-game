local EntityMethods = {
	Droppable = require(script:WaitForChild("Droppable")),
	Model = require(script:WaitForChild("Model")),
	ReplicateToClient = require(script:WaitForChild("ReplicateToClient")),
};

for _, Method in ipairs(script:GetChildren()) do -- Auto insert them
	if (Method:IsA("ModuleScript")) then
		if (not EntityMethods[Method.Name]) then
			EntityMethods[Method.Name] = require(Method);
		end
	end
end

return EntityMethods;