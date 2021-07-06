local WeaponHandler = {};
WeaponHandler.__index = WeaponHandler;

local LoadedAnimations = {};

local ReplicatedStorage = game:GetService("ReplicatedStorage");
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService");
local ContextActionService = game:GetService("ContextActionService");

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Aero"):WaitForChild("Shared");

local Maid = require(Shared:WaitForChild("Maid"));
local AudioEmitter = require(Shared:WaitForChild("AudioEmitter"));
local FootstepSounds = require(Shared:WaitForChild("FootstepSounds"));
local Spring = require(Shared:WaitForChild("Spring"));
local AudioModule = require(Shared:WaitForChild("AudioModule"));
local Thread = require(Shared:WaitForChild("Thread"));

delay = Thread.Delay;

local Player = game:GetService("Players").LocalPlayer;

local function GetBobbing(addition,modifier,speed)
	return math.sin(time()*addition*(speed or 0))*modifier
end

local function lerpNumber(a:number, b:number, t:number):number
	return a + (b - a) * t;
end

local function PlayTweenOnce(Object, Properties, TweenInformation)
    local Tween = TweenService:Create(Object, TweenInformation, Properties);

    Tween:Play();
    Tween.Completed:Connect(function()
        Tween:Destroy();
    end)

    return Tween;
end

function WeaponHandler.new(ServerManager)
    local self = setmetatable({
        Spread = 0,
        ServerManager = ServerManager,
        LoadedAnimations = {},
        MagInserted = {},
        BoltPulled = {},
        ReloadTimePosition = {},
        SeverAnimations = {},
        Ammo = {},
        KeyPressStates = {},

        Springs = {
            Spread = Spring.create(),
            Recoil = Spring.create(),
            Sway = Spring.create(nil, 4, 50, 6, 6),
            WalkCycle = Spring.create(),
            Camera = Spring.create()
        }, 

        Maid = Maid.new()
    }, WeaponHandler);

    return self;
end

function WeaponHandler:Remove()
    self.Viewmodel.Parent = ReplicatedStorage.Cache;
end

function WeaponHandler:Destroy()
    if (self.Viewmodel) then
        self.Viewmodel.Parent = ReplicatedStorage.Cache;
    end
    self.Maid:Destroy();
    for _, v in pairs(self) do
        if (type(v) == "table") then
            if (v.Destroy) then
                v:Destroy();
            end
            table.clear(v);
        end
    end
    table.clear(self);
    self:UnbindActions();
    setmetatable(self, {__mode="kv"});
    self.Destroyed = true;
end

function WeaponHandler:SetCrosshairSpread(x)
    local Bounds = self.Crosshair:WaitForChild("CrosshairUI"):WaitForChild("Bounds");

    Bounds.Size = Bounds.Size:Lerp(UDim2.fromOffset(x, x), .1);
end

