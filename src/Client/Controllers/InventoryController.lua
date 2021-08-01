-- Inventory Controller
-- Deter
-- June 20, 2021

local RunService = game:GetService("RunService");
local UserInputService = game:GetService("UserInputService");
local TweenService = game:GetService("TweenService");
local ContentProvider = game:GetService("ContentProvider");
local ContextActionService = game:GetService("ContextActionService");

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Aero"):WaitForChild("Shared");

local TableUtil = require(Shared:WaitForChild("TableUtil"));

local Thread = require(Shared:WaitForChild("Thread"));
local InventoryController = {};

function InventoryController:Start()
	self.Player = game:GetService("Players").LocalPlayer;
	self.PlayerGui = self.Player:WaitForChild("PlayerGui");
	self.Gui = self.PlayerGui:WaitForChild("Inventory");
	self.GuiStorage = self.Gui:WaitForChild("Items");

	self.InventoryManager = self.Services.InventoryManager;

	local Container:Frame = self.Gui:WaitForChild("Container"):WaitForChild("InventorySlotsContainer");
	function self:SizeChanged()
		local GridLayout = Container:WaitForChild("UIGridLayout");

		GridLayout.CellSize = UDim2.fromOffset(Container.AbsoluteSize.X/7, Container.AbsoluteSize.Y/5);
	end

	warn("Inventory controller started.");

	Container:GetPropertyChangedSignal("AbsoluteSize"):Connect(self.SizeChanged);
	self:SizeChanged();

	ContextActionService:BindAction("OpenInventory", function(_, State)
		if (State ~= Enum.UserInputState.Begin) then return; end;
		print("Inventory open action called.");

		self.Gui.Enabled = not self.Gui.Enabled;

		for _, v in ipairs(game:GetService("Lighting"):GetChildren()) do
			if (v.Name == "Inventory") then
				v.Enabled = self.Gui.Enabled;
			end
		end

		self.Controllers.FPSFramework.WeaponHandler:MenuToggled("Inventory", self.Gui.Enabled);

		if (self.Gui.Enabled) then
			for _, InventorySlot in ipairs(self.InventorySlots or {}) do
				InventorySlot:Destroy();
			end

			self.Inventory = self.InventoryManager:GetInventory().Inventory;
			self:DrawInventory(self.Gui:WaitForChild("Container"):WaitForChild("InventorySlotsContainer"));
		end
	end, false, Enum.KeyCode.E);
end

local function Intersecting(x, y, p, s)
	return ((x >= (p.X - s.X/2) and x <= (p.X + (s.X/2))) and (y >= (p.Y - s.Y/2) and y <= (p.Y + s.Y/2)));
end

function InventoryController:GetHoveringSlot(DragOffset:Vector2)
	local MouseLocation:Vector2 = UserInputService:GetMouseLocation() + self.DragOffset;

	for _, InventorySlot in ipairs(self.InventorySlots) do
		if (Intersecting(MouseLocation.X + DragOffset.X, MouseLocation.Y + DragOffset.Y, InventorySlot.Gui.AbsolutePosition, InventorySlot.Gui.AbsoluteSize)) then
			return InventorySlot;
		end
	end
end

