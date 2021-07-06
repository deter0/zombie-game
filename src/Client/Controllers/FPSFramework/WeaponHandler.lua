local WeaponHandler = {};
WeaponHandler.__index = WeaponHandler;

local LoadedAnimationCache = {};
local WeaponConfigCache = {};

local ReplicatedStorage = game:GetService("ReplicatedStorage");
local UserInputService = game:GetService("UserInputService");
local TweenService = game:GetService("TweenService");
local ContextActionService = game:GetService("ContextActionService");
local CollectionService = game:GetService("CollectionService");

local Shared = ReplicatedStorage:WaitForChild("Aero"):WaitForChild("Shared");

local Maid = require(Shared:WaitForChild("Maid"));
local AudioEmitter = require(Shared:WaitForChild("AudioEmitter"));
local FootstepSounds = require(Shared:WaitForChild("FootstepSounds"));
local Spring = require(Shared:WaitForChild("Spring"));
local AudioModule = require(Shared:WaitForChild("AudioModule"));
local Thread = require(Shared:WaitForChild("Thread"));

delay = Thread.Delay;

-- warn = function() end;
-- print = warn;

local Player = game:GetService("Players").LocalPlayer;
local Mouse = Player:GetMouse();

local Camera = workspace.CurrentCamera or workspace:WaitForChild("Camera");

local function GetBobbing(Addition:number, Modifier:number, Speed:number)
    return math.sin(os.clock() * Addition * (Speed or 0)) * Modifier;
end

local function Lerp(a:number, b:number, alpha:number)
    return a + (b - a) * alpha;
end

local function IsStatusValid(Status:number)
    return (Status >= 200 and Status <= 299);
end

local function PlayTweenOnce(Object:Instance, Properties, TweenInformation:TweenInfo, Callback)
    local Tween = TweenService:Create(Object, TweenInformation, Properties);

    local Completed; Completed = Tween.Completed:Connect(function()
        Tween:Destroy();
        Completed:Disconnect();

        Completed = nil;
        Tween = nil;

        if (Callback) then Callback(); end;
    end)
    Tween:Play();
end

-- Player.CharacterAdded:Connect(function(Character)
--     -- WeaponHandler:SetCharacter(Character);
--     -- WeaponHandler.Character = Character;
--     -- WeaponHandler.RaycastParams = WeaponHandler.RaycastParams or RaycastParams.new();
--     -- WeaponHandler.RaycastParams.FilterDescendantsInstances = {
--     --     Camera, Character, workspace:WaitForChild("Weapons")
--     -- }
-- end)

function WeaponHandler.new(ServerManager)
    local self = setmetatable(
        {
            Maid = Maid.new(),
            ActiveMaid = Maid.new(),
            Springs = {
                Spread = Spring.create(),
                Recoil = Spring.create(),
                Sway = Spring.create(nil, 4, 50, 6, 6),
                WalkCycle = Spring.create(),
                Camera = Spring.create()
            },
            ServerManager = ServerManager,
            Spread = 0,
            Speed = 0
        },
        WeaponHandler
    );

    local Character = Player.Character;

    if (Character) then warn("Character exists"); self:SetCharacter(Character); end;

    Player.CharacterAdded:Connect(function(Character)
        warn("Character added");
        self:SetCharacter(Character);
    end)

    return self;
end

function WeaponHandler:Remove()
    warn("Removing");

    if (self.Viewmodel) then
        self.Viewmodel.Parent = ReplicatedStorage.Cache;
    end

    if (self.Weapon) then
        self.Weapon.Parent = ReplicatedStorage.Cache;
    end

    self.Equipped = nil;
    self.ActiveMaid:DoCleaning();
end

function WeaponHandler:Destroy()
    if (self.Viewmodel) then self.Viewmodel.Parent = ReplicatedStorage.Cache; end;

    self.Maid:Destroy();
    self.ActiveMaid:Destroy();

    table.clear(self);
    setmetatable(self, nil);

    self.Destroyed = true;
end