function WeaponHandler:Equip(WeaponName:string)
    if (self.Weapon) then self.Weapon:Destroy(); end;
    if (self.Crosshair) then self.Crosshair:Destroy(); end;

    if (self.OnGetEvent) then self.OnGetEvent:Disconnect(); end;
    if (self.CharacterAdded) then self.CharacterAdded:Disconnect(); end;

    if (self.Disabled) then return; end;
    if (self.Equipped) then self:Remove(); end;

    self.ServerManager = self.Services.ServerWeaponManager;

    if (ReplicatedStorage:WaitForChild("Cache"):FindFirstChild("Viewmodel")) then
        print("Viewmodel was cached");
        self.Viewmodel = ReplicatedStorage:WaitForChild("Cache"):FindFirstChild("Viewmodel");
    else
        print("Viewmodel wasn't cached.");
        table.clear(LoadedAnimations);
        LoadedAnimations = {};
        self.Viewmodel = ReplicatedStorage:WaitForChild("Viewmodel"):Clone();
    end

    if (self.LoadedAnimations) then
        for _, AnimationTrack:AnimationTrack in pairs(self.LoadedAnimations) do
            AnimationTrack:Destroy();
        end

        table.clear(self.LoadedAnimations);

        self.LoadedAnimations = {};
    end

    local Weapon = ReplicatedStorage:WaitForChild("Weapons"):FindFirstChild(WeaponName);
    if (not Weapon) then return; end;

    self.AutomaticFiring = false;

    self.Weapon = Weapon:Clone();
    self.WeaponConfig = require(Weapon:WaitForChild("Config"));

    self.Mouse = game:GetService("Players").LocalPlayer:GetMouse();

    self.Crosshair = ReplicatedStorage:WaitForChild("Crosshair"):Clone();

    self.Maid.Crosshair = self.Crosshair;
    self.Maid.Weapon = self.Weapon;

    self.Viewmodel:WaitForChild("AnimationController");

    for _, v in pairs(self.Viewmodel:GetChildren()) do
		if v:IsA("BasePart") then
			v.CanCollide = false;
			v.CastShadow = false;
		end
	end

    self.Camera = workspace.CurrentCamera or workspace:WaitForChild("Camera");
    self.Character = Player.Character or Player.CharacterAdded:Wait();

    self.RaycastParams = self.RaycastParams or RaycastParams.new();
    self.RaycastParams.FilterDescendantsInstances = {self.Camera, self.Character};

    self.Viewmodel:WaitForChild("RootPart"):WaitForChild("Weapon");

    self.Viewmodel.RootPart.CFrame = CFrame.new(5000, -1000, 5000);

    self.Viewmodel.RootPart.Weapon.Part1 = self.Viewmodel.RootPart;
    -- self.Viewmodel.LeftArm.LeftHand.Part0 = self.Viewmodel.RootPart;
    -- self.Viewmodel.RightArm.RightHand.Part0 = self.Viewmodel.RootPart;

    self.Viewmodel.RootPart.Weapon.Part1 = self.Weapon:WaitForChild("Handle");
    
    self.Viewmodel.Parent = self.Camera;
    self.Weapon.Parent = self.Viewmodel;
    self.Crosshair.Parent = self.Viewmodel;
    
    self.Maid.OnGetEvent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Get/Post__").OnClientEvent:Connect(function()
        ReplicatedStorage:WaitForChild("Events"):WaitForChild("Get/Post__"):FireServer(self.Weapon.Handle.Muzzle.WorldPosition, self.Camera.CFrame.LookVector);
    end)

    for _, v in ipairs(self.Viewmodel.AnimationController:GetPlayingAnimationTracks()) do
        v:Stop();
    end

    for _, v in ipairs(self.LoadedAnimations or {}) do
        v:Stop();
    end

    self.LoadedAnimations = {};

    for _, Animation:Animation in ipairs(self.Weapon:WaitForChild("Animations"):GetChildren()) do
        if (LoadedAnimations[Animation.AnimationId]) then
            print("Cached animation");
            self.LoadedAnimations[Animation.Name] = LoadedAnimations[Animation.AnimationId];
        else
            print("Loaded animation");
            local LoadedAnimation = self.Viewmodel.AnimationController:LoadAnimation(Animation);
            self.LoadedAnimations[Animation.Name] = LoadedAnimation;
            LoadedAnimations[Animation.AnimationId] = LoadedAnimation;
        end
    end
    warn(self.LoadedAnimations);

    self.Equipped = self.Weapon.Name;
    self.LoadedAnimations.Idle:Play(0);
    self.LoadedAnimations.Idle.Looped = true;

    self.Fired = nil;
    self.Firing = false;

    if (self.WeaponConfig.FireMode == 1) then
        self.AutomaticFiring = true;
    end

    UserInputService.MouseIconEnabled = self.MouseFree;

    self:UnbindActions();
    self:BindActions();

    PlayTweenOnce(
        self.Weapon:WaitForChild("Offsets"):WaitForChild("ViewmodelOffset"):WaitForChild("Equip"),
        {Value = Vector3.new()},
        TweenInfo.new(.6, Enum.EasingStyle.Circular, Enum.EasingDirection.Out)
    );
    
    local CollectionService = game:GetService("CollectionService");
    self.Maid.CharacterAdded = Player.CharacterAdded:Connect(function(Character)
        if (self.Running) then self.Running:Disconnect(); end;
        self.Humanoid = Character:WaitForChild("Humanoid");

        if (not self.RaycastParams) then
            self.RaycastParams = RaycastParams.new();
        end

        self.RaycastParams.FilterDescendantsInstances = {Character, self.Camera}; --?

        self.CloseToWallParams = RaycastParams.new();
        self.CloseToWallParams.FilterDescendantsInstances = {Character, self.Camera, CollectionService:GetTagged("NotCollidable")};
        self.CloseToWallParams.IgnoreWater = true;

        self.Maid.Running = self.Humanoid.Running:Connect(function(Speed)
            self.Speed = Speed/16;
            self.HumanoidSpeed = Speed;
        end)
    end)

    self.Humanoid = self.Character:WaitForChild("Humanoid");

    self.CloseToWallParams = self.CloseToWallParams or RaycastParams.new();
    self.CloseToWallParams.FilterDescendantsInstances = {self.Character, self.Camera, CollectionService:GetTagged("NotCollidable")};
    self.CloseToWallParams.IgnoreWater = true;

    if (self.Running) then self.Running:Disconnect(); end;
    self.Maid.Running = self.Humanoid.Running:Connect(function(Speed)
        self.Speed = Speed/16;
        self.HumanoidSpeed = Speed;
    end)

    return true;
