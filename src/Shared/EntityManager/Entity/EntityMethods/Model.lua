local Model = {};

function Model.Remove(self)
	self.Model:Destroy();
	self.Model = -1;

	return true, {};
end

function Model.Apply(self)
	self.Model = self.Model:Clone();
	self.Model:SetAttribute("Id", self.Id);
	return true, {};
end

return Model;