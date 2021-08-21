local CollectionService = game:GetService("CollectionService");
local GameSettings = UserSettings().GameSettings;
local TreeQuality = {
	HigherQualityParts = {},
	Scheduled = 3,
};

function TreeQuality:Start()
	GameSettings:GetPropertyChangedSignal("SavedQualityLevel"):Connect(function() self:QualityChanged(); end);

	while true do
		if (self.Scheduled and self.Scheduled <= time()) then
			self.Scheduled = nil;
			self:Update();
		end

		task.wait(1);
	end
end

function TreeQuality:QualityChanged()
	self.Scheduled = time() + 5;
end

function TreeQuality:Update()
	self.Quality = GameSettings.SavedQualityLevel.Value;
	local NewTreeQuality = self.Quality < 5 and 0 or self.Quality < 8 and 1 or self.Quality <= 10 and 2;

	if (NewTreeQuality ~= self.CurrentTreeQuality) then
		self.CurrentTreeQuality = NewTreeQuality;
		for _, v in ipairs(self.HigherQualityParts) do
			v:Destroy();
		end
		table.clear(self.HigherQualityParts);

		for _, WindPart in ipairs(CollectionService:GetTagged("WindShake")) do
			if (not WindPart:GetAttribute("NotLeaves")) then
				for _ = 1, self.CurrentTreeQuality do
					local WindPartClone = WindPart:Clone();
					WindPartClone.Orientation += Vector3.new(
						math.random(12)-6,
						(math.random() - 0.5) * (WindPart:GetAttribute("LeavesRandomness") or 360),
						math.random(12)-6
					);
					WindPartClone.CastShadow = false;
					WindPartClone.Parent = WindPart.Parent;

					self.HigherQualityParts[#self.HigherQualityParts + 1] = WindPartClone;
				end
			end
		end
	end
end

return TreeQuality;