end

function WeaponHandler:BindActions()
    ContextActionService:BindAction(
        "Aim",
        function(_, State)
            self:Aim(State ~= Enum.UserInputState.End);
            self.Services.ServerWeaponManager:Aiming(State ~= Enum.UserInputState.End);
        end,
        false,
        Enum.UserInputType.MouseButton2
    )

    ContextActionService:BindAction("Fire", function(_, State)
        if (State == Enum.UserInputState.Begin) then
            if (not self.ServerManager) then self.ServerManager = self.Services.ServerWeaponManager; end;

            -- if (self.AutomaticFiring) then
            --     self.ServerManager:SetAutomaticFiring(true);
            -- end

            self.Firing = true;

            if (self.LoadedAnimations.Firing) then
                self.LoadedAnimations.Firing:Play(.3);
            end

            self.WeaponConfig = self.WeaponConfig or require(self.Weapon:WaitForChild("Config"));

            if (self.WeaponConfig.FireMode == 0) then
                if (not self.Fired or (time() - self.Fired) >= (60/self.WeaponConfig.FireRate)) then
                    self.FireSpreadInfluence = 1;
                    self:Fire();
                    delay(.1, function()
                        self.FireSpreadInfluence = 0;
                    end)
                    
                    if (self.WeaponConfig.Pumping) then
                        self:Pump();
                    end

                    self.Fired = time();
                end
            end
        elseif (State == Enum.UserInputState.End) then
            -- if (self.AutomaticFiring) then
            --     self.ServerManager:SetAutomaticFiring(false);
            -- end

             if (self.LoadedAnimations.Firing) then
                self.LoadedAnimations.Firing:Stop(.3);
            end

            self.Firing = false;
        end
    end, false, Enum.UserInputType.MouseButton1);

    ContextActionService:BindAction("Sprinting", function(_, State)
        if (State == Enum.UserInputState.Begin) then
            if (self.LoadedAnimations.Running) then
                self.LoadedAnimations.Running:Play(.1);
            end
            self.Humanoid.WalkSpeed = 20;

            self:Aim(false);

            self.Running = true;
        else
            if (self.LoadedAnimations.Running) then
                self.LoadedAnimations.Running:Stop(.3);
            end
            self.Humanoid.WalkSpeed = 16;

            self.Running = false;
        end
    end, false, Enum.KeyCode.LeftShift);
