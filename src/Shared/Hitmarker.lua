local ReplicatedStorage = game:GetService("ReplicatedStorage");

local HitMarkerFolder = ReplicatedStorage:WaitForChild("Hitmarker");

local HitMarker = {};

function HitMarker:Hit(Position:Vector3, Damage:number?) --TODO(deter): improve hitmarkers and make them look less shitty.
	local HitMarkerAttachment = HitMarkerFolder:WaitForChild("HitmarkerContainer"):WaitForChild("Hitmarker"):Clone();
	HitMarkerAttachment.WorldPosition = Position + Vector3.new(math.random(), 5, math.random());
	HitMarkerAttachment:WaitForChild("HitmarkerGUI"):WaitForChild("Damage").Text = tostring(math.floor(Damage + .5)) or "";

	HitMarkerAttachment.Parent = workspace:WaitForChild("Hitmarkers");

	local HitmarkerSound = HitMarkerFolder:WaitForChild("HitmarkerSound"):Clone();
	HitmarkerSound.Parent = HitMarkerFolder;

	HitmarkerSound:Play();

	HitmarkerSound.Stopped:Connect(function()
		HitmarkerSound:Destroy();
	end)

	delay(1, function()
		HitMarkerAttachment:Destroy();
	end)
end

return HitMarker;