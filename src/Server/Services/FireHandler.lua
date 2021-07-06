-- Fire Handler
-- Deter
-- June 28, 2021

local RunService = game:GetService("RunService");

local ReplicatedStorage = game:GetService("ReplicatedStorage");
local Shared = ReplicatedStorage:WaitForChild("Aero"):WaitForChild("Shared");

-- local TableUtil = require(Shared:WaitForChild("TableUtil"));
local Thread = require(Shared:WaitForChild("Thread"));

local FireHandler = {
    FireTick = 1,
    MinimumFireVertexDistance = 7,
    FireVertices = {},
    FireSources = {},
    Client = {}
};

type FireVertex = {
    Position: Vector3,
    Attachment: Attachment
};

local Particles = ReplicatedStorage:WaitForChild("Particles");
local FireParticles = Particles:WaitForChild("Fire");

local Fire = {
    MaxSize = 10
};
Fire.__index = Fire;

function Fire:SetSize(Size:number)
    self.Size = Size or self.Size or 0;

    -- self.FireCore.Size = NumberSequence.new({
    --     NumberSequenceKeypoint.new(0, 0, 0),
    --     NumberSequenceKeypoint.new(.194, Size, 0),
    --     NumberSequenceKeypoint.new(1, 0, 0)
    -- });
    self.Fire4.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, .76, 0),
        NumberSequenceKeypoint.new(.1, Size/2, 0),
        NumberSequenceKeypoint.new(1, Size*1.2, 0)
    });
    self.Fire2.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, .687, 0),
        NumberSequenceKeypoint.new(.1, Size/4, 0),
        NumberSequenceKeypoint.new(1, Size, 0)
    });
    self.Smoke.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, .76, 0),
        NumberSequenceKeypoint.new(.1, Size/3, 0),
        NumberSequenceKeypoint.new(1, Size/2, 0)
    });
    self.Smoke2.Size = self.Smoke.Size;
    self.Smoke3.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, .76, 0),
        NumberSequenceKeypoint.new(.1, Size/1.6, 0),
        NumberSequenceKeypoint.new(1, Size/1.1, 0)
    });

    -- self.Particle.Lifetime = NumberRange.new(self.Size*2.25);
    -- self.Light.Range = self.Size*4;
    -- self.Light.Brightness = self.Size / 12;
end

function Fire.new(FireVertex:FireVertex)
    local self = setmetatable({}, Fire);

    for _, Particle in ipairs(FireParticles:GetChildren()) do
        self[Particle.Name] = Particle:Clone();
        self[Particle.Name].Parent = FireVertex.Attachment;
    end

    self:SetSize(0);

    return self;
end

function FireHandler:Start()
    if (true) then return; end;
    
	self.Fire = workspace:WaitForChild("Fire");

    ReplicatedStorage:WaitForChild("Events"):WaitForChild("CreateFireVertex").OnServerEvent:Connect(function(Player, MousePosition:Vector3)
        self:AddFireVertex(MousePosition);
    end)

    Thread.Spawn(function()
        local Frame = 0;

        RunService.Heartbeat:Connect(function(DeltaTime)
            Frame += 1;
            if (Frame >= self.FireTick) then Frame = 0; else return; end;

            for _, FireEmitter in ipairs(self.FireSources) do
                for _, FireVertex in ipairs(self.FireVertices) do
                    local Distance = (FireEmitter.Position - FireVertex.Position).Magnitude;

                    if (Distance < self.MinimumFireVertexDistance) then
                        FireVertex:Damage(FireEmitter.Strength * (1-(Distance / self.MinimumFireVertexDistance)));
                    end
                end
            end

            for _, FireVertex in ipairs(self.FireVertices) do
                FireVertex:Update(DeltaTime);
            end
        end)
    end)
end


local FireCaster = {
    Strength = 15
};
FireCaster.__index = FireCaster;

function FireCaster.new(Position:Vector3, Strength:number?)
    local self = setmetatable({}, FireCaster);

    self.Strength = Strength or 10;
    self.Position = Position;

    return self;
end



local FireVertex = {
    Health = 100,
    Resistence = 60,
    SelfDamage = 0
};

FireVertex.__index = FireVertex;

function FireVertex:Damage(Amount:number)
    Amount = Amount * ((100 - FireVertex.Resistence) / 100);
    self.SelfDamage = math.tan(Amount) / 4;
    self.Health -= Amount;
end

function FireVertex:Update(DeltaTime)
    self.Health -= self.SelfDamage * (DeltaTime * 5);
    self.SelfDamage = self.SelfDamage / 2;

    self.Health = self.Health < 0 and 0 or self.Health;

    self.FireCaster.Strength = (1-(self.Health/100))*self.Fire.Size;

    self.Fire:SetSize((100-self.Health)/10);
end

function FireVertex:SetAttachmentVisible(Visible:boolean)
    self.Attachment.Visible = Visible;
end

function FireVertex:SetPosition(NewPosition:Vector3)
    self.Position = NewPosition;
    self.Attachment.WorldPosition = self.Position;

    FireHandler:FireVertexChangedAdded(self, self.Index);
end

function FireVertex.new(Position:Vector3)
    local self = setmetatable({Position = Position}, FireVertex);

    local FireAttachment = Instance.new("Attachment");
    FireAttachment.Name = ("fire_attachment_%d"):format(#FireHandler.FireVertices + 1);
    FireAttachment.WorldPosition = Position;
    
    FireAttachment.Parent = FireHandler.Fire;
    
    FireHandler.FireVertices[#FireHandler.FireVertices + 1] = self;
    
    self.Attachment = FireAttachment;
    self.FireCaster = FireCaster.new(self.Position, 0);
    
    self.Fire = Fire.new(self);

    FireHandler.FireSources[#FireHandler.FireSources + 1] = self.FireCaster;
    
    return self;
end

function FireVertex:Ignite()
    if (not self.Ignited) then
        self.Fire = Instance.new("Fire");
        self.Fire.Parent = self.Attachment;
        self.Ignited = true;

        delay(.3, function()
            FireHandler:MatchLit(self.Position);
        end)
    end
end

function FireHandler:AddFireVertex(Position:Vector3)
    local NewFireVertex:FireVertex = FireVertex.new(Position);
    NewFireVertex:SetAttachmentVisible(true);
end

function FireHandler:DisplayAttachment(Position:Vector3, Name:string?)
    self.DisplayAttachments = self.DisplayAttachments or {};

    
    local DisplayAttachment = Instance.new("Attachment");
    DisplayAttachment.Name = (Name or "display_attachment");
    DisplayAttachment.WorldPosition = Position;
    DisplayAttachment.Visible = true;

    if (Name) then
        if (self.DisplayAttachments[Name]) then
            self.DisplayAttachments[Name]:Destroy();
        end

        self.DisplayAttachments[Name] = DisplayAttachment;
    end
    
    DisplayAttachment.Parent = self.Fire;
end

function FireHandler:MatchLit(Position:Vector3)
	local NewFireCaster = FireCaster.new(Position);

    self.FireSources[#FireHandler.FireSources + 1] = NewFireCaster;

    return NewFireCaster;
end

return FireHandler;