end

function WeaponHandler:UnbindActions()
    ContextActionService:UnbindAction("Fire");
    ContextActionService:UnbindAction("Aim");
    ContextActionService:UnbindAction("Sprinting");
end

function WeaponHandler:FreeMouse(Origin:string, Status:bool)
    self.MouseLockers = self.MouseLockers or setmetatable({}, {__mode="kv"});

    self.MouseLockers[Origin] = Status;

    self.MouseFree = false;
    for _, v in pairs(self.MouseLockers) do
        self.MouseFree = v;
        if (v) then
            break;
        end;
    end
end

local EmptyCFrame = CFrame.new(0, 0, 0);

function WeaponHandler:Update(DeltaTime)
    if (not self.WeaponConfig) then
        self.WeaponConfig = require(self.Weapon:WaitForChild("Config"));
        return;
    end

    if (not self.Character or not self.Character.PrimaryPart) then
        self.Character = Player.Character;
        return;
    end

    if (self.AutomaticFiring and self.Firing and (not self.Fired or ((time() - self.Fired) >= (60/self.WeaponConfig.FireRate)))) then
        self.FireSpreadInfluence = 1;
        self:Fire();
        self.Fired = time();
        self.ServerManager:Fire(self.Weapon.Handle.Muzzle.WorldPosition, self.Camera.CFrame.LookVector);

        if (self.WeaponConfig.Pumping) then
            self:Pump();
        end
    else
        self.FireSpreadInfluence = 0;
    end

    -- UserInputService.MouseBehavior = self.MouseFree and Enum.MouseBehavior.Default or Enum.MouseBehavior.LockCenter;
    UserInputService.MouseIconEnabled = self.MouseFree;

    if (self.Aiming) then
        self.Camera.FieldOfView = lerpNumber(self.Camera.FieldOfView, 40, DeltaTime * 6);
    else
        self.Camera.FieldOfView = lerpNumber(self.Camera.FieldOfView, 65, DeltaTime * 6);
    end

    local TargetAim = self.Aiming and self.Weapon.Offsets.Aim.Value or Vector3.new();

    self.Weapon.Offsets.ViewmodelOffset.Aiming.Value = 
        self.Weapon.Offsets.ViewmodelOffset.Aiming.Value:Lerp(
            TargetAim,
            DeltaTime * 6
        )

    local MasterOffset = CFrame.new();

    for _, Offset in ipairs(self.Weapon.Offsets.ViewmodelOffset:GetChildren()) do
        if (typeof(Offset.Value) == "Vector3") then
            MasterOffset += Offset.Value;
        else
            MasterOffset *= Offset.Value;
        end
    end

    self.RunningCFrame = self.RunningCFrame or CFrame.new();

    local RunningCFrame = EmptyCFrame:Lerp(self.Running and (self.Weapon.Offsets:FindFirstChild("Running") and self.Weapon.Offsets.Running.Value or CFrame.new(.4, 0, -.3) * CFrame.Angles(0, math.rad(45), 0)) or EmptyCFrame, self.Speed or 0);
    self.RunningCFrame = self.RunningCFrame:Lerp(RunningCFrame, .1);

    MasterOffset *= self.RunningCFrame;


    self.JumpingVelocity = self.JumpingVelocity or CFrame.new();

    local JumpingVelocity = CFrame.Angles(-math.rad(self.Character.PrimaryPart.Velocity.Y), 0, 0);
    self.JumpingVelocity = self.JumpingVelocity:Lerp(JumpingVelocity, .1);

    MasterOffset *= self.JumpingVelocity;

    if (not self.WeaponConfig.DisableProximtyPushBack) then
        local _, ModelSize = self.Viewmodel:GetBoundingBox();
        local BackPoint = self.Camera.CFrame;

        local Raycast = workspace:Raycast(BackPoint.Position, self.Camera.CFrame.LookVector * ModelSize.X, self.CloseToWallParams);

        local Distance = 0;
        if (Raycast) then
            Distance = ModelSize.X - (BackPoint.Position - Raycast.Position).Magnitude;
        end
        self.CloseToWallCFrame = not self.CloseToWallCFrame and CFrame.Angles(0, 0, 0) or
            self.CloseToWallCFrame:Lerp(CFrame.new(0, 0, Distance), .15);

            MasterOffset *= self.CloseToWallCFrame;
    end

    local CharacterVelocity = self.Character.HumanoidRootPart.Velocity;

    local MouseDelta = UserInputService:GetMouseDelta();
	self.Springs.Sway:shove(Vector3.new(MouseDelta.X / 200, MouseDelta.Y / 200));

    if (self.Running and self.LoadedAnimations.Running) then
        self.LoadedAnimations.Running:AdjustWeight(self.Speed, .2);
    end

    local AimingInfluence = self.Aiming and (self.WeaponConfig.AimingInfluence or .1) or 1; --> Alternative to lower wobble when aiming
    local GunSwayInfluence = self.WeaponConfig.GunSwayInfluence or .7;

    local MovementSway = Vector3.new(
        (GetBobbing(4, 30, self.Speed)) * DeltaTime,
        ((GetBobbing(8, 15, self.Speed) * -1)) * DeltaTime,
        0
    ) * GunSwayInfluence * AimingInfluence;

    -- self.Springs.WalkCycle:shove(((MovementSway / 25) * DeltaTime * 60 * CharacterVelocity.Magnitude) * AimingInfluence);

    self.CameraBobbingCFrame = self.CameraBobbingCFrame or EmptyCFrame;
    self.CameraBobbingCFrame = self.CameraBobbingCFrame:Lerp(CFrame.Angles(0, 0, math.rad(GetBobbing(6+(self.Running and 1.3 or 0), .7, self.Speed)) * (self.Running and 2 or 1)), DeltaTime * 5);

    local CameraOffset = self.Springs.Camera:update(DeltaTime);
    CameraOffset = CFrame.Angles(
        math.rad(CameraOffset.X),
        math.rad(CameraOffset.Y),
        math.rad(CameraOffset.Z)
    ) * self.CameraBobbingCFrame;

    self.CameraOffset = self.CameraOffset or EmptyCFrame;

    self.Camera.CFrame *= EmptyCFrame:Lerp(self.CameraOffset, self.WeaponConfig.CameraRecoilRecovery or .5) * CameraOffset; --?
    
    self.CameraOffset = CameraOffset;

    local ShoveOffset = self.Springs.Sway:update(DeltaTime);
    local RecoilOffset = self.Springs.Recoil:update(DeltaTime);

    self.Sway = self.Sway and self.Sway:Lerp(
        CFrame.new(MovementSway), DeltaTime * 5
    ) or CFrame.new();

    self.CrosshairDirection = not self.CrosshairDirection and self.Camera.CFrame.LookVector or self.CrosshairDirection:Lerp(self.Camera.CFrame.LookVector, DeltaTime * 18);
    self.Crosshair.CFrame = CFrame.lookAt(self.Camera.CFrame.Position + (self.CrosshairDirection * 5), self.Camera.CFrame.Position);

    self.Viewmodel.RootPart.CFrame = self.Camera.CFrame:ToWorldSpace(CFrame.new(RecoilOffset) * CFrame.new(ShoveOffset));
	self.Viewmodel.RootPart.CFrame *= CFrame.Angles(0,-ShoveOffset.X, ShoveOffset.Y);

    self.Viewmodel.RootPart.CFrame *= MasterOffset * self.Sway;

    self:Footsteps();

    self.Springs.Spread:shove(Vector3.new(50+((self.HumanoidSpeed or 0) * 8), 0, 0));

    if (not self.Aiming) then
        local Spread = self.Springs.Spread:update(DeltaTime).X;
        self:SetCrosshairSpread(Spread);
    else
        self:SetCrosshairSpread(0);
    end
