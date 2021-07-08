-- Interactive Beams
-- Deter
-- July 5, 2021

local Camera = workspace.CurrentCamera or workspace:WaitForChild("Camera");

local RunService = game:GetService("RunService");
local CollectionService = game:GetService("CollectionService");

local ObjectTag = "InteractiveBeam";

local InteractiveBeams = {
    Streaming = {},
    StreamingRadius = 64
};

function InteractiveBeams:UpdateStream()
    local AllObjects = CollectionService:GetTagged(ObjectTag);
    local Position = Camera.CFrame.Position;

    self.RaycastParams.FilterDescendantsInstances = {
        table.unpack(CollectionService:GetTagged("NotCollidable")),
        table.unpack(CollectionService:GetTagged("InteractiveBeamIgnore"))
    };

    table.clear(self.Streaming);

    for _, Object:Beam in ipairs(AllObjects) do
        if ((Object.Attachment0.WorldPosition - Position).Magnitude <= self.StreamingRadius) then
            self.Streaming[#self.Streaming+1] = Object;
        end
    end
end

function InteractiveBeams:Update()
    for _, Beam:Beam in ipairs(self.Streaming) do
        local Delta = Beam.Attachment1.WorldPosition - Beam.Attachment0.WorldPosition;

        local Direction = Delta.Unit;
        local Distance = Delta.Magnitude;

        local Raycast = workspace:Raycast(
            Beam.Attachment0.WorldPosition, Direction * Distance, self.RaycastParams
        );

        if (Raycast) then
            local PercentDistance = (Beam.Attachment0.WorldPosition - Raycast.Position).Magnitude / Distance;

            Beam.Segments = 10;

            Beam.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, .75),
                NumberSequenceKeypoint.new(PercentDistance, 1),
                NumberSequenceKeypoint.new(1, 1)
            });
        else
            Beam.Segments = 1;

            Beam.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, .75),
                NumberSequenceKeypoint.new(1, 1)
            });
        end
    end
end

function InteractiveBeams:Start()
    self.StreamingUpdateIntervals = 3;
    self.UpdateIntervals = .3;

    local LastStream, LastUpdate = 0, 0;

    self.RaycastParams = RaycastParams.new();
    self.RaycastParams.IgnoreWater = true;
    self.RaycastParams.FilterType = Enum.RaycastFilterType.Blacklist;
    self.RaycastParams.FilterDescendantsInstances = {
        table.unpack(CollectionService:GetTagged("NotCollidable")),
        table.unpack(CollectionService:GetTagged("InteractiveBeamIgnore"))
    };

	RunService.RenderStepped:Connect(function(DeltaTime:number)
        if ((time() - LastStream) >= self.StreamingUpdateIntervals) then
            self:UpdateStream();
            LastStream = time();
        end

        if (not self.UpdateIntervals or (time() - LastUpdate) >= self.UpdateIntervals) then
            self:Update();
            LastUpdate = time();
        end
    end)
end

return InteractiveBeams;