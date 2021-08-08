-- UI Components
-- Deter
-- July 4, 2021

local RunService = game:GetService("RunService");
local UserInputService = game:GetService("UserInputService");

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Aero"):WaitForChild("Shared");

local Signal = require(Shared:WaitForChild("Signal"));
local Maid = require(Shared:WaitForChild("Maid"));

local MouseUp = Signal.new();

UserInputService.InputEnded:Connect(function(Input)
	if (Input.UserInputType == Enum.UserInputType.MouseButton1) then
		MouseUp:Fire();
	end
end)

local Slider = {
	Userdata = {},
	Value = 0
};
Slider.__index =  Slider;

function Slider:Destroy()
	self.Maid:Destroy();
	self.Changed:Destroy();
	table.clear(self);
	setmetatable(self, nil);
end

local function fuzzyEQ(a:number, b:number, epsilon:number)
	return math.abs(a - b) <= epsilon;
end

function Slider:SetDragging(DraggingState:boolean)
	if (self.Busy) then return; end;
	self.Dragging = DraggingState;

	if (self.Dragging) then
		self.StartPositionX = self.Gui.AbsolutePosition.X;

		self.Maid.RenderStepped = RunService.RenderStepped:Connect(function(DeltaTime)
			local MousePosition = UserInputService:GetMouseLocation();

			UserInputService.MouseIconEnabled = false;
		self.Value = math.clamp(MousePosition.X/(workspace.CurrentCamera.ViewportSize.X/2), 0, 1);

			self.SliderBall.Position = self.SliderBall.Position:Lerp(UDim2.fromScale(self.Value, .5), DeltaTime * 5);

			if (self.Data and self.Data.Range) then
				self.RealValue = (self.Data.Range.Max*self.Value)+(self.Data.Range.Min*(1-self.Value));
			else
				self.RealValue = self.Value;
			end
			
			self.Changed:Fire(self.RealValue, self.Userdata);
			self.SliderBall.Position = self.SliderBall.Position:Lerp(UDim2.fromScale(self.Value, .5), DeltaTime * 5);
		end)
	else
		self.Busy = true;

		self.Maid.RenderStepped = nil;
		UserInputService.MouseIconEnabled = true;

		UserInputService.MouseIconEnabled = true;

		repeat RunService.RenderStepped:Wait();
			self.SliderBall.Position = self.SliderBall.Position:Lerp(UDim2.fromScale(self.Value, .5), .2);
		until fuzzyEQ(self.SliderBall.Position.X.Scale or 0, self.Value, .001);

		self.Busy = false;
	end
end

function Slider:ListenForEvents()
	self.Maid.MouseButton1Down = self.Gui.MouseButton1Down:Connect(function()
		self:SetDragging(true);
	end)
	self.Maid.MouseButton1Down2 = self.SliderBall.MouseButton1Down:Connect(function()
		self:SetDragging(true);
	end)
	self.Maid.MouseUp = MouseUp:Connect(function()
		if (self.Dragging) then
			self:SetDragging(false);
		end
	end)
end

function Slider:SetValue(Value:number)
	assert(type(Value) == "number", "Invalid value");
	self.RealValue = Value;
	Value = math.clamp(Value, self.Data.Range.Min, self.Data.Range.Max)/self.Data.Range.Max;
	self.Value = Value;
	self.SliderBall.Position = UDim2.fromScale(self.Value, .5);
	self.Changed:Fire(self.RealValue, self.Userdata);
end

function Slider:Register()
	self.SliderBall = self.Gui:WaitForChild("SliderBall");
end

function Slider.new(Gui:Instance, ExtraData, Data)
	local self = setmetatable({
		Maid = Maid.new(),
		Data = Data,
		Gui = Gui:WaitForChild("Slider"),
		Userdata = ExtraData,
		Changed = Signal.new()
	}, Slider);

	self:Register();
	self:ListenForEvents();

	return self;
end





local Selection = {};
Selection.__index = Selection;

function Selection:Destroy()
	self.Maid:Destroy();
	self.Changed:Destroy();
	table.clear(self);
	setmetatable(self, nil);
end

function Selection:Register()
	self.Option = self.Storage:WaitForChild("Option");
	self.Options = self.Gui:WaitForChild("Options");
	
	local PageLayout:UIPageLayout = self.Options:WaitForChild("UIPageLayout");
	self.PageLayout = PageLayout;

	self.Right = self.Gui:WaitForChild("Right");
	self.Left = self.Gui:WaitForChild("Left");
end

function Selection:SetValue(Value:string)
	local Option = self.Options:FindFirstChild(Value);
	if (not Option) then warn("No option", Value); return; end;

	self.Value = Value;
	self.PageLayout:JumpTo(Option);
	self.Changed:Fire(self.Value, self.Userdata);
end

function Selection:ListenForEvents()
	for index, OptionText in ipairs(self.Data) do
		local Option:TextLabel = self.Option:Clone();
		Option.Text = OptionText;
		Option.LayoutOrder = index;
		Option.Name = OptionText;
		Option.Parent = self.Options;

		self.Maid[OptionText] = Option;
	end

	self.Maid.Right = self.Right.MouseButton1Up:Connect(function()
		self.PageLayout:Next();
	end)

	self.Maid.Left = self.Left.MouseButton1Up:Connect(function()
		self.PageLayout:Previous();
	end)

	self.Maid.PageChanged = self.PageLayout.Changed:Connect(function()
		self.Value = self.PageLayout.CurrentPage.Text;
		self.Changed:Fire(self.Value, self.Userdata);
	end)
end

function Selection.new(Gui, Userdata, Data, Storage)
	local self = setmetatable({
		Changed = Signal.new(),
		Maid = Maid.new(),
		Gui = Gui:WaitForChild("Selection"),
		Storage = Storage,
		Data = Data.Values,
		Userdata = Userdata
	}, Selection);

	self:Register();
	self:ListenForEvents();

	return self;
end



local Checkmark = "✓";

local Checkbox = {};
Checkbox.__index = Checkbox;

function Checkbox:Destroy()
	self.Maid:Destroy();
	self.Changed:Destroy();
	table.clear(self);
	setmetatable(self, nil);
end

function Checkbox:ListenForEvents()
	self.Maid.SelectionChanged = self.Gui.MouseButton1Up:Connect(function()
		local Enabled = self.Gui.Text == Checkmark;
		self.Value = not Enabled;
		self.Changed:Fire(self.Value, self.Userdata);
		self.Gui.Text = self.Value and Checkmark or "";
	end)
end

function Checkbox:SetValue(Value:boolean)
	assert(type(Value) == "boolean", "Invalid value");
	self.Value = Value;
	self.Gui.Text = self.Value and Checkmark or "";
	self.Changed:Fire(self.Value, self.Userdata);
end

function Checkbox.new(Gui, Userdata, Data, Storage)
	local self = setmetatable({
		Changed = Signal.new(),
		Maid = Maid.new(),
		Gui = Gui:WaitForChild("Selection"),
		Storage = Storage,
		Data = Data,
		Userdata = Userdata
	}, Checkbox);

	self:ListenForEvents();

	return self;
end

return {
	Slider = Slider,
	Selection = Selection,
	Checkbox = Checkbox
}