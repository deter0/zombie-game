-- Inventory Slot
-- Deter
-- June 20, 2021

local InventorySlot = {};
InventorySlot.__index = InventorySlot;


function InventorySlot.new(index)
	local self = setmetatable({
		Item = nil,
		Quantity = 0,
		index = index
	}, InventorySlot);

	return self;
end


return InventorySlot;