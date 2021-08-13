-- Tree Collision Box Generator
-- Deter
-- July 6, 2021

local CollectionService = game:GetService("CollectionService");

local TreeCollisionBoxGenerator = {};

function TreeCollisionBoxGenerator:GenerateCollisionBox(TreeModel:Model)
	local TreeTrunk = TreeModel:WaitForChild("Trunk", 6);

	if (TreeTrunk) then
		local XZMagnitude = math.sqrt(TreeTrunk.Size.X^2 + TreeTrunk.Size.Z^2)/14;
		local YSize = TreeTrunk.Size.Y;

		local CollisionBox = Instance.new("Part");
		CollisionBox.CFrame = TreeTrunk.CFrame;

		CollisionBox.Transparency = 1;
		CollisionBox.Anchored = true;
		CollisionBox.CanTouch = false;

		CollisionBox.Shape = Enum.PartType.Cylinder;
		CollisionBox.Rotation += Vector3.new(0, 0, 90);

		local CollisionBoxSize = Vector3.new(YSize, XZMagnitude, XZMagnitude);
		CollisionBox.Size = CollisionBoxSize;

		CollisionBox.Parent = workspace:WaitForChild("TreeCollidors");

		TreeTrunk.CanCollide = false;
		TreeTrunk.CanTouch = false;
	end
end

function TreeCollisionBoxGenerator:Start()
	for _, Tree in ipairs(CollectionService:GetTagged("Tree")) do
		self:GenerateCollisionBox(Tree);
	end
	CollectionService:GetInstanceAddedSignal("Tree"):Connect(function(Tree)
		task.spawn(function()
			self:GenerateCollisionBox(Tree);
		end)
	end)
end

return TreeCollisionBoxGenerator;