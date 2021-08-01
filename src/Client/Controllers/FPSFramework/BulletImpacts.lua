local ReplicatedStorage = game:GetService("ReplicatedStorage");
local Shared = ReplicatedStorage:WaitForChild("Aero"):WaitForChild("Shared");

local Thread = require(Shared:WaitForChild("Thread"));

local RunService = game:GetService("RunService");

local Particles = ReplicatedStorage:WaitForChild("Particles");
local SoundsEffects = ReplicatedStorage:WaitForChild("SFX");

local ImpactPart:BasePart = Instance.new("Part");
ImpactPart.Anchored = true;
ImpactPart.CanCollide = false;
ImpactPart.Transparency = 1;

ImpactPart.Parent = workspace;

local BulletImpacts = {
	Sounds = {
		[Enum.Material.Grass] = "Grass",

		[Enum.Material.Concrete] = "Concrete",
		[Enum.Material.Brick] = "Concrete",
		[Enum.Material.Rock] = "Concrete",
		[Enum.Material.Asphalt] = "Concrete",
		[Enum.Material.Slate] = "Concrete",
		[Enum.Material.Cobblestone] = "Concrete",

		[Enum.Material.Wood] = "Wood",
		[Enum.Material.WoodPlanks] = "Wood",

		[Enum.Material.Metal] = "Metal",
		[Enum.Material.CorrodedMetal] = "Metal",

		[Enum.Material.Ground] = "Ground",
		[Enum.Material.LeafyGrass] = "Ground",
		[Enum.Material.Grass] = "Ground",

		[Enum.Material.Glass] = "Glass",

		["Default"] = "Concrete"
	}
};

local BulletImpactSounds:Folder = SoundsEffects:WaitForChild("BulletImpacts");

function BulletImpacts:Impacted(Position:Vector3, Normal:Vector3, Material:Enum.Material)
	local SoundEffectName:string = self.Sounds[Material] or self.Sounds.Default;
	local SoundFolder = BulletImpactSounds:FindFirstChild(SoundEffectName);

	local Sound:Sound?;

	-- if (SoundFolder) then
	-- 	local SoundFolderSounds:{Sound} = SoundFolder:GetChildren();
	-- 	Sound = SoundFolderSounds[math.random(#SoundFolderSounds)]:Clone();
	-- end

	local Particle = Particles:WaitForChild("BulletImpacts"):WaitForChild("A"):FindFirstChildWhichIsA("Attachment"):Clone();

	Particle.WorldCFrame = CFrame.lookAt(Position, Position + Normal);
	Particle.Parent = ImpactPart;

	coroutine.resume(coroutine.create(function()
		wait(0.15);

		for _, _Particle in ipairs(Particle:GetChildren()) do
			_Particle:Destroy();
		end
	end))
end

return BulletImpacts;