local Droppable = {};

function Droppable:Drop(Position:Vector3, CFrameTarget:CFrame?):boolean
	self.Model.Parent = workspace;

	if (Position) then
		self.Model.Position = Position;
	elseif (CFrameTarget) then
		self.Model.CFrame = CFrameTarget;
	end

	if (self.ModelAnchorWhenDropped) then
		self.Model.Anchored = self.ModelAnchorWhenDropped;
	end

	return true;
end

function Droppable.Remove(self)
	local IndexesToUnblock = {};
	for index, _ in pairs(Droppable) do
		if (index ~= "Apply" and index ~= "Remove") then
			self[index] = nil; --> Have to set it to -1 to prevent __index from indexing it to the base class.
			table.insert(IndexesToUnblock, index);
		end
	end

	return true, IndexesToUnblock;
end

function Droppable.Apply(self)
	self.X = string.rep(tostring(math.random()), 5012);
	if (self.Model) then
		for index, value in pairs(Droppable) do
			if (index ~= "Apply" and index ~= "Remove") then
				self[index] = value;
			end
		end
	else
		print("No model");
	end

	return true, {};
end

return Droppable;