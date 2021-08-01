-- Wind
-- Deter
-- July 1, 2021

local RunService = game:GetService("RunService");
local CollectionService = game:GetService("CollectionService");
local Camera = workspace.CurrentCamera or workspace:WaitForChild("Camera");
local Tag = "WindShake";

local Wind = {
    Range = 90,
    Noises = {},
    Original = {},
    WindSpeed = 3,
    WindStrength = .1,
    UpdateStreamDistance = 50,
    WindDirection = CFrame.Angles(0, 0, 0),
    Streaming = {},
    NoiseLayers = 7
};

function Wind:UpdateStream(CameraPosition)
    self.Streaming = {};
    
    for index, TaggedPart:BasePart|Bone in ipairs(self.AllParts) do
        if (index % 300 == 0) then RunService.Heartbeat:Wait(); end;
        
        if (TaggedPart:IsA("BasePart")) then
            TaggedPart.CanCollide = false;
            TaggedPart.Massless = true;
            TaggedPart.Anchored = true;
            
            local Distance = (CameraPosition - (TaggedPart.Position)).Magnitude;
            
            if (Distance <= self.Range) then
                self.Streaming[#self.Streaming + 1] = TaggedPart;
            elseif (self.Original[TaggedPart]) then
                TaggedPart.CFrame = self.Original[TaggedPart];
                self.Original[TaggedPart] = nil;
            end
        end
    end
end

local noise = math.noise;
function Wind:GetNoise(now, Variation)
    return noise(
        (now * self.WindSpeed)*.2,
        Variation * 10
    ) * self.WindStrength;
end

function Wind:Start()
    local LastCameraPosition = Vector3.new(1e7, 1e7, 1e7);
    local LastUpdated = -math.huge;

    self.AllParts = CollectionService:GetTagged(Tag);

    CollectionService:GetInstanceAddedSignal(Tag):Connect(function(Instance)
        self.AllParts[#self.AllParts+1] = Instance;
    end)
    CollectionService:GetInstanceRemovedSignal(Tag):Connect(function(Instance) self.Original[Instance] = nil; end);

    if (not game:IsLoaded()) then game.Loaded:Wait(); end;

    local CameraPosition = Camera.CFrame.Position;
    self:UpdateStream(CameraPosition);

    self.Noises = {};

    local Angles = CFrame.Angles;

	RunService.Heartbeat:Connect(function(DeltaTime)
        debug.profilebegin("Wind:UpdateStream");

        CameraPosition = Camera.CFrame.Position;

        if ((LastCameraPosition - CameraPosition).Magnitude >= self.UpdateStreamDistance and (time() - LastUpdated) > .8) then
            self:UpdateStream(CameraPosition);
            LastCameraPosition = CameraPosition;
            LastUpdated = time();
        end

        local now = time();

        for i = 1, self.NoiseLayers do
            self.Noises[i] = self:GetNoise(now, i);
        end
    
        for index, Part in ipairs(self.Streaming) do
            local WindNoise = self.Noises[(index % self.NoiseLayers) + 1];
            local WindNoise2 = self.Noises[((index - 1) % self.NoiseLayers) + 1];

            if (not self.Original[Part]) then
                self.Original[Part] = Part.CFrame;
            end

            Part.CFrame = (self.Original[Part] * Angles(WindNoise2, WindNoise, -WindNoise * .4) * self.WindDirection);
        end

        debug.profileend();
    end)
end

return Wind