local ReplicatedStorage = game:GetService("ReplicatedStorage");

local Weapons = game:GetService("ServerStorage"):WaitForChild("Weapons");
local FastCast = require(ReplicatedStorage:WaitForChild("FastCast"));

local Events = ReplicatedStorage:WaitForChild("Events");
local Shared = ReplicatedStorage:WaitForChild("Aero"):WaitForChild("Shared");

local Thread = require(Shared:WaitForChild("Thread"));

local PlayerService = game:GetService("Players");

local WeaponManager = {
    Client = {},
    Data = {}
};

function WeaponManager:GetPlayerData(Player:Player)
    return self.Data[Player] or self:CreateStockData(Player);
end

function WeaponManager:Start()
    PlayerService.PlayerRemoving:Connect(function(Player:Player)
        if (not self.Data[Player]) then return; end;

        local PlayerData = self.Data[Player];
        
        PlayerData.Maid:Destroy();
        table.clear(PlayerData);

        self.Data[Player] = nil;
        PlayerData = nil;
    end)

    local Fired:RemoteEvent = Events:WaitForChild("Fired");
	Fired.OnServerEvent:Connect(function(...)
		self:FiredRequest(...);
	end)

    Events:WaitForChild("Shot").OnServerInvoke = (function(...)
        self:PlayerDidHitSomeone(...);
    end)

    Thread.Spawn(function()
        local RunService = game:GetService("RunService");

        self.ServerUpdateTick = RunService.Heartbeat:Connect(function() -- TODO: Maybe calculate how many times the player shot based on delta time
            for Player:Player, PlayerData in pairs(self.Data) do
                if (PlayerData.Firing) then
                    self:Fired(Player);
                end
            end
        end)
    end)
end

function WeaponManager:PlayerDidHitSomeone(Player:Player, CastUserData, Character:Model, HitPosition:Vector3)
    local PlayerData = self:GetPlayerData(Player);
    local ShotPlayer = PlayerService:GetPlayerFromCharacter(Character);

    if (ShotPlayer and ShotPlayer == Player) then
        return;
    end

    if (Character and PlayerData.WeaponConfig) then
        -- if (PlayerData.LastShot and (os.clock() - PlayerData.LastShot) < 60/PlayerData.WeaponConfig.FireRate) then
        --     print("Player shot too early"); -- TODO: Cheat detection
        --     return;
        -- end
        
        PlayerData.LastShot = time();
        
        local Humanoid = Character:FindFirstChildWhichIsA("Humanoid");

        if (Humanoid) then
            local Distance = (CastUserData.RayOrigin - Character.PrimaryPart.Position).Magnitude;
            if (Distance > (PlayerData.WeaponConfig.CastingConfig.BulletMaxDist + 25)) then -- Error margin of 25 just because
                print("Player shot too far"); -- TODO: Cheat detection
                return;
            end

            local Damage = PlayerData.WeaponConfig.Damage or 0;
            Damage *= math.clamp((5-((CastUserData.Hits and CastUserData.Hits - 1) or 0))/5, 0.1, 1);
            -- Damage *= 

            local DistancePercentage = (Distance/PlayerData.WeaponConfig.CastingConfig.BulletMaxDist); -- Damage drop off over distance
            local Falloff = 1 - (DistancePercentage ^ 2 * (3 - 2 * DistancePercentage));
            Damage *= Falloff;

            Humanoid:TakeDamage(Damage);

            Thread.Spawn(function()
                Events:WaitForChild("BloodEffect"):FireAllClients(HitPosition, Character);
            end)

            return Damage;
        end
    end
end

function WeaponManager:FiredRequest(Player, State:boolean|nil)
	local PlayerData = self:GetPlayerData(Player);

    if (State ~= nil) then
        PlayerData.Firing = State;
        return;
    else
        self:Fired(Player);
    end
end

function WeaponManager:Fired(Player:Player)
    local PlayerData = self:GetPlayerData(Player);

    if (not PlayerData.WeaponConfig) then return; end;
    if (not PlayerData.Equipped) then return; end;

    if (not PlayerData.LastShot or (time() - PlayerData.LastShot >= 60/PlayerData.WeaponConfig.FireRate)) then
        print('fired');
        PlayerData.LastShot = time();
        
        local Muzzle = PlayerData.Weapon:WaitForChild("Handle", 2):FindFirstChild("Muzzle");

        if (Muzzle) then
            for _, ParticleEmitter:ParticleEmitter|Light in ipairs(Muzzle:GetChildren()) do
                if (ParticleEmitter:IsA("ParticleEmitter")) then
                    ParticleEmitter:Emit(ParticleEmitter:GetAttribute("Emit"));
                elseif (ParticleEmitter:IsA("Light")) then
                    ParticleEmitter.Enabled = true;
                end
            end

            Thread.Delay(.15, function()
                for _, ParticleEmitter:ParticleEmitter|Light in ipairs(Muzzle:GetChildren()) do
                   if (ParticleEmitter:IsA("Light")) then
                        ParticleEmitter.Enabled = false;
                    end
                end
            end)
        end

        local Sound = PlayerData.Weapon:WaitForChild("Sounds", 2):FindFirstChild("Fire");
        if (Sound) then
            Sound = Sound:Clone();
            Sound.Parent = PlayerData.Weapon.Handle;
            Sound:Play();

            game:GetService("Debris"):AddItem(Sound, 2);
        end
    end
