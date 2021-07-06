-- Grass Patches
-- Deter
-- June 19, 2021


local Player = game:GetService("Players").LocalPlayer;

local RunService = game:GetService("RunService");
local CollectionService = game:GetService("CollectionService");

local GrassPatch = {};
GrassPatch.__index = GrassPatch;

function GrassPatch:UpdateStatus()
    local Character = Player.Character;
    if (not Character) then return; end;

    local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart");
    local ModelCFrame, ModelSize = self.Container:GetBoundingBox();

    local InRange = (HumanoidRootPart.Position - ModelCFrame.Position).Magnitude <= ModelSize.Magnitude;
    self.ModelSize = ModelSize;

    self.HumanoidRootPartPosition = HumanoidRootPart.Position;

    if (InRange ~= self.InRange) then
        self.InRange = InRange;
    end
end

function GrassPatch:Update()
    local AllGrass = self.Container:GetChildren();
    self.Original = {};

    for index, Grass in ipairs(AllGrass) do
        if (self.HumanoidRootPartPosition and ((Grass.Position - self.HumanoidRootPartPosition).Magnitude < 10)) then
            local Diff = (Grass.Position - self.HumanoidRootPartPosition);
            local Dist = 1-(Diff.Magnitude/10);

            
            if (not self.Original[index]) then
                self.Original[index] = Grass.CFrame;
            end

            local OriginalCFrame = self.Original[index];

            local Direction = Diff.Unit * Dist;

            Grass.CFrame = OriginalCFrame:Lerp(CFrame.lookAt(OriginalCFrame.Position, self.HumanoidRootPartPosition), Dist);
        end
    end
end

function GrassPatch.new(Model:Model)
    return setmetatable({Container = Model}, GrassPatch);
end


local GrassPatches = {}


function GrassPatches:Start()
	if (not game:IsLoaded()) then
        game.Loaded:Wait();
    end

    -- local GrassPatchModels = CollectionService:GetTagged("GrassPatch");
    -- self.GrassPatches = {};

    -- for _, GrassPathModel in ipairs(GrassPatchModels) do
    --     local NewGrassPatch = GrassPatch.new(GrassPathModel);

    --     table.insert(self.GrassPatches, NewGrassPatch);
    -- end

    -- RunService.Heartbeat:Connect(function()
    --     for _, CurrentGrassPatch in ipairs(self.GrassPatches) do
    --         CurrentGrassPatch:UpdateStatus();

    --         if (CurrentGrassPatch.InRange) then
    --             CurrentGrassPatch:Update();
    --         end
    --     end
    -- end)
end


function GrassPatches:Init()
	self.Chunks = self.Modules.Chunk;
end


return GrassPatches