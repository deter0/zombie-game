local LoadingScreen = {
	WaitForLoad = {
		"Controllers/FPSFramework",
	},
	States = {
		"Waiting for game",
		"Getting services",
		"Loading loading screen",
		"Loading loading screen gif",
		"Waiting for fps framework",
		"Loading materials",
		"Finalizing"
	},
	CompletedStates = {},

	LoadingAimation = {
		"rbxassetid://7096641655",
		"rbxassetid://7096638713",
		"rbxassetid://7096637697",
		"rbxassetid://7096637602",
		"rbxassetid://7096637496",
		"rbxassetid://7096637400",
		"rbxassetid://7096637336",
		"rbxassetid://7096637265",
		"rbxassetid://7096637110",
		"rbxassetid://7096637019",
		"rbxassetid://7096636953",
		"rbxassetid://7096636861",
		"rbxassetid://7096636778",
		"rbxassetid://7096636699",
		"rbxassetid://7096636601",
		"rbxassetid://7096636515",
		"rbxassetid://7096636445",
		"rbxassetid://7096636370",
		"rbxassetid://7096636275",
		"rbxassetid://7096636203",
		"rbxassetid://7096636140",
		"rbxassetid://7096636088",
		"rbxassetid://7096636020",
		"rbxassetid://7096635941",
		"rbxassetid://7096635836",
		"rbxassetid://7096635746",
		"rbxassetid://7096635676",
		"rbxassetid://7096635612",
		"rbxassetid://7096635545",
		"rbxassetid://7096635475",
		"rbxassetid://7096635395",
		"rbxassetid://7096635323",
		"rbxassetid://7096635234",
		"rbxassetid://7096635115",
		"rbxassetid://7096635017",
		"rbxassetid://7096634914",
		"rbxassetid://7096634817"
	}
};

function LoadingScreen:BuildGUI()
	self.LoadingScreenGui = Instance.new("ScreenGui");
	self.LoadingScreenGui.DisplayOrder = 10000;
	self.LoadingScreenGui.ResetOnSpawn = false;

	local BLACK = Color3.new(0, 0, 0);
	local WHITE = Color3.new(1, 1, 1);

	self.BackgroundGui = Instance.new("Frame");
	self.BackgroundGui.Size = UDim2.fromScale(1, 1);
	self.BackgroundGui.BorderSizePixel = 100;
	self.BackgroundGui.BackgroundColor3 = BLACK;
	self.BackgroundGui.BorderColor3 = BLACK;

	self.ProgressBar = Instance.new("Frame");
	self.ProgressBar.Size = UDim2.fromOffset(0, 2);
	self.ProgressBar.BorderSizePixel = 0;
	self.ProgressBar.Position = UDim2.fromScale(0, 1);
	self.ProgressBar.AnchorPoint = Vector2.new(0, 1);
	self.ProgressBar.ZIndex = 2;
	self.ProgressBar.BackgroundColor3 = WHITE;

	self.ProgressBarBackground = self.ProgressBar:Clone();
	self.ProgressBarBackground.ZIndex = 100;
	
	self.ProgressBarBackgroundGradient = Instance.new("UIGradient");
	self.ProgressBarBackgroundGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, .95),
		NumberSequenceKeypoint.new(.45, .9),
		NumberSequenceKeypoint.new(.5, .3),
		NumberSequenceKeypoint.new(.55, .9),
		NumberSequenceKeypoint.new(1, .95)
	});
	self.ProgressBarBackgroundGradient.Offset = Vector2.new(-1, 0);

	self.LoadingStateText = Instance.new("TextLabel");
	self.LoadingStateText.BackgroundTransparency = 1;
	self.LoadingStateText.Size = UDim2.new(.4, 0, 0, 15);
	self.LoadingStateText.AnchorPoint = Vector2.new(0, 1);
	self.LoadingStateText.Position = UDim2.new(0, 4, 1, -6);
	self.LoadingStateText.Font = Enum.Font.SourceSansBold;
	self.LoadingStateText.TextScaled = true;
	self.LoadingStateText.TextYAlignment = Enum.TextYAlignment.Bottom;
	self.LoadingStateText.TextXAlignment = Enum.TextXAlignment.Left;
	self.LoadingStateText.TextColor3 = WHITE;

	self.GifPlayer = Instance.new("ImageLabel");
	self.GifPlayer.ImageTransparency = 1;
	self.GifPlayer.BackgroundTransparency = 1;
	self.GifPlayer.AnchorPoint = Vector2.new(1, 1);
	self.GifPlayer.Position = UDim2.fromScale(1.02, 1.01);
	self.GifPlayer.Size = UDim2.fromScale(.215, .5);
	self.GifPlayer.ZIndex = 5;

	self.BackgroundGui.Parent = self.LoadingScreenGui;
	self.ProgressBar.Parent = self.BackgroundGui;
	self.ProgressBarBackground.Parent = self.BackgroundGui;
	self.ProgressBarBackgroundGradient.Parent = self.ProgressBarBackground;
	self.GifPlayer.Parent = self.BackgroundGui;
	self.LoadingStateText.Parent = self.BackgroundGui;

	self.LoadingScreenGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui");
