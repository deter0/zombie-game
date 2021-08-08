-- Ammo Gui Controller
-- deter
-- July 30, 2021

local ReplicatedStorage = game:GetService("ReplicatedStorage");
local Shared = ReplicatedStorage:WaitForChild("Aero"):WaitForChild("Shared");

local Base64 = require(Shared:WaitForChild("Base64"));

local PlayerService = game:GetService("Players");
local Player = PlayerService.LocalPlayer;

local AmmoGuiController = {}

function AmmoGuiController:Start()
	if (true) then return; end;
	
	local PlayerGui = Player:WaitForChild("PlayerGui");
	local AmmoScreenGui:ScreenGui = PlayerGui:WaitForChild("Ammo");
	local AmmoGuiContainer:Frame = AmmoScreenGui:WaitForChild("Container");

	local AmmoIcon:ImageLabel = AmmoGuiContainer:WaitForChild("AmmoIcon");
	local AmmoText:TextLabel = AmmoGuiContainer:WaitForChild("AmmoText");

	self.AmmoIcon = AmmoIcon;
	self.AmmoText = AmmoText;

	self:Reloading(false);

	self.AmmoDirectory = ReplicatedStorage:WaitForChild("Ammo"):WaitForChild(Player.Name, 5); --!

	self:Update();
	
	for _, IntValue:IntValue in ipairs(self.AmmoDirectory:GetChildren()) do
		IntValue.Changed:Connect(function()
			self:Update();
		end);
	end
end

local function GetFormattedString(String:string|number):string
	return string.rep("0", math.min(3-#tostring(string.sub(String, 1, 3)), 0))..String
end

function AmmoGuiController:Update()
	local CurrentAmmo = self.AmmoDirectory:WaitForChild("InClip").Value;
	local AmmoRemaining = self.AmmoDirectory:WaitForChild("Reserve").Value;

	local CurrentAmmoText = GetFormattedString(CurrentAmmo);
	local AmmoRemainingText = GetFormattedString(AmmoRemaining);

	local AmmoText:string = string.format("%s %s", CurrentAmmoText, AmmoRemainingText);

	self.AmmoText.Text = AmmoText;
end

function AmmoGuiController:Reloading(State:boolean):nil
	self.Reloading = State;

	self.AmmoIcon.ImageTransparency = self.Reloading and 0.5 or 0;
	self.AmmoText.TextTransparency = self.Reloading and 0.5 or 0;
	self.AmmoText.TextStrokeTransparency = self.Reloading and 0.9 or 0.8;
end

return AmmoGuiController