function WeaponHandler:SetCharacter(NewCharacter:Model)
    self.Character = NewCharacter;

    self.RaycastParams = self.RaycastParams or RaycastParams.new();
    table.clear(self.RaycastParams.FilterDescendantsInstances);
    self.RaycastParams.FilterDescendantsInstances = {
        Camera,
        NewCharacter,
        workspace:WaitForChild("Weapons")
    }

    self.ProximityParams = self.ProximityParams or RaycastParams.new();
    table.clear(self.ProximityParams.FilterDescendantsInstances);
    self.ProximityParams.FilterDescendantsInstances = {
        NewCharacter,
        Camera,
        table.unpack(CollectionService:GetTagged("NotCollidable"))
    };
    
    self.ProximityParams.IgnoreWater = true;

    self.Humanoid = self.Character:WaitForChild("Humanoid");
    self.ActiveMaid.Running = self.Humanoid.Running:Connect(function(Speed)
        self.Speed = Speed / 16;
        self.HumanoidSpeed = Speed;
    end)
end

function WeaponHandler:Equip(WeaponName:string)
    if (WeaponName == self.Equipped) then return; end;
    if (self.IsAMenuOpen) then return; end;

    self.ActiveMaid = self.ActiveMaid or Maid.new();

    if (self.Disabled) then warn("Disabled"); return; end;

    local Status = self.ServerManager:Equipped(WeaponName);

    if (not IsStatusValid(Status)) then
        warn("Got invalid status from server", Status);
        return;
    end

    self:Remove();
    self:SetCharacter(self.Character or Player.Character);

    if (not self.ServerManager) then
        self.ServerManager = self.Services.ServerWeaponManager;
    end

    self.Camera = Camera;

    local CachedViewmodel = ReplicatedStorage.Cache:FindFirstChild("Viewmodel");

    if (CachedViewmodel) then
        self.Viewmodel = CachedViewmodel;
    else
        table.clear(LoadedAnimationCache);
        LoadedAnimationCache = {};
        self.Viewmodel = ReplicatedStorage:WaitForChild("Viewmodel"):Clone();
    end
    CachedViewmodel = nil;

    if (self.LoadedAnimations) then
        for _, AnimationTrack:AnimationTrack in pairs(self.LoadedAnimations) do
            AnimationTrack:Destroy();
        end

        table.clear(self.LoadedAnimations);
    end

    self.LoadedAnimations = {};

    self.Weapon = ReplicatedStorage.Cache:FindFirstChild(WeaponName) or ReplicatedStorage:WaitForChild("Weapons"):FindFirstChild(WeaponName);
    local WasWeaponCached = self.Weapon.Parent.Name == "Cache";

    if (not self.Weapon) then warn("Weapon not found"); return; end;

    warn("Cached weapon: ", WasWeaponCached);

    if (not WasWeaponCached) then
        self.Weapon = self.Weapon:Clone();
    end

    -- if (self.WeaponConfig) then
    --     table.clear(self.WeaponConfig);
    --     self.WeaponConfig = nil;
    -- end

    self.Humanoid = self.Character:WaitForChild("Humanoid");

    self.WeaponConfig = require(self.Weapon:WaitForChild("Config"));
    -- GetConfigStatus = nil;

    self.Crosshair = ReplicatedStorage:WaitForChild("Crosshair"):Clone();
    self.ActiveMaid.Crosshair = self.Crosshair;

    self.CrosshairCenter = self.Crosshair:WaitForChild("CrosshairUI"):WaitForChild("Center"):WaitForChild("Scale");

    for _, BasePart:BasePart in ipairs(self.Viewmodel:GetChildren()) do
        if (BasePart:IsA("BasePart")) then
            BasePart.CanCollide = false;
            BasePart.CastShadow = false;
        end
    end

    for _, BasePart:BasePart in ipairs(self.Weapon:GetDescendants()) do
        if (BasePart:IsA("BasePart")) then
            BasePart.CanCollide = false;
            BasePart.CastShadow = false;
        end
    end

    self.Fired = nil;

    self.RaycastParams = self.RaycastParams or RaycastParams.new();
    table.clear(self.RaycastParams.FilterDescendantsInstances);
    self.RaycastParams.FilterDescendantsInstances = {Camera, self.Character, workspace.Weapons};

    -- Wait for instances to load

    self.Viewmodel:WaitForChild("RootPart"):WaitForChild("Weapon");
    self.Weapon:WaitForChild("Handle");

    self.Viewmodel.RootPart.CFrame = CFrame.new(50000, 50000, 50000);
    self.Weapon.Handle.CFrame = self.Viewmodel.RootPart.CFrame;

    self.Viewmodel.RootPart.Weapon.Part1 = self.Weapon.Handle;

    self.Viewmodel.Parent = Camera;
    self.Weapon.Parent = self.Viewmodel;
    self.Crosshair.Parent = Camera;

    self.ViewmodelAnimationController = self.Viewmodel:WaitForChild("AnimationController");

    for _, AnimationTrack:AnimationTrack in ipairs(self.ViewmodelAnimationController:GetPlayingAnimationTracks()) do
        AnimationTrack:Stop(0);
    end

    for _, Animation in ipairs(self.Weapon.Animations:GetChildren()) do
        local CachedAnimation = LoadedAnimationCache[Animation.AnimationId];

        if (CachedAnimation) then
            self.LoadedAnimations[Animation.Name] = CachedAnimation;
        else
            local LoadedAnimation = self.ViewmodelAnimationController:LoadAnimation(Animation);
            self.LoadedAnimations[Animation.Name] = LoadedAnimation;
            LoadedAnimationCache[Animation.AnimationId] = LoadedAnimation;
        end
    end

    self.Equipped = self.Weapon.Name;

    if (self.LoadedAnimations.Idle) then
        self.LoadedAnimations.Idle.Looped = true;
        self.LoadedAnimations.Idle.Priority = Enum.AnimationPriority.Idle;
    end

    self:PlayAnimation("Idle", 0);

    UserInputService.MouseIconEnabled = false;

    self:BindActions();

    self:PlayEquipAnimation();

    self.Equipped = self.Weapon.Name;

    -- warn("Sent equip request to server. Status: ", self.ServerManager:EquippedWeapon(self.Weapon.Name));

    WasWeaponCached = nil;
    return true;
