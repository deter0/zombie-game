local Debris = game:GetService("Debris");
local ReplicatedStorage = game:GetService("ReplicatedStorage");

local HitMarkerFolder = ReplicatedStorage:WaitForChild("Hitmarker");
local HitMarkerPart = workspace:WaitForChild("HitmarkerPart");

local Delete = {};
local HitMarker = {};

local TweenService = game:GetService("TweenService");

local FadeOutTweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Cubic, Enum.EasingDirection.InOut, 0, false, 0.1);

function HitMarker:Hit(Position:Vector3, Damage:number?, Character:Model) --TODO(deter): improve hitmarkers and make them look less shitty.
	if (Character:FindFirstChild("Head")) then
		local DamageGui = Character.Head:FindFirstChild("Damage") or HitMarkerFolder:WaitForChild("Damage"):Clone();

		local CurrentDamage:number = tonumber(DamageGui:WaitForChild("TextLabel").Text);
		local NewDamage:number = (CurrentDamage or 0) + Damage;
		DamageGui.TextLabel.Text = math.round(NewDamage);

		DamageGui.Parent = Character:FindFirstChild("Head");
		Delete[DamageGui] = time();
	end

	local HitmarkerSound = HitMarkerFolder:WaitForChild("HitmarkerSound"):Clone();
	HitmarkerSound.Parent = HitMarkerFolder;

	HitmarkerSound:Play();

	HitmarkerSound.Stopped:Connect(function()
		HitmarkerSound:Destroy();
	end)

	local HitPoint:Attachment = HitMarkerPart:WaitForChild("Hit"):Clone();
	HitPoint.WorldPosition = Position;

	HitPoint.Parent = HitMarkerPart;

	local Fadeout = TweenService:Create(HitPoint:FindFirstChildWhichIsA("BillboardGui"):FindFirstChildWhichIsA("Frame"), FadeOutTweenInfo, {Size = UDim2.fromOffset(0, 0)});
	Fadeout:Play();

	local Completed; Completed = Fadeout.Completed:Connect(function()
		Completed = nil;
		Fadeout:Destroy();
	end)

	-- local HitMarkerAttachment = HitMarkerFolder:WaitForChild("HitmarkerContainer"):WaitForChild("Hitmarker"):Clone();
	-- HitMarkerAttachment.WorldPosition = Position + Vector3.new(math.random(), 5, math.random());
	-- HitMarkerAttachment:WaitForChild("HitmarkerGUI"):WaitForChild("Damage").Text = tostring(math.floor(Damage + .5)) or "";

	-- HitMarkerAttachment.Parent = workspace:WaitForChild("Hitmarkers");

	-- delay(1, function()
	-- 	HitMarkerAttachment:Destroy();
	-- end)
end

function HitMarker:Start()
	task.spawn(function()
		while (true) do
			for Item:Instance, LastTimeUpdated:number in pairs(Delete) do
				if ((time() - LastTimeUpdated) >= 5) then
					Item:Destroy();
					Delete[Item] = nil;
				end
			end

			wait(3);
		end
	end)
end

return HitMarker;