end

function LoadingScreen:LoadingProgressUpdated()
	self.LoadingPercentage = #self.CompletedStates/#self.States;

	print(self.LoadingPercentage, self.CompletedStates, self.States);
end

function LoadingScreen:SetLoadingState(NewState:string)
	if (self.LoadingState) then
		self.CompletedStates[#self.CompletedStates+1] = self.LoadingState;
	end

	self.LoadingState = NewState;
	self.LoadingStateText.Text = (self.LoadingState or "Finished").."...";
	self:LoadingProgressUpdated();
end

local RunService = game:GetService("RunService");

function LoadingScreen:StartProgressBarUpdates()
	coroutine.resume(coroutine.create(function()
		RunService.RenderStepped:Connect(function(DeltaTime:number)
			self.ProgressBar.Size = self.ProgressBar.Size:Lerp(UDim2.new(self.LoadingPercentage or 0, 0, 0, 2), math.clamp(DeltaTime * 8, 0, 1));
		end)
	end))
end

function LoadingScreen:Start()
	if (_G.LoadingScreenActive) then
		return;
	end

	_G.LoadingScreenActive = true;
	self.Controllers.Fade:Out(0);

	self:BuildGUI();
	local ReplicatedFirst = game:GetService("ReplicatedFirst");
	ReplicatedFirst:RemoveDefaultLoadingScreen();

	self:StartProgressBarUpdates();

	self:SetLoadingState("Waiting for game");

	if (not game:IsLoaded()) then
		game.Loaded:Wait();
	end

	
	local ReplicatedStorage = game:GetService("ReplicatedStorage");
	local Shared = ReplicatedStorage:WaitForChild("Aero"):WaitForChild("Shared");

	self:SetLoadingState("Loading loading screen");

	local GifPlayer = self.Controllers.ImageSequencePlayer:Play(self.GifPlayer, .08, self.LoadingAimation, {.2});

	self:SetLoadingState("Loading loading screen gif");

	GifPlayer.Loaded:Wait();

	self:SetLoadingState("Waiting for fps framework");

	if (not self.Controllers.FPSFramework.IsLoaded) then
		self.Controllers.FPSFramework.Loaded:Wait();
	end

	self:SetLoadingState("Finalizing");

	if (not RunService:IsStudio()) then
		wait(4);
	end

	self:SetLoadingState("Loading materials");
	wait(.25);

	local ContentProvider = game:GetService("ContentProvider");

	local ToLoad = {};

	for _, ToLoadInstance:Instance in ipairs(ReplicatedStorage:WaitForChild("ToLoad"):GetChildren()) do
		ToLoad[#ToLoad + 1] = ToLoadInstance;
	end

	ContentProvider:PreloadAsync(ToLoad, function(id)
		print("Loaded", id);
	end);

	self:SetLoadingState(nil);
	GifPlayer:Stop();

	self.LoadingScreenGui.Enabled = false;
	self.Controllers.Fade:In(1.5);
end

return LoadingScreen;