end

function WeaponHandler:BindActions()
    self:UnbindActions();

    ContextActionService:BindAction("Aim", function(...)
        self:Aim(...);
    end, false, Enum.UserInputType.MouseButton2);

    ContextActionService:BindAction("Fire", function(...)
        self:FireActionCalled(...);
    end, false, Enum.UserInputType.MouseButton1);

    ContextActionService:BindAction("Sprinting", function(_, State)
        self:HandleRunningAction(State);
    end, false, Enum.KeyCode.LeftShift);
end

function WeaponHandler:HandleRunningAction(State)
    if (self.LoadedAnimations.Running) then
        self.LoadedAnimations.Running.Priority = Enum.AnimationPriority.Action;
    end

    if (State == Enum.UserInputState.Begin) then
        self:PlayAnimation("Running", .1);

        self:Aim(nil, Enum.UserInputState.End);
        self.Humanoid.WalkSpeed = 20;

        self.Running = true;
    else
        self:StopAnimation("Running", .3);
        self.Humanoid.WalkSpeed = 16;

        self.Running = false;
    end
end

function WeaponHandler:Aim(_, State)
    if (not self.WeaponConfig.DisableAim) then
        if (self.Running) then return; end;

        local Aiming = State ~= Enum.UserInputState.End;
        Thread.Spawn(function()
            local CanAimStatus, AimingState = self.ServerManager:SetAiming(Aiming);

            if (IsStatusValid(CanAimStatus)) then
                self.Aiming = AimingState;
            else
                self.Aiming = false;
            end
        end)

        self.Aiming = Aiming or false;
    else
        self.Aiming = false;
        self.ServerManager:SetAiming(false);
    end
end

function WeaponHandler:StopAnimation(AnimationTitle:string, StopSpeed:number)
    local LoadedAnimation = self.LoadedAnimations[AnimationTitle];

    if (LoadedAnimation) then
        LoadedAnimation:Stop(StopSpeed);
    end
end

function WeaponHandler:UnbindActions()
    ContextActionService:UnbindAction("Aim");
    ContextActionService:UnbindAction("Fire");
    ContextActionService:UnbindAction("Sprinting");
end

function WeaponHandler:FirePrime()
    self:PlayAnimation("Firing", .3);
    self:Fire();
    if (self.WeaponConfig.Pumping) then self:Pump(); end;
    self.Fired = os.clock();
end

