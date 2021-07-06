-- -- Server Weapon Manager
-- -- Deter
-- -- June 20, 2021

-- local LoadedAnimations = {};

-- local Weapons = game:GetService("ReplicatedStorage"):WaitForChild("Weapons");

-- local Events = game:GetService("ReplicatedStorage"):WaitForChild("Events");

-- local ReplicatedStorage = game:GetService("ReplicatedStorage");
-- local Shared = ReplicatedStorage:WaitForChild("Aero"):WaitForChild("Shared");

-- local FastCast = require(ReplicatedStorage:WaitForChild("FastCastRedux"));
-- local PartCacheModule= require(ReplicatedStorage:WaitForChild("PartCache"));
-- local Thread = require(Shared:WaitForChild("Thread"));
-- local Maid = require(Shared:WaitForChild("Maid"));
-- local Ragdoll = require(Shared:WaitForChild("Ragdoll"));

-- Thread.DelayRepeat(60, function()
--     for i, v in ipairs(LoadedAnimations) do
--         LoadedAnimations[i] = table.clear(v);
--     end
-- end)

-- FastCast.DebugLogging = false;
-- FastCast.VisualizeCasts = false;

-- local ActiveRagdolls = {};

-- function OnRayHit(Humanoid:Humanoid, Config, MuzzlePosition, hitPart:BasePart, hitPosition)
--     Humanoid:TakeDamage(Config.DamagePerBullet);

--     if (Humanoid.Health < 0) then
--         if (not ActiveRagdolls[Humanoid]) then
--             local CharacterRagdoll = Ragdoll.new(Humanoid.Parent);
--             CharacterRagdoll:setRagdolled(true);

--             ActiveRagdolls[Humanoid] = true;
--          end

--         local Direction = (hitPosition - MuzzlePosition).Unit;
--         hitPart:ApplyImpulseAtPosition(Direction * (Config.BulletKnockback or 9000), hitPosition or hitPart.Position);

--         -- Events:WaitForChild("Ragdoll"):FireAllClients(Humanoid.Parent, Direction, hitPart, hitPosition);
--     end
-- end

-- local ServerWeaponManager = {DiedMaid = Maid.new(), PlayerWeapons = {}, Client = {}};

-- function ServerWeaponManager.Client:EquippedWeapon(Player, WeaponName:string)
--     if (not WeaponName or not Player) then return 400; end;

--     local Weapon = Weapons:FindFirstChild(WeaponName);
--     if (not Weapon) then
--         return 404;
--     end

--     Weapon = Weapon:Clone();

--     if (ServerWeaponManager.PlayerWeapons[Player]) then
--         table.clear(ServerWeaponManager.PlayerWeapons[Player].LoadedAnimations);
--         table.clear(ServerWeaponManager.PlayerWeapons[Player].Config);
--         table.clear(ServerWeaponManager.PlayerWeapons[Player]);

--         if (ServerWeaponManager.PlayerWeapons[Player].Weapon) then
--             ServerWeaponManager.PlayerWeapons[Player].Weapon:Destroy();
--         end
--     end

--     ServerWeaponManager.PlayerWeapons[Player] = {
--         Weapon = Weapon,
--         LoadedAnimations = {},
--         Config = require(Weapon:WaitForChild("Config")),
--         RNG = Random.new()
--     };

--     ServerWeaponManager.PlayerWeapons[Player].CasterConfig = ServerWeaponManager.PlayerWeapons[Player].Config.CastingConfig or {
--         BulletSpeed = 400,
--         BulletMaxDist = 400,
--         BulletGravity = Vector3.new(0, -25, 0),
--         MinBulletSpreadAngle = -2,
--         MaxBulletSpreadAngle = 2,
--         FireDelay = 0,
--         BulletsPerShot = 8,
--         PierceDemo = true,
--         DamagePerBullet = 5,
--         SpeedSpreadAffector = .5,
--         AimingSpreadAffector = .1,
--         BloodType = "a"
--     };

--     local Config = ServerWeaponManager.PlayerWeapons[Player].CasterConfig;