function InventoryController:Drag(InventorySlotGui:TextLabel, InitialX:number, InitialY:number)
	local InitialClickPosition = Vector2.new(InitialX, InitialY);

	if (self.DraggingLoop) then self.DraggingLoop:Disconnect(); end;
	if (self.DetectStopSignal) then self.DetectStopSignal:Disconnect(); end;
	if (self.DraggingObject) then self.DraggingObject:Destroy(); end;

	local FromInventorySlot = self.InventorySlots[InventorySlotGui:GetAttribute("index")];

	self.DraggingObject = self.GuiStorage:WaitForChild("Dragging"):Clone();
	self.DraggingObject:WaitForChild("Icon").Image = InventorySlotGui:WaitForChild("Icon").Image;

	self.DraggingObject.Parent = self.Gui;

	self.StopDragging = false;
	self.RightClicked = false;

	self.DragOffset = InventorySlotGui.AbsolutePosition - InitialClickPosition;

	self.DetectStopSignal = UserInputService.InputEnded:Connect(function(Input)
		if (Input.UserInputType == Enum.UserInputType.MouseButton1) then
			if (not self.RightClicked) then
				self.StopDragging = true;
				self.DetectStopSignal:Disconnect();
			else
				self.StopDragging = true;
			end
		elseif (Input.UserInputType == Enum.UserInputType.MouseButton2) then
			local HoveringSlot = self:GetHoveringSlot(self.DragOffset);

			self.RightClicked = true;

			if (HoveringSlot) then
				if (HoveringSlot.Slot.Item == FromInventorySlot.Slot.Item) then
					FromInventorySlot.Slot.Quantity -= 1;
					HoveringSlot.Slot.Quantity += 1;

					HoveringSlot:Update();
					FromInventorySlot:Update();
				else
					FromInventorySlot.Slot.Quantity -= 1;

					HoveringSlot.Slot.Quantity += 1;
					HoveringSlot.Slot.Item = TableUtil.Copy(FromInventorySlot.Slot.Item);

					HoveringSlot:Update();
					FromInventorySlot:Update();

					HoveringSlot.Gui.Icon.Image = FromInventorySlot.Gui.Icon.Image;
				end

				if (FromInventorySlot.Slot.Quantity == 0) then
					FromInventorySlot.Slot.Item = nil;
					self.StopDragging = true;
				end
			end
		end
	end)

	InventorySlotGui.Icon.ImageTransparency = 0.75;

	self.DraggingLoop = RunService.RenderStepped:Connect(function()
		local MouseLocation:Vector2 = UserInputService:GetMouseLocation() + self.DragOffset;

		self.DraggingObject.Position = UDim2.fromOffset(MouseLocation.X, MouseLocation.Y);
		self.DraggingObject.Icon.Size = UDim2.fromOffset(InventorySlotGui.Icon.AbsoluteSize.X, InventorySlotGui.Icon.AbsoluteSize.Y);

		if (self.StopDragging) then
			self.StopDragging = false;

			self.DraggingLoop:Disconnect();
			self.DetectStopSignal = self.DetectStopSignal and self.DetectStopSignal:Disconnect();
			self.DraggingObject:Destroy();

			local TweenBack = TweenService:Create(InventorySlotGui.Icon, TweenInfo.new(.3, Enum.EasingStyle.Circular), {ImageTransparency = 0});
			TweenBack:Play();

			TweenBack.Completed:Connect(function()
				TweenBack:Destroy();
			end)

			if (self.RightClicked) then return; end;

			for _, InventorySlot in ipairs(self.InventorySlots) do
				if (Intersecting(MouseLocation.X, MouseLocation.Y, InventorySlot.Gui.AbsolutePosition, InventorySlot.Gui.AbsoluteSize)) then
					local CurrentInventorySlot = InventorySlot.Slot;

					Thread.Spawn(function()
						self.InventoryManager:ExchangeSlot(FromInventorySlot.Slot.index, CurrentInventorySlot.index);
					end)

					if (FromInventorySlot.Slot.index == CurrentInventorySlot.index) then return; end;

					local From = {Item = FromInventorySlot.Slot.Item, Quantity = FromInventorySlot.Slot.Quantity};

					if (FromInventorySlot.Slot.Item and CurrentInventorySlot.Item and FromInventorySlot.Slot.Item.Class == CurrentInventorySlot.Item.Class) then
						FromInventorySlot.Slot.Item = nil;
						CurrentInventorySlot.Quantity += FromInventorySlot.Slot.Quantity;
						FromInventorySlot.Slot.Quantity = 0;
					else
						FromInventorySlot.Slot.Item = CurrentInventorySlot.Item;
						CurrentInventorySlot.Item = From.Item;

						FromInventorySlot.Slot.Quantity = CurrentInventorySlot.Quantity;
						CurrentInventorySlot.Quantity = From.Quantity;
					end

					print(FromInventorySlot, CurrentInventorySlot);

					InventorySlot:Update();
					FromInventorySlot:Update();

					break;
				end
			end
		end
	end)
end

function InventoryController:DrawInventory(Parent:Instance)
	local HoverTweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Circular, Enum.EasingDirection.Out);
	local ImagesToLoad = {};
	self.InventorySlots = {};

	for _, InventorySlot in ipairs(self.Inventory) do
		local Tweens = {};

		local InventorySlotGui:TextButton = self.GuiStorage:WaitForChild("Slot"):Clone();

		local Slot = {Gui = InventorySlotGui, Slot = InventorySlot, Update = function(self)
			self.Gui.Icon.Image = self.Slot.Item and self.Slot.Item.Icon or "";
			self.Gui.QuantityText.Text = self.Slot.Quantity or 0;
		end, Destroy = function(self)
			self.Gui:Destroy();
			self.Update = nil;
			self.Gui = nil;
			self.FlashTween = self.FlashTween and self.FlashTween:Destroy();
			table.clear(self);
			setmetatable(self, nil);
		end};

		InventorySlotGui:WaitForChild("QuantityText").Text = InventorySlot.Quantity;

		InventorySlotGui.MouseEnter:Connect(function()
			if (not Tweens.OnMouseEnter) then
				Tweens.OnMouseEnter = TweenService:Create(InventorySlotGui, HoverTweenInfo, {BorderSizePixel = 2});
			end
			if (not Tweens.OnMouseLeave) then
				Tweens.OnMouseLeave = TweenService:Create(InventorySlotGui, HoverTweenInfo, {BorderSizePixel = 0});
			end

			Tweens.OnMouseLeave:Pause();
			Tweens.OnMouseEnter:Play();
		end)

		InventorySlotGui.MouseLeave:Connect(function()
			if (Tweens.OnMouseEnter) then
				Tweens.OnMouseEnter:Pause();
				Tweens.OnMouseLeave:Play();
			end
		end)

		InventorySlotGui.MouseButton1Down:Connect(function(...)
			if (not self.Dragging and Slot.Slot.Item) then
				self:Drag(InventorySlotGui, ...);
			end
		end)

		if (InventorySlot.Item) then
			local Neighbours = ImagesToLoad[InventorySlot.Item.Icon];

			if (not Neighbours) then
				ImagesToLoad[InventorySlot.Item.Icon] = { InventorySlotGui:WaitForChild("Icon") };
			else
				Neighbours[#Neighbours + 1] = InventorySlotGui:WaitForChild("Icon");
				ImagesToLoad[InventorySlot.Item.Icon] = Neighbours;
			end
		end

		InventorySlotGui.Parent = Parent;
		InventorySlotGui:SetAttribute("index", InventorySlot.index);

		self.InventorySlots[#self.InventorySlots + 1] = Slot;
	end

	for ImageId:string, Instances in pairs(ImagesToLoad) do
		ContentProvider:PreloadAsync({ImageId}, function(NewImageId:string, Status:Enum)
			if (Status == Enum.AssetFetchStatus.Success) then
				for _, Object in ipairs(Instances) do
					Object.Image = NewImageId;
				end
			end
		end);
	end
end

function InventoryController:Init()

end


return InventoryController