-- Blood Handler
-- Deter
-- June 22, 2021

local ReplicatedStorage = game:GetService("ReplicatedStorage");
local Shared = ReplicatedStorage:WaitForChild("Aero"):WaitForChild("Shared");

local Thread = require(Shared:WaitForChild("Thread"));
local Ragdoll = require(Shared:WaitForChild("Ragdoll"));

local Events = ReplicatedStorage:WaitForChild("Events");
local BloodFolder = ReplicatedStorage:WaitForChild("Particles"):WaitForChild("Blood");

local BloodHandler = {
    ActiveRagdolls = {},
    ActiveParticles = {}
};

function BloodHandler:Start()
	Events:WaitForChild("BloodEffect").OnClientEvent:Connect(function(Position:Vector3, BloodType:string, BloodConfig)
        local BloodPart = BloodFolder:FindFirstChild(BloodType);

        print(BloodType);

        if (BloodPart) then
            BloodPart = BloodPart:Clone();
            BloodPart.Parent = workspace:WaitForChild("CosmeticBulletsFolder");
            BloodPart.Position = Position;

            delay(.4, function()
                BloodPart:FindFirstChildWhichIsA("ParticleEmitter").Enabled = false;
                wait(1);
                BloodPart:Destroy();
            end)
        end
    end)

    Events:WaitForChild("Ragdoll").OnClientEvent:Connect(function(Character:Model, Direction:Vector3, Part:BasePart, HitPosition:Vector3?)
        if (self.ActiveRagdolls[Character]) then return; end;
        
        local CharacterRagdoll = Ragdoll.new(Character);
        CharacterRagdoll:setRagdolled(true);


        delay(1, function()
            warn(Part, Direction * 5000);
    
            Part:ApplyImpulse(Direction * 5000);
        end)

        self.ActiveRagdolls[Character] = {
            Created = time(),
            Ragdoll = CharacterRagdoll
        }
    end)

    Thread.DelayRepeat(25, function()
        for index, ActiveRagdoll in pairs(self.ActiveRagdolls) do
            if ((time() - ActiveRagdoll.Created) > 60) then
                warn("Cleared ragdoll");

                ActiveRagdoll.Ragdoll:destroy();
                table.clear(ActiveRagdoll);

                self.ActiveRagdolls[index] = nil;
            end
        end
    end)

    -- self:
end

function BloodHandler:HighFidelityEffect(Position:Vector3, Direction:Vector3, Strength:number?)
    Strength = (not Strength or Strength < 1 and 1) or Strength;
    Direction = (Direction.Magnitude > 1 and Direction.Unit) or Direction;

    local ToEmit = math.ceil(Strength/10);
    local AllParticles = ReplicatedStorage:WaitForChild("Particles"):WaitForChild("BloodHighFidelity"):GetChildren();

    Thread.Spawn(function()
        local Parts = {};

        for i = 1, ToEmit do
            Parts[i] = AllParticles[math.random(#AllParticles)]:Clone();
        end

        local function SpawnParticle()
            local Particle = Parts[math.random(#Parts)];

            Particle.Position = Position;

            local ParticleDirection = Vector3.new(
                math.random(),
                math.random(),
                math.random()
            ).Unit:Lerp(
                Direction, Strength / 1.4
            );

            Particle.Parent = workspace.CosmeticBulletsFolder;

            self.ActiveParticles[#self.ActiveParticles + 1] = {Object = Particle, Direction = ParticleDirection, Strength = Strength};
        end

        for _ = 1, #Parts do
            SpawnParticle();
            wait(math.random()/4);
        end
    end)
end

return BloodHandler