end

function WeaponManager:CreateStockData(Player:Player)
    local PlayerData = {
        Weapon = nil,
        WeaponConfig = nil,
        WeaponData = {},
        Maid = self.Shared.Maid.new(),
        CachedAnimations = {},
        LoadedAnimations = {},
        Aiming = false
    };

    Player.CharacterAdded:Connect(function(Character:Model)
        table.clear(self.Data[Player].CachedAnimations);

        for _, AnimationTrack:AnimationTrack in ipairs(PlayerData.LoadedAnimations) do
            AnimationTrack:Destroy();
        end
        table.clear(PlayerData.LoadedAnimations);
    end)

    self.Data[Player] = PlayerData;
    return self.Data[Player];
end

function WeaponManager:EquipWeapon(Player:Player, WeaponName:string)
    if (not Player.Character or not Player.Character.PrimaryPart or not Player.Character:FindFirstChild("Humanoid")) then return 400; end;
    
    local PlayerData = self:GetPlayerData(Player);
    local Weapon:Model = Weapons:FindFirstChild(WeaponName);
    
    if (not Weapon) then
        return 404;
    end

    -- if (WeaponName == PlayerData.Equipped) then return 200; end;

    Weapon = Weapon:Clone();
    Weapon:WaitForChild("Handle").CFrame = CFrame.new(10000, 10000, 10000);
    Weapon.Name = Player.Name;

    Weapon.Parent = workspace.Weapons;

    PlayerData.Equipped = WeaponName;
    PlayerData.Weapon = Weapon;
    PlayerData.Maid.Weapon = Weapon;

    if (PlayerData.WeaponConfig) then
        table.clear(PlayerData.WeaponConfig);
        PlayerData.WeaponConfig = nil;
    end

    PlayerData.WeaponConfig = require(Weapon:WaitForChild("Config"));

    local WeaponMotor6DDirectory = Player.Character:WaitForChild("RightHand");
    local WeaponMotor6D = WeaponMotor6DDirectory:FindFirstChild("Weapon") or Instance.new("Motor6D");

    WeaponMotor6D.Name = "Weapon";

    WeaponMotor6D.Part0 = WeaponMotor6DDirectory;
    WeaponMotor6D.Part1 = Weapon.Handle;

    WeaponMotor6D.Parent = WeaponMotor6DDirectory;

    for _, Animation:Animation in ipairs(Weapon:WaitForChild("ServerAnimations"):GetChildren()) do
        local CachedAnimation = PlayerData.CachedAnimations[Animation.AnimationId];

        if (CachedAnimation) then
            PlayerData.LoadedAnimations[Animation.Name] = CachedAnimation;
        else
            local LoadedAnimation = Player.Character.Humanoid:WaitForChild("Animator"):LoadAnimation(Animation);

            PlayerData.LoadedAnimations[Animation.Name] = LoadedAnimation;
            PlayerData.CachedAnimations[Animation.AnimationId] = LoadedAnimation;
        end
    end

    if (PlayerData.LoadedAnimations.Idle) then
        PlayerData.LoadedAnimations.Idle:Play();
    end

    return 200;
end

function WeaponManager:SetAiming(Player:Player, IsAiming:boolean)
    local PlayerData = self:GetPlayerData(Player);

    if (not PlayerData.WeaponConfig.DisableAiming) then
        PlayerData.Aiming = IsAiming;

        local AimingAnimation = PlayerData.LoadedAnimations.Aiming;

        if (AimingAnimation) then
            if (PlayerData.Aiming) then
                AimingAnimation:Play();
            else
                AimingAnimation:Stop();
            end
        end

        return 200, PlayerData.Aiming;
    end

    return 400;
end

function WeaponManager:GetWeaponConfig(Player:Player, WeaponName:string)
    -- TODO: Verify if the player can access this config

    local Weapon = Weapons:FindFirstChild(WeaponName);

    if (Weapon) then
        return 200, require(Weapon:FindFirstChild("Config"));
    end

    return 404;
end

-- Client functions

function WeaponManager.Client:Equipped(...)
    return WeaponManager:EquipWeapon(...);
end

function WeaponManager.Client:SetAiming(...)
    return WeaponManager:SetAiming(...);
end

return WeaponManager;