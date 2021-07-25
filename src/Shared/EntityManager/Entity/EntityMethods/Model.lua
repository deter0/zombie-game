local Model = {};

function Model.Remove(self)
	self.Model:Destroy();
	self.Model = -1;

	return true, {};
end

function Model.Apply(self)
	self.Model = self.Model:Clone();
	return true, {};
end

return Model;