-- Wind
-- Deter
-- July 1, 2021

local RunService = game:GetService("RunService");
local CollectionService = game:GetService("CollectionService");
local Camera = workspace.CurrentCamera or workspace:WaitForChild("Camera");
local Tag = "WindShake";

local Wind = {
    Range = 250,
    Original = {},
    WindSpeed = 2,
    WindStrength = 6,
    UpdateStreamDistance = 250/2,
    WindDirection = CFrame.Angles(0, math.rad(24), 0),
    Streaming = setmetatable({}, {__mode = "kv"});
};

function Wind:UpdateStream(CameraPosition)
    if (true) then return; end;

    self.Streaming = {};

    for index, TaggedPart:BasePart|Bone in ipairs(self.AllParts) do
        if (index % 300 == 0) then RunService.Heartbeat:Wait(); end;

        local IsBone = TaggedPart:IsA("Bone");

        if (TaggedPart:IsA("BasePart") or IsBone) then
            if ((CameraPosition - (not IsBone and TaggedPart.Position or TaggedPart.WorldPosition)).Magnitude <= self.Range) then
                self.Streaming[#self.Streaming+1] = TaggedPart;
            elseif (self.Original[TaggedPart]) then
                if (not IsBone) then
                    TaggedPart.CFrame = self.Original[TaggedPart];
                else
                    TaggedPart.WorldPosition = self.Original[TaggedPart];
                end
                self.Original[TaggedPart] = nil;
            end
        end
    end
end

local function Angles(x:number, y:number?, z:number?)
    x = math.rad(x);
    return CFrame.Angles(x, math.rad(y) or x, math.rad(z) or x);
end

function Wind:getNoise(now, Variation)
    return math.noise(
        (now * self.WindSpeed)*.2,
        Variation * 10
    ) * self.WindStrength;
end

function Wind:Start()
    if (true) then return; end;

    local LastCameraPosition = Vector3.new(1e7, 1e7, 1e7);
    local LastUpdated = 0;

    self.AllParts = CollectionService:GetTagged(Tag);

    CollectionService:GetInstanceAddedSignal(Tag):Connect(function(Instance) self.AllParts[#self.AllParts+1] = Instance; end)
    CollectionService:GetInstanceRemovedSignal(Tag):Connect(function(Instance) self.Original[Instance] = nil; end);

    if (not game:IsLoaded()) then game.Loaded:Wait(); end;

    local CameraPosition = Camera.CFrame.Position;
    self:UpdateStream(CameraPosition);

	RunService.Heartbeat:Connect(function()
        CameraPosition = Camera.CFrame.Position;

        if ((LastCameraPosition - CameraPosition).Magnitude >= self.UpdateStreamDistance and (os.clock() - LastUpdated) > .8) then
            self:UpdateStream(CameraPosition);
            LastCameraPosition = CameraPosition;
            LastUpdated = os.clock();
        end

        local now = time();

        local noises = {};
        for i = 1, 6 do
            noises[i] = self:getNoise(now, i);
        end

        for index, Part:BasePart|Bone in ipairs(self.Streaming) do
            local IsBone = Part:IsA("Bone");

            local WindNoise = noises[(index % #noises) + 1];

            if (not self.Original[Part]) then
                self.Original[Part] = not IsBone and Part.CFrame or Part.WorldPosition;
            end

            if (not IsBone) then
                Part.CFrame = Part.CFrame:Lerp(self.Original[Part] * CFrame.Angles(WindNoise * .8, WindNoise, -WindNoise * .4) * self.WindDirection, .1);
            else
                Part.WorldPosition = self.Original[Part] + Vector3.new(WindNoise, 0, -WindNoise * .4);
            end
        end

        -- warn("Updated", #self.Streaming);
    end)
end

return Wind