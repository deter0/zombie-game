local ReplicatedStorage = game:GetService("ReplicatedStorage");

local Weapons = game:GetService("ReplicatedStorage"):WaitForChild("Weapons");
local FastCast = require(ReplicatedStorage:WaitForChild("FastCast"));

local Events = ReplicatedStorage:WaitForChild("Events");

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

    --@ https://en.wikipedia.org/wiki/Smoothstep
    local function SmoothStep(edge0:number, edge1:number, x:number)
        -- Scale, bias and saturate x to 0..1 range
        x = math.clamp((x - edge0) / (edge1 - edge0), 0, 1); 
        -- Evaluate polynomial
        return x * x * (3 - 2 * x);
    end

    Events:WaitForChild("Shot").OnServerInvoke = (function(Player:Player, CastUserData, Character:Model, RaycastResults:RaycastResults)
        local PlayerData = self:GetPlayerData(Player);

        print(CastUserData);

        if (Character and PlayerData.WeaponConfig) then
            -- if (PlayerData.LastShot and (os.clock() - PlayerData.LastShot) < 60/PlayerData.WeaponConfig.FireRate) then
            --     print("Player shot too early"); -- TODO: Cheat detection
            --     return;
            -- end
            
            PlayerData.LastShot = os.clock();
            
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

                local DistancePercentage = (Distance/PlayerData.WeaponConfig.CastingConfig.BulletMaxDist);
                local Falloff = 1 - (DistancePercentage ^ 2 * (3 - 2 * DistancePercentage));

                Damage *= Falloff;

                Humanoid:TakeDamage(Damage);
                return Damage;
            end
        end
    end)
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