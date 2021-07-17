local CollectionService = game:GetService("CollectionService");

local AnimationHandler = {
	Animations = {
		Walk = 7087279230
	},
	AnimationInstances = {}
};

local function Lerp(a:number, b:number, alpha:number)
    return a + (b - a) * alpha;
end

function AnimationHandler:Start()
	if (true) then return; end;
	
	warn("Started the thingy");
	for AnimationName:string, AnimationId:number in pairs(self.Animations) do
		local AnimationInstance = Instance.new("Animation");
		AnimationInstance.Name = AnimationName;
		AnimationInstance.AnimationId = string.format("rbxassetid://%d", AnimationId);
		AnimationInstance.Parent = script;

		self.AnimationInstances[AnimationName] = AnimationInstance;
	end

	for _, ZombieModel in ipairs(CollectionService:GetTagged("Zombie")) do
		warn("AIHNIAGUAIGUAIUG");
		self:HandleZombie(ZombieModel);
	end

	CollectionService:GetInstanceAddedSignal("Zombie"):Connect(function(...)
		self:HandleZombie(...);
	end)
end

function AnimationHandler:HandleZombie(Zombie:Model)
	print("Handling zombie");

	local LoadedAnimations = {};
	local Humanoid:Humanoid = Zombie:WaitForChild("Humanoid");

	for AnimationName, AnimationInstance in pairs(self.AnimationInstances) do
		warn(AnimationInstance);
		LoadedAnimations[AnimationName] = Humanoid:WaitForChild("Animator"):LoadAnimation(AnimationInstance);
	end

	LoadedAnimations.Walk:Play();
	Humanoid.Running:Connect(function(Speed:number)
		warn(Speed);
		-- LoadedAnimations.Walk:AdjustSpeed(math.clamp(Speed/Humanoid.WalkSpeed, 0, 1));
	end)

	local Speed = .2;
	local Increment = 0;

	LoadedAnimations.Walk:GetMarkerReachedSignal("Step"):Connect(function(StepNumber)
		warn("Stepped", StepNumber);
		Increment += 4;
	end)

	local RunService = game:GetService("RunService");
	RunService.Heartbeat:Connect(function(DeltaTime)
		Humanoid.WalkSpeed = Speed;
		-- Speed += Zombie.PrimaryPart.Velocity.Magnitude/6;
		
		Increment = Lerp(Increment, 0, .04);
		Speed = Lerp(Speed, .2 + Increment, .04);
	end)
end

function AnimationHandler:Init()

end

return AnimationHandler;