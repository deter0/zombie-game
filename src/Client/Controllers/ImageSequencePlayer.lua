local ReplicatedStorage = game:GetService("ReplicatedStorage");
local Shared = ReplicatedStorage:WaitForChild("Aero"):WaitForChild("Shared");

local Thread = require(Shared:WaitForChild("Thread"));

local ImageSequencePlayer = {};
local Anim = {
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


local Delays_ = {
	[1] = .3,
};

-- for i = 26, 37 do
-- 	Delays_[i] = .1;
-- end

-- function ImageSequencePlayer:Start()
-- 	local LoadingScreen = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("LoadingScreen");

-- 	-- self:PlaySpriteSheet(LoadingScreen:WaitForChild("Background"):WaitForChild("Player"), .15, "rbxassetid://7096473218", Vector2.new(194, 194), 5, 23, 5, 6);

-- 	self:Play(
-- 		LoadingScreen:WaitForChild("Background"):WaitForChild("Player"), .08, Anim, Delays_
-- 	)
-- end


local RunService = game:GetService("RunService");
local ContentProvider = game:GetService("ContentProvider");

function ImageSequencePlayer:Play(Target, Intervel:number, Images, Delays)
	Thread.Spawn(function()
		local ImageLabels = {};
		warn(Images);
		
		for index, Image in ipairs(Images) do
			local ImageLabel = Instance.new("ImageLabel");
			ImageLabel.Size = UDim2.new(1, 0, 1, 0);
			ImageLabel.Image = Image;
			ImageLabel.Visible = true;
			ImageLabel.Name = Image;
			ImageLabel.Parent = Target;
			ImageLabel.BackgroundTransparency = 1;
			ImageLabel.ScaleType = Enum.ScaleType.Fit;
			
			ImageLabels[index] = ImageLabel;
		end
		
		
		local LastFrameInterval = 0;
		local CurrentIndex = 1;
		local CurrentImg;

		ContentProvider:PreloadAsync(ImageLabels);
		
		RunService.Heartbeat:Connect(function()
			if ((tick() - LastFrameInterval) > (Intervel + (Delays[CurrentIndex] or 0))) then
				CurrentIndex += 1;
				CurrentIndex = (CurrentIndex % #Images) + 1;
				
				for _, Image in ipairs(ImageLabels) do
					Image.Visible = false;
				end
				
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

function ImageSequencePlayer:PlaySpriteSheet(Target:ImageLabel, Interval:number, SpriteSheetId:string, TileSize:Vector2, Tiles:number, NumOfTiles:number, Row:number, Column)
	Target.ImageRectSize = TileSize;
	
	ContentProvider:PreloadAsync({SpriteSheetId});

	Thread.Spawn(function()
		while (true) do
			local y = 0;
			for i = 1, NumOfTiles do
				local x = (i % Column) + 1;
				if (x >= Row) then y += 1; end;

				Target.ImageRectOffset = Vector2.new(x * TileSize.X, y * TileSize.Y);

				wait(Interval);
			end
		end
	end)
end

return ImageSequencePlayer;