--     local RNG = Random.new();

--     local CosmeticBulletsFolder = workspace:FindFirstChild("CosmeticBulletsFolder") or Instance.new("Folder", workspace);
--     CosmeticBulletsFolder.Name = "CosmeticBulletsFolder";

--     local Caster = FastCast.new();

--     local CosmeticBullet = Weapon:FindFirstChild("Bullet") or game:GetService("ReplicatedStorage"):WaitForChild("Bullet"):Clone();

--     local CastParams = RaycastParams.new()
--     CastParams.IgnoreWater = true
--     CastParams.FilterType = Enum.RaycastFilterType.Blacklist
--     CastParams.FilterDescendantsInstances = {
--         Player.Character,
--         CosmeticBulletsFolder,
--         workspace.Weapons
--     }

--     local CosmeticPartProvider = PartCacheModule.new(CosmeticBullet, 100, CosmeticBulletsFolder);

--     local CastBehavior = FastCast.newBehavior();
--     CastBehavior.RaycastParams = CastParams;
--     CastBehavior.MaxDistance = Config.BulletMaxDist;
--     CastBehavior.HighFidelityBehavior = FastCast.HighFidelityBehavior.Default;

--     -- CastBehavior.CosmeticBulletTemplate = CosmeticBullet -- Uncomment if you just want a simple template part and aren't using PartCache
--     CastBehavior.CosmeticBulletProvider = CosmeticPartProvider; -- Comment out if you aren't using PartCache.

--     CastBehavior.CosmeticBulletContainer = CosmeticBulletsFolder;
--     CastBehavior.Acceleration = Config.BulletGravity;
--     CastBehavior.AutoIgnoreContainer = false;

--     local PlayerData = ServerWeaponManager.PlayerWeapons[Player];

--     ServerWeaponManager.PlayerWeapons[Player].CanPierce = function(Cast, RayResult, SegmentVelocity)
--         local Hits = Cast.UserData.Hits;
--         if (not Hits) then
--             Cast.UserData.Hits = 1;
--         else
--             Cast.UserData.Hits += 1;
--         end
        
--         if (Cast.UserData.Hits > 3) then
--             return false
--         end
        
--         local hitPart = RayResult.Instance;
--         if (hitPart ~= nil and hitPart.Parent ~= nil) then
--             local humanoid = hitPart.Parent:FindFirstChildOfClass("Humanoid");
            
--             local hitPoint = RayResult.Position;

--             if (humanoid and not ServerWeaponManager.PlayerWeapons[Player].Hit[humanoid]) then
--                 ServerWeaponManager.PlayerWeapons[Player].Hit[humanoid] = true;
--                 OnRayHit(humanoid, ServerWeaponManager.PlayerWeapons[Player].CasterConfig, PlayerData.MuzzleWorldPosition, hitPart, hitPoint);
--             end

--             return true;
--         end

--         -- This function shows off the piercing feature literally. Pass this function as the last argument (after bulletAcceleration) and it will run this every time the ray runs into an object.
        
--         -- Do note that if you want this to work properly, you will need to edit the OnRayPierced event handler below so that it doesn't bounce.
        
--         local material = hitPart and hitPart.Material or nil;
--         if (material and material == Enum.Material.Plastic or material == Enum.Material.Ice or material == Enum.Material.Glass or material == Enum.Material.SmoothPlastic) then
--             if hitPart.Transparency >= 0.5 then
--                 return true;
--             end
--         end

--         if (hitPart and hitPart.CanCollide == false) then
--             return true;
--         end

--         return false;
--     end
    
--     local TAU = math.pi*2;
--     local CasterConfig = ServerWeaponManager.PlayerWeapons[Player].CasterConfig;

--     ServerWeaponManager.PlayerWeapons[Player].Fire = function(direction)
--         ServerWeaponManager.PlayerWeapons[Player].Hit = {};

--         local SpeedAffector = math.clamp((Player.Character.PrimaryPart.Velocity.Magnitude*Config.SpeedSpreadAffector), 1, math.huge);
--         local AimingAffector = (ServerWeaponManager.PlayerWeapons[Player].Aiming and CasterConfig.AimingSpreadAffector or 1);

