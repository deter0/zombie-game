-- Indicator
-- deter
-- August 8, 2021

local Indicator = {};

function Indicator:Start()
	local Player = game:GetService("Players").LocalPlayer;
	local PlayerGui = Player:WaitForChild("PlayerGui");

	self.IndicatorGui = PlayerGui:WaitForChild("Indicator");

	self.GuiStorage = self.IndicatorGui:WaitForChild("Storage");
	self.GuiContainer = self.IndicatorGui:WaitForChild("Container");
end

local TweenService = game:GetService("TweenService");

local ExpandTweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Cubic, Enum.EasingDirection.InOut, 0, false, 0);
local BlinkTweenInfo = TweenInfo.new(0.075, Enum.EasingStyle.Cubic, Enum.EasingDirection.InOut, 3, true, 0.02);

function Indicator:Indicate(Message:string, ...)
	task.spawn(function(Message, ...)
		Message = string.format(Message, ...);

		local Gui = self.GuiStorage:WaitForChild("Indicator"):Clone();
		local TextLabel = Gui:WaitForChild("TextLabel");

		TextLabel.Text = Message;
		Gui.Size = UDim2.new(0, 0, .035, 0);

		Gui.Parent = self.GuiContainer;

		TextLabel.TextScaled = false;
		TextLabel.TextSize = Gui.AbsoluteSize.Y;

		local ExpandTween = TweenService:Create(Gui, ExpandTweenInfo, {Size = UDim2.new(1, 0, .035, 0)});
		ExpandTween:Play();

		ExpandTween.Completed:Wait();

		local BlinkTween = TweenService:Create(TextLabel, BlinkTweenInfo, {TextTransparency = 1});
		BlinkTween:Play();

		task.wait(2);

		local CollapseTween = TweenService:Create(Gui, ExpandTweenInfo, {Size = UDim2.new(0, 0, .035, 0)});
		CollapseTween:Play();
			
		CollapseTween.Completed:Wait();

		Gui:Destroy();
	end, Message, ...);
end

return Indicator;