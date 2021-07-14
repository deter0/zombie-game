local ReplicatedStorage = game:GetService("ReplicatedStorage");
local Shared = ReplicatedStorage:WaitForChild("Aero"):WaitForChild("Shared");

local Thread = require(Shared:WaitForChild("Thread"));

local ImageSequencePlayer = {};

-- function ImageSequencePlayer:Start()
	-- local LoadingScreen = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("LoadingScreen");

	-- self:Play(
	-- 	LoadingScreen:WaitForChild("Background"):WaitForChild("Player"), .05, {
	-- 		"rbxassetid://7092418991",
	-- 		"rbxassetid://7092418885",
	-- 		"rbxassetid://7092418800",
	-- 		"rbxassetid://7092418720",
	-- 		"rbxassetid://7092418654",
	-- 		"rbxassetid://7092418580",
	-- 		"rbxassetid://7092418501",
	-- 		"rbxassetid://7092418441",
	-- 		"rbxassetid://7092418376",
	-- 		"rbxassetid://7092418282",
	-- 		"rbxassetid://7092418207",
	-- 		"rbxassetid://7092418129",
	-- 		"rbxassetid://7092418043",
	-- 		"rbxassetid://7092417974",
	-- 		"rbxassetid://7092417886",
	-- 		"rbxassetid://7092417789",
	-- 		"rbxassetid://7092417687",
	-- 		"rbxassetid://7092417623",
	-- 		"rbxassetid://7092417555",
	-- 		"rbxassetid://7092417489",
	-- 		"rbxassetid://7092417417",
	-- 		"rbxassetid://7092417343",
	-- 		"rbxassetid://7092417252"
	-- 	}
	-- )
-- end

--[[
	{
	"rbxassetid://7092418991",
	"rbxassetid://7092418885",
	"rbxassetid://7092418800",
	"rbxassetid://7092418720",
	"rbxassetid://7092418654",
	"rbxassetid://7092418580",
	"rbxassetid://7092418501",
	"rbxassetid://7092418441",
	"rbxassetid://7092418376",
	"rbxassetid://7092418282",
	"rbxassetid://7092418207",
	"rbxassetid://7092418129",
	"rbxassetid://7092418043",
	"rbxassetid://7092417974",
	"rbxassetid://7092417886",
	"rbxassetid://7092417789",
	"rbxassetid://7092417687",
	"rbxassetid://7092417623",
	"rbxassetid://7092417555",
	"rbxassetid://7092417489",
	"rbxassetid://7092417417",
	"rbxassetid://7092417343",
	"rbxassetid://7092417252"
}
]]

local RunService = game:GetService("RunService");
local ContentProvider = game:GetService("ContentProvider");

function ImageSequencePlayer:Play(Target, Intervel:number, Images)
	Thread.Spawn(function()
		local ImageLabels = {};
		ContentProvider:PreloadAsync(Images);

		for index, Image in ipairs(Images) do
			local ImageLabel = Instance.new("ImageLabel");
			ImageLabel.Size = UDim2.new(1, 0, 1, 0);
			ImageLabel.Image = Image;
			ImageLabel.Visible = false;
			ImageLabel.Parent = Target;
			ImageLabel.BackgroundTransparency = 1;

			ImageLabels[index] = ImageLabel;
		end


		local LastFrameInterval = 0;
		local CurrentIndex = 1;
		local CurrentImg;

		RunService.Heartbeat:Connect(function(DeltaTime)
			if ((tick() - LastFrameInterval) > Intervel) then
				CurrentIndex += 1;
				CurrentIndex = (CurrentIndex % #Images) + 1;

				if (CurrentImg) then CurrentImg.Visible = false; end;

				if (ImageLabels[CurrentIndex]) then
					ImageLabels[CurrentIndex].Visible = true;
					CurrentImg = ImageLabels[CurrentIndex];
				end

				LastFrameInterval = tick();
			end
		end)
	end)
end

return ImageSequencePlayer;