--         local directionalCF = CFrame.new(Vector3.new(), direction)
--         local newDirection = (directionalCF * CFrame.fromOrientation(0, 0, PlayerData.RNG:NextNumber(0, TAU)) * CFrame.fromOrientation(
--             math.rad(
--                 PlayerData.RNG:NextNumber(
--                     Config.MinBulletSpreadAngle*SpeedAffector*AimingAffector,
--                     Config.MaxBulletSpreadAngle*SpeedAffector*AimingAffector
--                 )
--             ), 0, 0)).LookVector;
        
--         PlayerData.CastBehavior.CanPierceFunction = PlayerData.CanPierce;

--         PlayerData.Caster:Fire(
--             PlayerData.MuzzleWorldPosition,
--             newDirection,
--             newDirection * CasterConfig.BulletSpeed,
--             PlayerData.CastBehavior
--         );
--     end

--     ServerWeaponManager.PlayerWeapons[Player].OnRayHit = function(cast, raycastResult, segmentVelocity, cosmeticBulletObject)
--         -- This function will be connected to the Caster's "RayHit" event.
--         local hitPart = raycastResult.Instance;
--         local hitPoint = raycastResult.Position;
--         local normal = raycastResult.Normal;

--         if hitPart ~= nil and hitPart.Parent ~= nil then -- Test if we hit something
--             local humanoid = hitPart.Parent:FindFirstChildOfClass("Humanoid") -- Is there a humanoid?
--             if (humanoid and not not ServerWeaponManager.PlayerWeapons[Player].Hit[humanoid]) then
--                 ServerWeaponManager.PlayerWeapons[Player].Hit[humanoid] = true;
--                 OnRayHit(humanoid, ServerWeaponManager.PlayerWeapons[Player].CasterConfig, PlayerData.MuzzleWorldPosition, hitPart, hitPoint);
--             end
--             Events:WaitForChild("BloodEffect"):FireAllClients(hitPoint, ServerWeaponManager.PlayerWeapons[Player].Config.BloodType or "a", Config.BloodSettings);
--         end
--     end

--     ServerWeaponManager.PlayerWeapons[Player].OnRayPierced = function(cast, raycastResult, segmentVelocity, cosmeticBulletObject)
--         -- You can do some really unique stuff with pierce behavior - In reality, pierce is just the module's way of asking "Do I keep the bullet going, or do I stop it here?"
--         -- You can make use of this unique behavior in a manner like this, for instance, which causes bullets to be bouncy.
--         local position = raycastResult.Position
        
--         -- It's super important that we set the cast's position to the ray hit position. Remember: When a pierce is successful, it increments the ray forward by one increment.
--         -- If we don't do this, it'll actually start the bounce effect one segment *after* it continues through the object, which for thin walls, can cause the bullet to almost get stuck in the wall.
--         cast:SetPosition(position)

--         if (ServerWeaponManager.PlayerWeapons[Player].Config.OnRayHit) then
--             ServerWeaponManager.PlayerWeapons[Player].Config.OnRayHit(raycastResult);
--         end
        
--         -- Generally speaking, if you plan to do any velocity modifications to the bullet at all, you should use the line above to reset the position to where it was when the pierce was registered.
--     end

--     ServerWeaponManager.PlayerWeapons[Player].OnRayUpdated = function(cast, segmentOrigin, segmentDirection, length, segmentVelocity, cosmeticBulletObject)
--         -- Whenever the caster steps forward by one unit, this function is called.
--         -- The bullet argument is the same object passed into the fire function.
--         if cosmeticBulletObject == nil then return end
--         local bulletLength = cosmeticBulletObject.Size.Z / 2 -- This is used to move the bullet to the right spot based on a CFrame offset
--         local baseCFrame = CFrame.new(segmentOrigin, segmentOrigin + segmentDirection)
--         cosmeticBulletObject.CFrame = baseCFrame * CFrame.new(0, 0, -(length - bulletLength))
--         -- cosmeticBulletObject:FindFirstChildWhichIsA("Trail").Enabled = true;
--     end

