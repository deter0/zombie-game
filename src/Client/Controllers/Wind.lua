-- Wind
-- Deter
-- July 1, 2021

local RunService = game:GetService("RunService");
local CollectionService = game:GetService("CollectionService");
local Camera = workspace.CurrentCamera or workspace:WaitForChild("Camera");
local Tag = "WindShake";

local Wind = {
    Range = 250,
    Noises = {},
    Original = {},
    WindSpeed = 2,
    WindStrength = .3,
    UpdateStreamDistance = 250/2,
    WindDirection = CFrame.Angles(0, math.rad(24), 0),
    Streaming = {},
    NoiseLayers = 6
};

function Wind:UpdateStream(CameraPosition)
    self.Streaming = {};

    for index, TaggedPart:BasePart|Bone in ipairs(self.AllParts) do
        if (index % 300 == 0) then RunService.Heartbeat:Wait(); end;

        if (TaggedPart:IsA("BasePart")) then
            local Distance = (CameraPosition - (TaggedPart.Position)).Magnitude;

            if (Distance <= self.Range) then
                self.Streaming[#self.Streaming+1] = TaggedPart;
            elseif (self.Original[TaggedPart]) then
                TaggedPart.CFrame = self.Original[TaggedPart];
                self.Original[TaggedPart] = nil;
            end
        end
    end
end

function Wind:GetNoise(now, Variation)
    return math.noise(
        (now * self.WindSpeed)*.2,
        Variation * 10
    ) * self.WindStrength;
end

function Wind:Start()
    local LastCameraPosition = Vector3.new(1e7, 1e7, 1e7);
    local LastUpdated = 0;

    self.AllParts = CollectionService:GetTagged(Tag);

    CollectionService:GetInstanceAddedSignal(Tag):Connect(function(Instance)
        self.AllParts[#self.AllParts+1] = Instance;
    end)
    CollectionService:GetInstanceRemovedSignal(Tag):Connect(function(Instance) self.Original[Instance] = nil; end);

    if (not game:IsLoaded()) then game.Loaded:Wait(); end;

    local CameraPosition = Camera.CFrame.Position;
    self:UpdateStream(CameraPosition);

	RunService.Heartbeat:Connect(function(DeltaTime)
        CameraPosition = Camera.CFrame.Position;

        if ((LastCameraPosition - CameraPosition).Magnitude >= self.UpdateStreamDistance and (os.clock() - LastUpdated) > .8) then
            self:UpdateStream(CameraPosition);
            LastCameraPosition = CameraPosition;
            LastUpdated = os.clock();
        end

        local now = time();

        if (not self.Noises) then self.Noises = {}; end;

        table.clear(self.Noises);
        for i = 1, self.NoiseLayers do
            self.Noises[i] = self:GetNoise(now, i);
        end

        for index, Part:BasePart|Bone in ipairs(self.Streaming) do
            local WindNoise = self.Noises[(index % self.NoiseLayers) + 1];

            if (not self.Original[Part]) then
                self.Original[Part] = Part.CFrame;
            end

            Part.CFrame = Part.CFrame:Lerp(self.Original[Part] * CFrame.Angles(WindNoise * .8, WindNoise, -WindNoise * .4) * self.WindDirection, DeltaTime * 5);
        end
    end)
end

return Wind