end

function WeaponHandler:Aim(State)
    -- if (not self.WeaponConfig.DisableAim) then
        self.Aiming = State;
    -- else
    --     self.Aiming = false;
    -- end
end

function WeaponHandler:FireSound()
    self.AudioEmitter = self.AudioEmitter or AudioEmitter.new(self.Weapon.Handle);
    self.AudioEmitter.originPart = self.Weapon.Handle;

    self.AudioEmitter:Play(self.Weapon.Sounds.Fire.SoundId, {
        volume = 1,
        distance = 500,
        disableReverb = false
    }, true);
end

function WeaponHandler:PlaySound(SoundName:string)
    local Sound:Sound = self.Weapon:WaitForChild("Sounds"):FindFirstChild(SoundName);
    if (not Sound) then return; end;

    Sound = Sound:Clone();

    Sound.Parent = self.Weapon.Sounds;
    Sound:Play();

    local Stopped; Stopped = Sound.Stopped:Connect(function()
        Stopped:Disconnect();
        Sound:Destroy();
    end)

    return Sound;
end

function WeaponHandler:Pump()
    delay(.4, function()
        self:PlaySound("Pump");
        
        if (self.LoadedAnimations["Pump"]) then
            self.LoadedAnimations.Pump:Play();
        end
    end)
