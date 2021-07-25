local ReplicatedStorage = game:GetService("ReplicatedStorage");

local Shared = ReplicatedStorage:WaitForChild("Aero"):WaitForChild("Shared");
local Events = ReplicatedStorage:WaitForChild("Events");

local RunService = game:GetService("RunService")

local Base64 = require(Shared:WaitForChild("Base64"));
local BulletsDirectory = ReplicatedStorage:WaitForChild("Bullets");

local CollectionService = game:GetService("CollectionService");

local FiringHandler = {
	BulletsPerPlayer = 50,
};

function FiringHandler:GetBullets(Player:Player)
	local PlayerDirectory = Base64:Encode(tostring(Player.UserId));
	local PlayerBulletDirectory = BulletsDirectory:FindFirstChild(PlayerDirectory);

	
	if (not PlayerBulletDirectory) then
		PlayerBulletDirectory = Instance.new("Model");
		PlayerBulletDirectory.Name = PlayerDirectory;
		PlayerBulletDirectory.Parent = BulletsDirectory;
	end
	
	PlayerBulletDirectory.Parent = BulletsDirectory;
	CollectionService:AddTag(PlayerBulletDirectory, "PlayerBulletDirectory");
	
	local NumOfBullets = #PlayerBulletDirectory:GetChildren();
	
	local BulletsToHandle = self.BulletsPerPlayer - NumOfBullets;
	if (BulletsToHandle > 0) then
		for ind = 1, BulletsToHandle do
			local Bullet = self:CreateBullet();
			Bullet.Name = ind;
			CollectionService:AddTag(Bullet, "Bullet");
			Bullet.Parent = PlayerBulletDirectory;
			
			if (ind % 60 == 0) then
				wait(.1); -- Cool down
			end
		end
	else
		for _ = 1, BulletsToHandle do
			local Bullets = PlayerBulletDirectory:GetChildren();
			Bullets[#Bullets]:Destroy();
		end
	end
	
	return PlayerBulletDirectory;
end

local NEON = Enum.Material.Neon;
local YELLOW = Color3.new(1, 0.901960, 0.462745);
local VERY_FAR = Vector3.new(-1e6, 1e6, 0);

function FiringHandler:CreateBullet() -- ?
	local Bullet:Part = Instance.new("Part");

	Bullet.Size = Vector3.new(0.25, 0.25, 4.4);
	Bullet.Material = NEON;
	Bullet.Color = YELLOW;
	Bullet.Position = VERY_FAR;
	Bullet.CanCollide = false;
	CollectionService:AddTag(Bullet, "Bullet");

	return Bullet;
end

function FiringHandler:SetBullets(Player, BulletsContainer)
	if (CollectionService:HasTag(BulletsContainer, "PlayerBulletDirectory")) then
		BulletsContainer.Parent = workspace:WaitForChild("Bullets");

		for _, Bullet in ipairs(BulletsContainer:GetChildren()) do
			if (CollectionService:HasTag(Bullet, "Bullet")) then
				Bullet:SetNetworkOwner(Player);
			end
		end
	end
end

function FiringHandler:Start()
	-- * Event hookups

	local PlayerService = game:GetService("Players");

	PlayerService.PlayerAdded:Connect(function(Player)
		self:GetBullets(Player);
	end)

	local GetBulletsRemoteFunction:RemoteFunction = Events:WaitForChild("Bullets");
	GetBulletsRemoteFunction.OnServerInvoke = function(...)
		return self:SetBullets(...);
	end

	PlayerService.PlayerRemoving:Connect(coroutine.wrap(function(Player)
		local PlayerDirectory = Base64:Encode(tostring(Player.UserId));
		local PlayerBulletDirectory = workspace:WaitForChild("Bullets"):FindFirstChild(PlayerDirectory);
		PlayerBulletDirectory:Destroy();
	end));

	return;
end

return FiringHandler;