function WeaponHandler:FireActionCalled(_, State)
    if (State == Enum.UserInputState.Begin) then
        if (not self.Weapon) then return; end;
        if (not self.ServerManager) then return; end;
        if (not self.WeaponConfig or not self.WeaponConfig.FireRate) then warn("Returing"); return; end;

        if (not self.Fired or (os.clock() - self.Fired) >= (60/self.WeaponConfig.FireRate)) then
            self:FirePrime();
        end
    elseif (State == Enum.UserInputState.End) then
        self:StopAnimation("Firing", .3);
        self.Firing = false;
    end
end


function WeaponHandler:PlayEquipAnimation()
    self.EquipTweenInfo = self.WeaponConfig.EquipTweenInfo or self.EquipTweenInfo or TweenInfo.new(.6, Enum.EasingStyle.Circular, Enum.EasingDirection.Out);
    local EquipOffset = self.Weapon:WaitForChild("Offsets"):WaitForChild("ViewmodelOffset"):WaitForChild("Equip");

    EquipOffset.Value = self.Weapon.Offsets.InitalEquip.Value;
    self.EquipAnimationPlaying = true;

    PlayTweenOnce(
        EquipOffset,
        {Value = Vector3.new()},
        self.EquipTweenInfo,
        function()
            self.EquipAnimationPlaying = false;
        end
    );
end

function WeaponHandler:MenuToggled(MenuName:string, State:boolean)
    self.OpenMenus = self.OpenMenus or {};
    
    if (not self.ActiveMaid.OpenMenus) then
        self.ActiveMaid.OpenMenus = self.OpenMenus;
    end

    self.OpenMenus[MenuName] = State;

    self.IsAMenuOpen = false;

    for _, MenuOpen in pairs(self.OpenMenus) do
        if (MenuOpen) then
            self.IsAMenuOpen = true;
            break;
        end
    end

    if (not self.Equipped) then return; end;

    if (self.IsAMenuOpen) then
        self:UnbindActions();
        UserInputService.MouseIconEnabled = true;
    else
        self:BindActions();
    end
end

function WeaponHandler:PlayAnimation(AnimationTitle:string, PlaySpeed:number?)
    local Animation = self.LoadedAnimations[AnimationTitle];

    if (Animation) then
        Animation:Play(PlaySpeed);
        return 1;
    else
        return -1;
    end
end

function WeaponHandler:PlaySound(SoundName:string)
    local Sound = self.Weapon:WaitForChild("Sounds"):FindFirstChild(SoundName);

    if (Sound) then
        Sound = Sound:Clone();
        Sound.Parent = self.Weapon.Sounds;

        Sound:Play();

        local Stopped; Stopped = Sound.Stopped:Connect(function()
            Stopped:Disconnect();
            Sound:Destroy();

            Sound = nil;
            Stopped = nil;
        end)
    end
end

function WeaponHandler:Pump()
    Thread.Delay(self.WeaponConfig.PumpDelay or .4, function()
        self:PlayAnimation("Pump", 0.3);
    end)
end

local EmptyCFrame = CFrame.new();
local VeryFar = CFrame.new(1e8, 1e8, 1e8);

