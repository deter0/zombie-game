local LoadingScreen = {
	WaitForLoad = {
		"Controllers/FPSFramework",
	},
	States = {
		"Waiting for game",
		"Getting services",
		"Loading loading screen",
		"Loading loading screen gif",
		"Presenting logos",
		"Waiting for fps framework",
		"Loading materials",
		"Finalizing"
	},
	CompletedStates = {},

	LoadingAnimation = nil
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
	self.GifPlayer.AnchorPoint = Vector2.new(0.5, 0.5);
	self.GifPlayer.Position = UDim2.fromScale(0.5, 0.5);
	self.GifPlayer.Size = UDim2.fromOffset(800, 400);
	self.GifPlayer.ImageColor3 = Color3.new(1, 1, 1);
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

local VERY_FAR = Vector3.new(1e8, 1e8, 1e8);
function LoadingScreen:Start()
	if (_G.LoadingScreenActive) then
		return;
	end

	local ReplicatedFirst = game:GetService("ReplicatedFirst");
	ReplicatedFirst:RemoveDefaultLoadingScreen();

	_G.LoadingScreenActive = true;
	self.Controllers.Fade:Out(0);

	self:BuildGUI();

	local ReplicatedStorage = game:GetService("ReplicatedStorage");
	local Shared = ReplicatedStorage:WaitForChild("Aero"):WaitForChild("Shared");

	coroutine.resume(coroutine.create(function()
		repeat RunService.Heartbeat:Wait();
			workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable;
			workspace.CurrentCamera.CFrame = CFrame.new(VERY_FAR);
			workspace.CurrentCamera.Focus = workspace.CurrentCamera.CFrame;
		until self.Finished;

		workspace.CurrentCamera.CameraType = Enum.CameraType.Custom;
	end));

	self:StartProgressBarUpdates();

	self:SetLoadingState("Waiting for game");

	if (not game:IsLoaded()) then
		game.Loaded:Wait();
	end

	self:SetLoadingState("Loading loading screen");

	wait(4);
	self.LoadingAnimation = require(Shared:WaitForChild("Animations"):WaitForChild("Logo"));
	local GifPlayer = self.Controllers.ImageSequencePlayer:Play(self.GifPlayer, .04, self.LoadingAnimation, {[1] = 1.5, [#self.LoadingAnimation] = 5});

	self:SetLoadingState("Loading loading screen gif");

	if (not RunService:IsStudio()) then
		GifPlayer.Loaded:Wait();
	end

	self:SetLoadingState("Presenting logos");

	GifPlayer.Finished:Wait();

	self:SetLoadingState("Waiting for fps framework");

	if (not self.Controllers.FPSFramework.IsLoaded) then
		self.Controllers.FPSFramework.Loaded:Wait();
	end

	self:SetLoadingState("Loading materials");
	wait(.25);

	local ContentProvider = game:GetService("ContentProvider");

	local ToLoad = {};

	for _, ToLoadInstance:Instance in ipairs(ReplicatedStorage:WaitForChild("ToLoad"):GetChildren()) do
		ToLoad[#ToLoad + 1] = ToLoadInstance;
	end

	ContentProvider:PreloadAsync(ToLoad);

	self:SetLoadingState("Finalizing");

	if (not RunService:IsStudio()) then
		wait(4);
	end

	self:SetLoadingState(nil);
	GifPlayer:Stop();
	self.LoadingScreenGui:Destroy();
	self.Controllers.Fade:In(1.5);
	self.Finished = true;
	self.LoadingAnimation = nil;
end

return LoadingScreen;