end

function WeaponHandler:Fire()
    if (self.Running) then return; end;

    if (not self.AutomaticFiring) then
        self.ServerManager:Fire(
            self.Weapon:WaitForChild("Handle"):WaitForChild("Muzzle").WorldPosition,
            self.Camera.CFrame.LookVector
        );
    end

    self.FireIteration = not self.FireIteration and 1 or self.FireIteration + 1;

    for _, ParticleEmitter:ParticleEmitter|Light in ipairs(self.Weapon.Handle:WaitForChild("Muzzle"):GetChildren()) do
        if (ParticleEmitter:IsA("ParticleEmitter")) then
            ParticleEmitter:Emit(ParticleEmitter:GetAttribute("Emit"));
        elseif (ParticleEmitter:IsA("Light")) then
            ParticleEmitter.Enabled = true;
        end
    end

    local CurrentIteration = self.FireIteration;
    delay(.15, function()
        if (CurrentIteration ~= self.FireIteration) then return; end;

        for _, Light:Light in ipairs(self.Weapon.Handle:WaitForChild("Muzzle"):GetChildren()) do
            if (Light:IsA("Light")) then
                Light.Enabled = false;
            end
        end
    end)

    self.Springs.Recoil:shove(self.WeaponConfig.GetWeaponModelRecoil());
    self:PlaySound("Fire");
    
    local CameraShove = (self.WeaponConfig.GetCameraRecoil());
    self.Springs.Camera:shove(CameraShove);
end

function WeaponHandler:Footsteps()
    self.FootStepFrame = not self.FootStepFrame and 0 or self.FootStepFrame + 1;

    if ((self.FootStepFrame) >= 60/3) then
        self.FootStepFrame = 0;
        
        local raycast = workspace:Raycast(self.Character.HumanoidRootPart.Position, Vector3.new(0, -8, 0), self.RaycastParams);
        if (raycast) then
            self.FloorMaterial = raycast.Material;
            self.FootstepTable = FootstepSounds:GetTableFromMaterial(self.FloorMaterial);
        end
    end
    
    self.lastPosition = self.lastPosition or Vector3.new();

    local state = self.Humanoid:GetState();
    if (not self.FootstepTable or not self.HumanoidSpeed or (state ~= Enum.HumanoidStateType.Running and state ~= Enum.HumanoidStateType.RunningNoPhysics)) then return; end;
    
    if ((self.Character.HumanoidRootPart.Position - self.lastPosition).Magnitude <= 6) then
        return;
    end

    self.lastPosition = self.Character.HumanoidRootPart.Position;

    AudioModule:GetInstanceFromId(
        self.FootstepTable[math.random(#self.FootstepTable)]
    ):Play();
end

return WeaponHandler;