-- Tree Collision Box Generator
-- Deter
-- July 6, 2021

local CollectionService = game:GetService("CollectionService");

local TreeCollisionBoxGenerator = {};

function TreeCollisionBoxGenerator:GenerateCollisionBox(TreeModel:Model)   
    local TreeTrunk = TreeModel:WaitForChild("Trunk");
    print(TreeModel, TreeTrunk);
    
    if (TreeTrunk) then
        local XZMagnitude = math.sqrt(TreeTrunk.Size.X^2 + TreeTrunk.Size.Z^2)/14;
        local YSize = TreeTrunk.Size.Y;

        local CollisionBoxSize = Vector3.new(XZMagnitude, YSize, XZMagnitude);

        local CollisionBox = Instance.new("Part");
        CollisionBox.Size = CollisionBoxSize;
        CollisionBox.CFrame = TreeTrunk.CFrame;

        CollisionBox.Transparency = .5;
        CollisionBox.Anchored = true;
        CollisionBox.Color = Color3.new(1, 0, 0);

        CollisionBox.Parent = TreeModel;
        
        TreeTrunk.CanCollide = false;
    end
end

function TreeCollisionBoxGenerator:Start()
    print("Hello");
    
	for _, Tree in ipairs(CollectionService:GetTagged("Tree")) do
        self:GenerateCollisionBox(Tree);
    end
    CollectionService:GetInstanceAddedSignal("Tree"):Connect(function(Tree)
        self:GenerateCollisionBox(Tree);
    end)
end

return TreeCollisionBoxGenerator;