function WeaponHandler:Update(DeltaTime:number)
    if (not self.Equipped) then return; end;
    if (not self.WeaponConfig) then
        self.WeaponConfig = require(self.Weapon:WaitForChild("Config"));
    end

    if (self.IsAMenuOpen) then
        self.Viewmodel.RootPart.CFrame = VeryFar;
        self.Crosshair.CFrame = VeryFar;

        return;
    end

    if (not self.Character or not self.Character.PrimaryPart) then print("no primary part or character, exiting."); return; end;

    if (self.Automatic and self.Firing and (not self.Fired or ((os.clock() - self.Fired) >= (60/self.WeaponConfig.FireRate)))) then
        self:FirePrime();
    end

    UserInputService.MouseIconEnabled = false;

    local AimingSpeed = self.WeaponConfig.AimingSpeed or 6;

    if (self.Aiming) then
        Camera.FieldOfView = Lerp(Camera.FieldOfView, 40, DeltaTime * AimingSpeed);
    else
        Camera.FieldOfView = Lerp(Camera.FieldOfView, 65, DeltaTime * AimingSpeed);
    end

    local TargetAim = self.Aiming and self.Weapon.Offsets.Aim.Value or Vector3.new();

    self.Weapon.Offsets.ViewmodelOffset.Aiming.Value =
        self.Weapon.Offsets.ViewmodelOffset.Aiming.Value:Lerp(
            TargetAim,
            DeltaTime * AimingSpeed
        );

    AimingSpeed = nil;
    local MasterOffset = CFrame.new();

    for _, Offset in ipairs(self.Weapon.Offsets.ViewmodelOffset:GetChildren()) do
        local OffsetValue = Offset.Value;

        if (typeof(OffsetValue) == "Vector3") then
            MasterOffset += OffsetValue;
        else
            MasterOffset *= OffsetValue;
        end
    end

    -- if (not self.WeaponConfig.DisableProximityPushback) then
    --     local Backpoint = Camera.CFrame.Position;
    --     local _, Size = self.Viewmodel:GetBoundingBox();
    --     Size = Size.Magnitude;

    --     local ProximityRaycast = workspace:Raycast(
    --         Backpoint, Camera.CFrame.LookVector * Size, self.ProximityParams
    --     );

    --     local Offset = EmptyCFrame;

    --     if (ProximityRaycast) then
    --         local Distance = (Camera.CFrame.Position - ProximityRaycast.Position).Magnitude;
    --         Offset = CFrame.new(0, 0, (1-(Distance/Size))*Size);
    --     end

    --     if (not self.ProximityPushbackOffset) then
    --         self.ProximityPushbackOffset = EmptyCFrame;
    --     end

    --     self.ProximityPushbackOffset = self.ProximityPushbackOffset:Lerp(Offset, DeltaTime * 5);

    --     MasterOffset *= self.ProximityPushbackOffset;
    -- end

    self.RunningCFrame = self.RunningCFrame or EmptyCFrame;
    local RunningCFrame =
        EmptyCFrame:Lerp(self.Running and (self.Weapon.Offsets:FindFirstChild("Running") and self.Weapon.Offsets.Running.Value or CFrame.new(.4, 0, -.3) * CFrame.Angles(0, math.rad(45), 0)) or EmptyCFrame, self.Speed or 0);

    self.RunningCFrame = self.RunningCFrame:Lerp(RunningCFrame, 5 * DeltaTime);

    MasterOffset *= self.RunningCFrame;

    self.JumpingVelocity = self.JumpingVelocity or EmptyCFrame;

    local JumpingVelocity = CFrame.Angles(-math.rad(self.Character.PrimaryPart.Velocity.Y), 0, 0);
    self.JumpingVelocity = self.JumpingVelocity:Lerp(JumpingVelocity, 10 * DeltaTime);

    MasterOffset *= self.JumpingVelocity;

    local MouseDelta = UserInputService:GetMouseDelta();

    self.Springs.Sway:shove(Vector3.new(MouseDelta.X / 200, MouseDelta.Y / 200));

    if (self.LoadedAnimations.Running) then
        if (self.Running) then
            self.LoadedAnimations.Running:AdjustWeight(math.clamp(self.Speed, 0, 1), .2);
        else
            self.LoadedAnimations.Running:AdjustWeight(0, .2);
        end
    end

    local AimingInfluence = self.Aiming and (self.WeaponConfig.AimingInfluence or .1) or 1; --> Alternative to lower wobble when aiming
    local GunSwayInfluence = self.WeaponConfig.GunSwayInfluence or .7;

    local MovementSway = Vector3.new(
        (GetBobbing(4, 30, self.Speed * (self.Running and 1.2 or 1))) * DeltaTime * (self.Running and 1.6 or 1),
        ((GetBobbing(8, 15, self.Speed * (self.Running and 1.2 or 1)) * -1)) * DeltaTime  * (self.Running and 1.6 or 1),
        0
    ) * GunSwayInfluence * AimingInfluence;

    self.CameraBobbingCFrame = self.CameraBobbingCFrame or EmptyCFrame;
    self.CameraBobbingCFrame = self.CameraBobbingCFrame:Lerp(CFrame.Angles(0, 0, math.rad(GetBobbing(6+(self.Running and 1.3 or 0), .7, self.Speed)) * (self.Running and 2 or 1)), DeltaTime * 5);

    local CameraOffset = self.Springs.Camera:update(DeltaTime);
    CameraOffset = CFrame.Angles(
        math.rad(CameraOffset.X),
        math.rad(CameraOffset.Y),
        math.rad(CameraOffset.Z)
    ) * self.CameraBobbingCFrame;

    self.CameraOffset = self.CameraOffset or EmptyCFrame;

    Camera.CFrame *= EmptyCFrame:Lerp(self.CameraOffset, self.WeaponConfig.CameraRecoilRecovery or .5) * CameraOffset; --?

    self.CameraOffset = CameraOffset;

    local ShoveOffset = self.Springs.Sway:update(DeltaTime);
    local RecoilOffset = self.Springs.Recoil:update(DeltaTime);

    self.Sway = self.Sway and self.Sway:Lerp(
        CFrame.new(MovementSway), DeltaTime * 5
    ) or CFrame.new();


    self.CrosshairCenter.Scale = Lerp(self.CrosshairCenter.Scale, self.Aiming and 0 or 1, DeltaTime * 15);

    self.CrosshairDirection = not self.CrosshairDirection and Camera.CFrame.LookVector or self.CrosshairDirection:Lerp(Camera.CFrame.LookVector, DeltaTime * 18);
    self.Crosshair.CFrame = CFrame.lookAt(Camera.CFrame.Position + (self.CrosshairDirection * 5), Camera.CFrame.Position);

    self.Viewmodel.RootPart.CFrame = Camera.CFrame:ToWorldSpace(CFrame.new(RecoilOffset) * CFrame.new(ShoveOffset));
	self.Viewmodel.RootPart.CFrame *= CFrame.Angles(0,-ShoveOffset.X, ShoveOffset.Y);

    self.Viewmodel.RootPart.CFrame *= MasterOffset * self.Sway;

    self:Footsteps();

    AimingInfluence = nil;
    GunSwayInfluence = nil;
