local ReplicatedStorage = game:GetService("ReplicatedStorage");
local Shared = ReplicatedStorage:WaitForChild("Aero"):WaitForChild("Shared");

local Signal = require(Shared:WaitForChild("Signal"));
local Maid = require(Shared:WaitForChild("Maid"));

local ContextActionService = game:GetService("ContextActionService");

local RunService = game:GetService("RunService");

local Input = {
	Input = Signal.new(),
	Held = {},
	Maid = Maid.new()
};

function Input:Bind()
	ContextActionService:BindActionAtPriority("Command Prompt Input", function(_, State, KeyCode)
		print(KeyCode.KeyCode, State);
	
		if (State == Enum.UserInputState.Begin) then
			self.Held[KeyCode] = time();
			return;
		end
		
		self.Input:Fire(KeyCode);
		self.Held[KeyCode] = nil;
	end, false, Enum.ContextActionPriority.High.Value, table.unpack(Enum.KeyCode:GetEnumItems()));

	-- self.Maid.Update = RunService.Heartbeat:Connect(function()
	-- 	for KeyCode, IsHeld in pairs(self.Held) do
	-- 		if (IsHeld ~= nil) then
	-- 			if (time() - IsHeld >= .2) then
	-- 				self.Input:Fire(KeyCode);
	-- 				self.Held[KeyCode] = time()-.15;
	-- 			end
	-- 		end
	-- 	end
	-- end)
end

local Exceptions = {
	[Enum.KeyCode.One] = "1",
	[Enum.KeyCode.Two] = "2",
	[Enum.KeyCode.Three] = "3",
	[Enum.KeyCode.Four] = "4",
	[Enum.KeyCode.Five] = "5",
	[Enum.KeyCode.Six] = "6",
	[Enum.KeyCode.Seven] = "7",
	[Enum.KeyCode.Eight] = "8",
	[Enum.KeyCode.Nine] = "9",
	[Enum.KeyCode.Zero] = "0",

	[Enum.KeyCode.Return] = "\n",

	[Enum.KeyCode.Space] = " ",
	[Enum.KeyCode.Tab] = "\t",
}
function Input:TranslateToText(KeyCode)
	return Exceptions[KeyCode] or KeyCode.Name;
end

function Input:Unbind()
	ContextActionService:UnbindAction("Command Prompt Input");
	self.Maid:DoCleaning();
	table.clear(self.Held);
end

return Input;