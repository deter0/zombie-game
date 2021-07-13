local RunService = game:GetService("RunService");
local PlayerService = game:GetService("Players");
local Player = PlayerService.LocalPlayer;

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Aero"):WaitForChild("Shared");
local Maid = require(Shared:WaitForChild("Maid"));
local Thread = require(Shared:WaitForChild("Thread"));

local InputManager = {
    Maid = Maid.new()
};

function InputManager:Start()
    self.ServerWeaponManager = self.Services.ServerWeaponManager;

    self.CurrentWeapon = nil;
    self.EnumBinds = {
        [1] = Enum.KeyCode.One,
        [2] = Enum.KeyCode.Two,
        [3] = Enum.KeyCode.Three,
        [4] = Enum.KeyCode.Four
    };
    
    local Camera = workspace.CurrentCamera or workspace:WaitForChild("Camera");
    for _, v in ipairs(Camera:GetChildren()) do
        if (v.Name ~= "Viewmodel") then continue; end;
        v:Destroy();
    end
    
    local ContextActionService = game:GetService("ContextActionService");
    
    if (not game:IsLoaded()) then
        game.Loaded:Wait();
    end
    
    self.Weapons = game:GetService("ReplicatedStorage"):WaitForChild("Weapons"):GetChildren();
    self.WeaponHandler = self.WeaponHandlerClass.new(self.ServerWeaponManager);
    self.Maid.WeaponHandler = self.WeaponHandler;

    workspace.Weapons.ChildAdded:Connect(function(Weapon:Model)
        if (Weapon.Name == Player.Name) then
            game:GetService("Debris"):AddItem(Weapon, .001); --> Weird issues with it not working with only :Destroy()
        end
    end)

    local debounce;

    for i, Weapon in ipairs(self.Weapons) do
        local function Equip(_, State)
            xpcall(function()
                if (debounce) then return; end;
                if (State ~= Enum.UserInputState.Begin) then return; end;
                if (self.WeaponHandler.EquipAnimationPlaying) then return; end;
                Thread.Spawn(function()
                    self.WeaponHandler:Equip(Weapon.Name);
                end)

            end, function(err)
                error(err);
            end)
        end

        ContextActionService:BindAction("equip"..i, Equip, false, self.EnumBinds[i]);
    end

    self.Maid.Update = RunService.RenderStepped:Connect(function(DeltaTime)
        self.WeaponHandler:Update(DeltaTime);
    end)
end

function InputManager:Init()
    self.WeaponHandlerClass = require(script:WaitForChild("WeaponHandler"));
    self.Thread = self.Shared.Thread;
    self.ServerWeaponManager = self.Services.ServerWeaponManager;
end

return InputManager;