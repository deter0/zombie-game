local ReplicatedStorage = game:GetService("ReplicatedStorage");
local Shared = ReplicatedStorage:WaitForChild("Aero"):WaitForChild("Shared");

local Thread = require(Shared:WaitForChild("Thread"));
local Signal = require(Shared:WaitForChild("Signal"));

local ImageSequencePlayer = {};

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

function ImageSequencePlayer:Play(Target, Interval:number, Images, Delays, COLOR)
	local Player = {
		Loaded = Signal.new(),
		Finished = Signal.new(),
		Stop = function(self)
			self.Loop = self.Loop and self.Loop:Disconnect() and nil;
			self.Loaded:DisconnectAll();
			self.Loaded:Destroy();
			self.Finished:DisconnectAll();
			self.Finished:Destroy();
			for _, v in ipairs(self.ImageLabels) do v:Destroy(); end;
			table.clear(self);
			warn("Stopped gif player");
		end
	};

	Thread.Spawn(function()
		local ImageLabels = {};
		warn(Images);
		
		for index, Image in ipairs(Images) do
			if (index % 50 == 0) then wait(.1); end;

			local ImageLabel = Instance.new("ImageLabel");
			ImageLabel.Size = UDim2.new(1, 0, 1, 0);
			ImageLabel.Image = Image;
			ImageLabel.ImageColor3 = Target.ImageColor3 or Color3.new(1,1,1);
			ImageLabel.Visible = true;
			ImageLabel.Name = Image;
			ImageLabel.Parent = Target;
			ImageLabel.BackgroundTransparency = 1;
			ImageLabel.ScaleType = Enum.ScaleType.Fit;
			
			ImageLabels[index] = ImageLabel;
		end
		
		-- local Images = {};
		-- local InsertService = game:GetService("InsertService");
		-- local function getImageIdFromDecal(decalId)
		-- 	local decal = InsertService:LoadAsset(decalId):FindFirstChildWhichIsA("Decal")
		-- 	return decal.Texture
		-- end

		-- local Decal = workspace.DecalPart.Decal;
		-- local Animation = require(game.ReplicatedStorage.Aero.Shared.Animations.Logo);
		-- for _, image in ipairs(Animation) do
		-- 	local ids = tonumber(string.match(image, "%d+"));
		-- 	table.insert(Images, getImageIdFromDecal(ids));
		-- end
		-- local str = "";
		-- for i, v in ipairs(Images) do
		-- 	str ..= "\""..v.."\",\n";
		-- end
		-- print(str);

		local LastFrameInterval = 0;
		local CurrentIndex = 1;
		local CurrentImg;

		local half = {};
		local otherHalf = {};

		for i, v in ipairs(ImageLabels) do
			if (i < #ImageLabels/2) then
				half[#half + 1] = v;
			else
				otherHalf[#otherHalf + 1] = v;
			end
		end

		ContentProvider:PreloadAsync(half);
		wait(2);
		ContentProvider:PreloadAsync(otherHalf);
		Player.ImageLabels = ImageLabels;

		Player.Loaded:Fire();
		Player.DidLoad = true;

		Player.Loop = RunService.Heartbeat:Connect(function()
			if (Player.DidLoad and (time() - LastFrameInterval) > (Interval + (Delays[CurrentIndex] or 0))) then
				CurrentIndex += 1;
				CurrentIndex = (CurrentIndex % #Images) + 1;
				if ((CurrentIndex %#Images) + 1 == #Images) then
					Player.Finished:Fire();
				end
				
				for _, Image in ipairs(ImageLabels) do
					Image.Visible = false;
				end
				
				if (CurrentImg) then CurrentImg.Visible = false; end;
				
				if (ImageLabels[CurrentIndex]) then
					ImageLabels[CurrentIndex].Visible = true;
					CurrentImg = ImageLabels[CurrentIndex];
				end

				LastFrameInterval = time();
			end
		end)
	end)

	return Player;
end

function ImageSequencePlayer:PlaySpriteSheet(Target:ImageLabel, Interval:number, SpriteSheetId:string, TileSize:Vector2, Tiles:number, NumOfTiles:number, Row:number, Column) -- ! Doesn't work/ incomplete
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