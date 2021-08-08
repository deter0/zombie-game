-- First Person Shadow
-- deter
-- August 2, 2021



local FirstPersonShadow = {}

function FirstPersonShadow:Start()
	local RunService = game:GetService("RunService");

	local Players = game:GetService("Players");
	local Player = Players.LocalPlayer;

	local Camera = workspace.CurrentCamera or workspace:WaitForChild("Camera");
	local CharacterParts = {};
	local Ignore = {["HumanoidRootPart"] = true}; -- Ignore these parts

	local FAR = Vector3.new(1e6, 1e6, 1e6); -- Create a very far constant
	Player.CharacterAdded:Connect(function(Character)
		for _, Part in ipairs(CharacterParts) do Part:Destroy(); end; -- Destroy all the parts inside the array
		table.clear(CharacterParts); -- Clear the array

		local function HandleCharacterChild(Child)
			if (Child:IsA("BasePart") and not Ignore[Child.Name]) then
				local Clone = Child:Clone();
				Clone:ClearAllChildren(); -- We don't care about the children
				Clone.Material = Enum.Material.ForceField; -- Set it's material to force field
				Clone.Transparency = -math.huge; -- Set the transparency to -inf
				Clone.CanCollide = false; -- So it doesn't fling us
				Clone.Position = FAR; -- Initially place it very far

				Clone.Parent = workspace; -- Set it's parent to the workspace
				CharacterParts[#CharacterParts + 1] = Clone; -- Insert it to the table
			end
		end
		table.foreachi(Character:GetChildren(), HandleCharacterChild); -- If there are existing parts inside the character
		Character.ChildAdded:Connect(HandleCharacterChild); -- If an parts are added when for example the player is loading
	end)


	RunService.RenderStepped:Connect(function(DeltaTime:number)
		local Character = Player.Character;

		if (Character and Character:FindFirstChild("Head")) then -- Check if the character exists and the character's head exists since it can be destroyed and that can lead to errors
			local CameraZoomDistance = (Character.Head.Position - Camera.CFrame.Position).Magnitude; -- Get the zoom distance

			local IsInFirstPerson = CameraZoomDistance < 3; -- There might be a better way to check if the player is in first person

			for _, Part:BasePart in ipairs(CharacterParts) do -- Loop through the table where we inserted all the duplicate parts
				local CharacterPart = Character:FindFirstChild(Part.Name);

				if (CharacterPart) then -- If it finds a part with the same name inside the character then continue
					Part.CFrame = IsInFirstPerson and CharacterPart.CFrame or CFrame.new(FAR); -- Set its CFrame to that character's part with the same name or very far depending on if the player is in first person
				end
			end
		end
	end)
end

return FirstPersonShadow;