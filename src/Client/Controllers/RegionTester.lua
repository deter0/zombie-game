-- Region Tester
-- Deter
-- June 30, 2021


local ReplicatedStorage = game:GetService("ReplicatedStorage");
local Shared = ReplicatedStorage:WaitForChild("Aero"):WaitForChild("Shared");

local Maid = require(Shared:WaitForChild("Maid"));

local Player = game:GetService("Players").LocalPlayer;
local Mouse = Player:GetMouse();

local ContextActionService = game:GetService("ContextActionService");
local RunService = game:GetService("RunService");

local RegionTester = {
    Height = 0,
    Maid = Maid.new()
};


function RegionTester:Start()
	-- self:Inputs();
    -- self:Dragging();
end

function RegionTester:Init()
    self.RegionController = self.Services.RegionController;
end

function RegionTester:Dragging()
    self.VertexAdornment = ReplicatedStorage:WaitForChild("Adornments"):WaitForChild("Vertex");
    self.VertexNormalAdornment = ReplicatedStorage:WaitForChild("Adornments"):WaitForChild("VertexNormal");

    local Ignore = Instance.new("Folder");
    Ignore.Name = "Ignore";
    Ignore.Parent = workspace;

    self.VertexDisplay = Instance.new("Part");
    self.VertexDisplay.Size = Vector3.new();
    self.VertexDisplay.Transparency = 1;
    self.VertexDisplay.CanCollide = false;
    self.VertexDisplay.Anchored = true;
    self.VertexDisplay.Position = Vector3.new(5000, -5000, 5000);
    self.VertexDisplay.Name = "VertexDisplay";

    self.VertexDisplay.Parent = Ignore;

    self.RaycastParams = RaycastParams.new();
    self.RaycastParams.FilterDescendantsInstances = {Player.Character or Player.CharacterAdded:Wait(), Ignore, self.VertexDisplay};
    self.RaycastParams.IgnoreWater = true;
    self.RaycastParams.FilterType = Enum.RaycastFilterType.Blacklist;

    self.Maid.Dragging = RunService.RenderStepped:Connect(function()
        if (self.IsDragging or self.InitPosition) then
            local MousePosition = Mouse.Hit.Position;
            local Camera = workspace.CurrentCamera.CFrame.Position;

            local Sub = (Camera - MousePosition);
            
            local Direction = Sub.Unit;
            local Distance = math.clamp(Sub.Magnitude, 0, 100) * 1.05;

            local Raycast = workspace:Raycast(
                Camera, Direction * Distance, self.RaycastParams
            );

            self.VertexAdornment.Adornee = self.VertexDisplay;
            self.VertexAdornment.Parent = self.VertexDisplay;

            local Position = Vector3.new();

            if (Raycast) then
                Position = Raycast.Position + Vector3.new(0, self.Height, 0);
            else
                Position = MousePosition;
            end
            local setInit = false;
            if (not self.InitPosition) then setInit = true; self.InitPosition = Position; end;

            if (self.AdjustingNormal and not setInit) then
                self.VertexNormalAdornment.Parent = self.VertexDisplay;
                self.VertexNormalAdornment.Adornee = self.VertexDisplay;
                self.VertexDisplay.CFrame = CFrame.lookAt(self.VertexDisplay.Position, Position);
            else
                self.VertexNormalAdornment.Adornee = nil;
                self.VertexDisplay.Position = self.InitPosition;
            end

            self.LastPosition = self.VertexDisplay.Position;
        else
            self.VertexDisplay.Position = Vector3.new(5000, -5000, 5000) + Vector3.new(0, self.Height, 0);
        end
    end)
end

function RegionTester:Inputs()
    self.Maid.WheelForwards = Mouse.WheelForward:Connect(function()
        self.Height += 2.5;
    end)
    self.Maid.WheelBackwards = Mouse.WheelBackward:Connect(function()
        self.Height -= 2.5;
    end)

    ContextActionService:BindAction("AddRegionVertex", function(_, State, Input)
        if (Input.UserInputType == Enum.UserInputType.MouseButton2) then
            self.AdjustingNormal = State == Enum.UserInputState.Begin;
            self.IsDragging = true;
        else
            self.AdjustingNormal = false;
            self.InitPosition = nil;
        end
        
        if (not (State == Enum.UserInputState.Begin)) then
            self.RegionController:AddVertexToRegion(self.VertexDisplay.Position, self.VertexDisplay.CFrame.LookVector);
        end

        self.IsDragging = (State == Enum.UserInputState.Begin);
    end, false, Enum.UserInputType.MouseButton1, Enum.UserInputType.MouseButton2);
end

return RegionTester