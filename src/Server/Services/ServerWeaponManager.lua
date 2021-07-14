local ReplicatedStorage = game:GetService("ReplicatedStorage");
local Weapons = game:GetService("ServerStorage"):WaitForChild("Weapons");
local FastCast = require(ReplicatedStorage:WaitForChild("FastCast"));

local PlayerService = game:GetService("Players");

local WeaponManager = {
    Client = {},
    Caster = FastCast.new(),
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

    Weapon = Weapon:Clone();
    Weapon:WaitForChild("Handle").CFrame = CFrame.new(10000, 10000, 10000);
    Weapon.Name = Player.Name;

    Weapon.Parent = workspace.Weapons;

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