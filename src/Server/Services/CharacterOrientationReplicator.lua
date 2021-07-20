-- Character Orientation Replicator
-- Deter
-- July 12, 2021



local CharacterOrientationReplicator = {Client = {}};

function CharacterOrientationReplicator:Start()
	local PlayerService = game:GetService("Players");

	PlayerService.PlayerAdded:Connect(function(Player)
		coroutine.wrap(function()
			local Part = Instance.new("Part");
			Part.CanCollide = false;
			Part.Size = Vector3.new(2, 2, 2);
			Part.Position = Vector3.new(0, 50, 0);
			Part.Name = Player.UserId;
			Part.Parent = workspace:WaitForChild("CharacterOrientations");

			Part:SetNetworkOwner(Player);
		end)();
	end)
end

function CharacterOrientationReplicator:Init() end;

-- function CharacterOrientationReplicator.Client:GetOrientationPart(Player:Player)
	
-- end

return CharacterOrientationReplicator;