end

function WeaponHandler:Fire()
    if (self.Running) then return; end;

    -- self.ServerManager:Fire(
    --     self.Weapon:WaitForChild("Handle"):WaitForChild("Muzzle").WorldPosition,
    --     Camera.CFrame.LookVector
    -- );

    self.FireIteration = not self.FireIteration and 1 or self.FireIteration + 1;

    for _, ParticleEmitter:ParticleEmitter|Light in ipairs(self.Weapon.Handle:WaitForChild("Muzzle"):GetChildren()) do
        if (ParticleEmitter:IsA("ParticleEmitter")) then
            ParticleEmitter:Emit(ParticleEmitter:GetAttribute("Emit"));
        elseif (ParticleEmitter:IsA("Light")) then
            ParticleEmitter.Enabled = true;
        end
    end

    local CurrentIteration = self.FireIteration;
    Thread.Delay(.15, function()
        if (CurrentIteration ~= self.FireIteration) then CurrentIteration = nil; return; end;

        for _, Light:Light in ipairs(self.Weapon.Handle:WaitForChild("Muzzle"):GetChildren()) do
            if (Light:IsA("Light")) then
                Light.Enabled = false;
            end
        end

        CurrentIteration = nil;
    end)

    self.Springs.Recoil:shove(self.WeaponConfig.GetWeaponModelRecoil());
    self:PlaySound("Fire");

    local CameraShove = (self.WeaponConfig.GetCameraRecoil());
    self.Springs.Camera:shove(CameraShove);
end

function WeaponHandler:Footsteps()
    self.FootstepFrame = not self.FootstepFrame and 1 or self.FootstepFrame + 1;

    if (self.FootstepFrame >= 60/3) then
        self.FootstepFrame = 0;

        local raycast = workspace:Raycast(self.Character.HumanoidRootPart.Position, Vector3.new(0, -8, 0), self.RaycastParams);
        if (raycast) then
            self.FloorMaterial = raycast.Material;
            self.FootstepTable = FootstepSounds:GetTableFromMaterial(self.FloorMaterial);
        end
    end

    self.lastPosition = self.lastPosition or Vector3.new();

    self.HumanoidState = self.Humanoid:GetState();
    if (not self.FootstepTable or not self.HumanoidSpeed or (self.HumanoidState ~= Enum.HumanoidStateType.Running and self.HumanoidState ~= Enum.HumanoidStateType.RunningNoPhysics)) then return; end;

    if ((self.Character.HumanoidRootPart.Position - self.lastPosition).Magnitude <= 4) then
        return;
    end

    self.lastPosition = self.Character.HumanoidRootPart.Position;

    AudioModule:GetInstanceFromId(
        self.FootstepTable[math.random(#self.FootstepTable)]
    ):Play();
end

return WeaponHandler;