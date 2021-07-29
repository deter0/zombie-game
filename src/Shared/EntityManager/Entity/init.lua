local ReplicatedStorage = game:GetService("ReplicatedStorage");
local HttpService = game:GetService("HttpService");

local Shared = ReplicatedStorage:WaitForChild("Aero"):WaitForChild("Shared");

require(Shared:WaitForChild("Types")); -- Import all base types

local EntityMethods = require(script:WaitForChild("EntityMethods")); -- Get all entity methods

export type Entity = {
	EntityCreated: nil | Signal | (Entity, any) -> (),
	Model: Model | BasePart | nil,
	Droppable: boolean?,
	Drop: (Vector3?, CFrame?) -> boolean,
	RestrictedOverrides: {[string]: boolean},
	AppliedEntityMethods: {[string]: boolean},
	Id: string
};

local Entity = {
	RestrictedOverrides = {["new"] = true, ["Create"] = true, ["Update"] = true},
	AppliedEntityMethods = {},
	ClassName = "Entity",
	IsEntity = true
};
Entity.__index = Entity;

function Entity:__newindex(Index:any, value:any)
	if (not self.RestrictedOverrides[Index]) then
		rawset(self, Index, value);
	else
		error(("Cannot set %s (locked)"):format(tostring(Index)));
	end
end

function Entity:SafeFireSignal(SignalIndex:string, ...)
	local SignalToFire = self[SignalIndex];

	if (SignalToFire and type(SignalToFire) == "table" and SignalToFire._connections) then -- Verify that it's a signal with (...)._connections
		SignalToFire:Fire(...);
	elseif (SignalToFire and type(SignalToFire) == "function") then -- If it's a function then just call it
		SignalToFire(self, ...);
	end
end

function Entity:Update()
	local NewAppliedEntityMethods = {};
	for index, value in pairs(self) do
		if (EntityMethods[index] and value and not NewAppliedEntityMethods[index]) then
			local DidApplyMethods, DisableOverride = EntityMethods[index].Apply(self);

			if (not DidApplyMethods) then continue; end;

			for _, ToDisable:string in ipairs(DisableOverride) do
				self.RestrictedOverrides[ToDisable] = true;
			end

			NewAppliedEntityMethods[index] = true;
		end
	end

	for MethodIdentifier:string, _ in pairs(self.AppliedEntityMethods) do
		if (not NewAppliedEntityMethods[MethodIdentifier]) then
			local DidRemoveMethods, UnRestrictIndexes = EntityMethods[MethodIdentifier].Remove(self);

			if (not DidRemoveMethods) then continue; end;

			for _, ToDisable:string in ipairs(UnRestrictIndexes) do
				self.RestrictedOverrides[ToDisable] = nil;
			end
		end
	end

	self.AppliedEntityMethods = NewAppliedEntityMethods;
end

function Entity.new(DefaultEntityData, Manager, EntityData:Entity)
	local this = DefaultEntityData or {};

	for index, value in pairs(EntityData or {}) do
		this[index] = value;
	end

	this = setmetatable(this, Entity);

	this.Id = HttpService:GenerateGUID(false);

	this.Manager = Manager;
	this:Update();
	this:SafeFireSignal("EntityCreated");

	return this;
end

return Entity;