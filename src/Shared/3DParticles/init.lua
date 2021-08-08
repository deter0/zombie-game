local RunService = game:GetService("RunService");

export type ParticleEmitter3D = {
	Particles:number,
	Force:number,
	LifeTime:number,
	MinSpreadAngle:number,
	MaxSpreadAngle:number,
	Acceleration:Vector3,
	TargetDirection:Vector3?,
	TargetDirectionStrength:number?,
	ParticleInstance:BasePart|Model|nil,
	ParticleParent: Instance?,

	Random:Random,
	new: (ParticleEmitter3D?) -> ParticleEmitter3D,
	Emit: (Vector3) -> nil,
	EmitOne: (Vector3) -> nil,
	AddParticleToUpdate: (Instance) -> nil,

	UpdateQueue: {[number]: {TimeAdded:number, Particle:BasePart|Model, Velocity:Vector3}},
	Update: (number) -> nil,
};

local ParticleEmitter = {
	LifeTime = 5,
	Particles = 1,
	Force = 1500,
	MinSpreadAngle = 0,
	MaxSpreadAngle = 360,
	TargetDirectionStrength = 0,
	TargetDirection = nil,
	ParticleInstance = nil,

	Acceleration = Vector3.new(0, -196.6, 0),

	PhysicsEnabled = true,

	UpdateQueue = {},
};
ParticleEmitter.__index = ParticleEmitter;

function ParticleEmitter.new(Inheritance:ParticleEmitter3D?):ParticleEmitter2D
	local self:ParticleEmitter2D = setmetatable(Inheritance or {}, ParticleEmitter);

	self.Random = Random.new();
	task.spawn(function()
		RunService.Heartbeat:Connect(function(DeltaTime)
			self:Update(DeltaTime);
		end)
	end)

	return self;
end

function ParticleEmitter:Emit(Position:Vector3, ...)
	for _ = 1, self.Particles do
		self:EmitOne(Position, ...);
	end
end

function ParticleEmitter:EmitOne(Position:Vector3)
	local RandomDirection:Vector3 = CFrame.fromOrientation(
		math.rad(self.Random:NextNumber(self.MinSpreadAngle, self.MaxSpreadAngle)),
		math.rad(self.Random:NextNumber(self.MinSpreadAngle, self.MaxSpreadAngle)),
		0
	).LookVector;

	if (self.ParticleInstance) then
		local DirectionalCFrame = CFrame.lookAt(Position, Position + (RandomDirection * 3));

		local CloneInstance:BasePart|Model = self.ParticleInstance:Clone();

		if (CloneInstance:IsA("BasePart")) then
			CloneInstance.CFrame = DirectionalCFrame;
			CloneInstance.Anchored = not self.PhysicsEnabled;
			CloneInstance.CanCollide = self.PhysicsEnabled;
		else
			CloneInstance:SetPrimaryPartCFrame(DirectionalCFrame);
			CloneInstance.PrimaryPart.Anchored = not self.PhysicsEnabled;
			CloneInstance.PrimaryPart.CanCollide = self.PhysicsEnabled;
		end

		CloneInstance.AssemblyLinearVelocity = Vector3.new(RandomDirection * self.Force);

		CloneInstance.Parent = self.ParticleParent or workspace;
		self:AddParticleToUpdate(CloneInstance, DirectionalCFrame.LookVector);
	else
		warn("no instance");
	end
end

function ParticleEmitter:AddParticleToUpdate(Particle:BasePart|Model, Direction:Vector3)
	self.UpdateQueue[#self.UpdateQueue+1] = {
		Particle = Particle,
		TimeAdded = time(),
		Velocity = Direction * self.Force,
	};
end

function ParticleEmitter:Update(DeltaTime:number)
	for index, Particle in ipairs(self.UpdateQueue) do
		if ((time() - Particle.TimeAdded) >= self.LifeTime) then
			Particle.Particle:Destroy();
			self.UpdateQueue[index] = nil;
			continue;
		end
	end
end

return ParticleEmitter;