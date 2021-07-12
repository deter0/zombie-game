local CharacterHandler = {};

function CharacterHandler:Start()
	local PlayerService = game:GetService("Players");
	local CollectionService = game:GetService("CollectionService");

	local CharacterTags = {"NotCollidable"};

	PlayerService.PlayerAdded:Connect(function(Player)
		coroutine.wrap(function()
			Player.CharacterAdded:Connect(function(Character)
				for _, Tag in ipairs(CharacterTags) do
					CollectionService:AddTag(Character, Tag);
				end
			end)
		end)();
	end)
end

return CharacterHandler;