--     ServerWeaponManager.PlayerWeapons[Player].OnRayTerminated = function(cast)
--         local cosmeticBullet = cast.RayInfo.CosmeticBulletObject
--         if cosmeticBullet ~= nil then
--             -- This code here is using an if statement on CastBehavior.CosmeticBulletProvider so that the example gun works out of the box.
--             -- In your implementation, you should only handle what you're doing (if you use a PartCache, ALWAYS use ReturnPart. If not, ALWAYS use Destroy.
--             if CastBehavior.CosmeticBulletProvider ~= nil then
--                 CastBehavior.CosmeticBulletProvider:ReturnPart(cosmeticBullet)
--             else
--                 cosmeticBullet:Destroy()
--             end
--         end
--     end

--     Caster.RayHit:Connect(ServerWeaponManager.PlayerWeapons[Player].OnRayHit);
--     Caster.RayPierced:Connect(ServerWeaponManager.PlayerWeapons[Player].OnRayPierced);
--     Caster.LengthChanged:Connect(ServerWeaponManager.PlayerWeapons[Player].OnRayUpdated);
--     Caster.CastTerminating:Connect(ServerWeaponManager.PlayerWeapons[Player].OnRayTerminated);

--     ServerWeaponManager.PlayerWeapons[Player].Caster = Caster;
--     ServerWeaponManager.PlayerWeapons[Player].CastBehavior = CastBehavior;

--     for _, Animation in ipairs(Weapon:WaitForChild("ServerAnimations"):GetChildren()) do
--         LoadedAnimations[Player] = LoadedAnimations[Player] or {};
        
--         if (LoadedAnimations[Player][Animation.AnimationId]) then
--             print("Animation cached");
--             ServerWeaponManager.PlayerWeapons[Player].LoadedAnimations[Animation.Name] = LoadedAnimations[Player][Animation.AnimationId];
--         else
--             print("Animation loaded");
--             local LoadedAnimation = Player.Character:WaitForChild("Humanoid"):LoadAnimation(Animation);
--             ServerWeaponManager.PlayerWeapons[Player].LoadedAnimations[Animation.Name] = LoadedAnimation;
--             LoadedAnimations[Player][Animation.AnimationId] = LoadedAnimation;
--         end
--     end

--     Weapon.Name = Player.Name;
--     local cur = workspace.Weapons:FindFirstChild(Player.Name);
--     if (cur) then cur:Destroy(); end;

--     Weapon.Parent = workspace.Weapons;

--     if (not Player.Character:WaitForChild("RightHand"):FindFirstChild("Weapon")) then
--         local Motor6D = Instance.new("Motor6D");
--         Motor6D.Part1 = Player.Character.RightHand;
--         Motor6D.Name = "Weapon";

--         Motor6D.Parent = Player.Character.RightHand;
--     end

--     Player.Character:WaitForChild("RightHand"):FindFirstChild("Weapon").Part1 = Weapon:WaitForChild("Handle");

--     ServerWeaponManager.PlayerWeapons[Player].LoadedAnimations.Idle:Play();

--     -- game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("WeaponMade"):FireClient(Player, Weapon);

--     return 200, Weapon;
-- end

-- function ServerWeaponManager.Client:Aiming(Player, State:boolean)
--     if (not ServerWeaponManager.PlayerWeapons[Player]) then return; end;

--     ServerWeaponManager.PlayerWeapons[Player].Aiming = State;

--     if (State == true) then
--         ServerWeaponManager.PlayerWeapons[Player].LoadedAnimations.Aiming:Play(.3);
--     else
--         ServerWeaponManager.PlayerWeapons[Player].LoadedAnimations.Aiming:Stop(.3);
--     end
-- end

-- local function PlaySound(Parent:Instance, Sound:Sound):Sound|nil
--     if (not Sound or not Parent) then return; end;
    
--     Sound = Sound:Clone();
--     Sound.Parent = Parent;
    
--     Sound:Play();

--     Sound.Stopped:Connect(function()
--         Sound:Destroy();
--     end)

--     return Sound;
-- end

-- function ServerWeaponManager:Start()
--     local RunService = game:GetService("RunService");
--     local Data = {};

--     game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("Get/Post__").OnServerEvent:Connect(function(Player, MuzzlePosition, Direction)
--         Data[Player] = {MuzzlePosition, Direction};
--     end);

--     game:GetService("Players").PlayerAdded:Connect(coroutine.wrap(function(Player)
--         LoadedAnimations[Player] = {};
--         Player.CharacterAdded:Connect(function(Character)
--             Character:WaitForChild("Humanoid").Died:Connect(function()
--                 table.clear(LoadedAnimations[Player]);
--             end)
--         end)
--     end))

--     RunService.Heartbeat:Connect(function()
--         for Player, PlayerData in pairs(ServerWeaponManager.PlayerWeapons) do
--             if (PlayerData.AutomaticFiring) then
--                 game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("Get/Post__"):FireClient(Player);

--                 local waiting = 0;
--                 repeat waiting += 1; RunService.Heartbeat:Wait();
--                 until waiting > 60 or Data[Player];

--                 if (waiting < 60) then
--                     self.Client:Fire(Player, Data[Player][1], Data[Player][2]);
--                 end

--                 Data[Player] = nil;
--                 waiting = nil;
--             end
--         end
--     end)
-- end

-- function ServerWeaponManager.Client:SetAutomaticFiring(Player, State)
--     local PlayerData = ServerWeaponManager.PlayerWeapons[Player];
--     if (not PlayerData) then return; end;

--     PlayerData.AutomaticFiring = State;

--     ServerWeaponManager.PlayerWeapons[Player] = PlayerData;
-- end

-- function ServerWeaponManager.Client:Fire(Player, MuzzleWorldPosition, Direction)
--     local PlayerData = ServerWeaponManager.PlayerWeapons[Player];
--     if (not PlayerData) then return; end;

--     local LastFired = PlayerData.LastFired;
--     PlayerData.LastFired = not LastFired and 0 or LastFired;
--     LastFired = not LastFired and 0 or LastFired;

--     if ((os.clock() - LastFired) < (60/PlayerData.Config.FireRate)) then
--         return;
--     end

--     if (not MuzzleWorldPosition or not Direction) then warn("no", MuzzleWorldPosition, Direction); return; end;

--     ServerWeaponManager.PlayerWeapons[Player].MuzzleWorldPosition = MuzzleWorldPosition;
-- 	-- local mouseDirection = (MousePoint - MuzzleWorldPosition).Unit;
-- 	for i = 1, PlayerData.CasterConfig.BulletsPerShot do
-- 		PlayerData.Fire(Direction);
-- 	end

--     PlayerData.LastFired = os.clock();
--     PlayerData.FireIteration = not self.FireIteration and 1 or self.FireIteration + 1;

--     for _, ParticleEmitter:ParticleEmitter|Light in ipairs(PlayerData.Weapon.Handle:WaitForChild("Muzzle"):GetChildren()) do
--         if (ParticleEmitter:IsA("ParticleEmitter")) then
--             ParticleEmitter:Emit(ParticleEmitter:GetAttribute("Emit"));
--         elseif (ParticleEmitter:IsA("Light")) then
--             ParticleEmitter.Enabled = true;
--         end
--     end

--     local CurrentIteration = PlayerData.FireIteration;
--     delay(.15, function()
--         if (CurrentIteration ~= PlayerData.FireIteration) then return; end;

--         for _, Light:Light in ipairs(PlayerData.Weapon.Handle:WaitForChild("Muzzle"):GetChildren()) do
--             if (Light:IsA("Light")) then
--                 Light.Enabled = false;
--             end
--         end
--     end)

--     PlaySound(PlayerData.Weapon.Handle.Muzzle, PlayerData.Weapon.Sounds.Fire);

--     ServerWeaponManager.PlayerWeapons[Player] = PlayerData;
-- end

-- return ServerWeaponManager

return {}