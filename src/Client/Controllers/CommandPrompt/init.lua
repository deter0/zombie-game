local ReplicatedStorage = game:GetService("ReplicatedStorage");
local Shared = ReplicatedStorage:WaitForChild("Aero"):WaitForChild("Shared");

local Signal = require(Shared:WaitForChild("Signal"));
local Maid = require(Shared:WaitForChild("Maid"));

local Executer = require(script:WaitForChild("Executer"));

local CommandPrompt = {
	LinesPrinted = {},
	NumOfLines = 0,
	Maid = Maid.new(),
	Directory = "game/",
	DirectoryChanged = Signal.new(),
};

function CommandPrompt:Start()
	self:Open();
end

local CouldNotConvertError = "(Unable to covert to string)";

local MaxDepth = 5;
local function TableToString(Table):string
	local function insert(tbl, depth)
		local Stringified = "{";
		
		for i, v in pairs(tbl) do
			if (type(v) == "string") then
				v = "\""..v.."\"";
			end

			local value = tostring(v) or CouldNotConvertError;
			
			if (type(v) == "table") then
				if (depth <= MaxDepth) then
					value = insert(v, depth + 1);
				else
					value = "(Max table depth reached)";
				end
			end

			Stringified..= string.format("\n"..string.rep("    ", depth).."[%s] = %s,", tostring(i) or CouldNotConvertError, value or CouldNotConvertError);
		end

		return Stringified.."\n"..string.rep("    ", depth-1).."}";
	end

	return insert(Table, 1);
end

function CommandPrompt:ToString(ConvertObject)
	local Converted = tostring(ConvertObject) or "(Unable to covert to string)";

	if (type(Converted) == "table") then
		Converted = TableToString(ConvertObject);
	end

	return Converted;
end

function CommandPrompt:WriteLine(...)
	for _, line in ipairs({...}) do
		if (type(line) == "table") then
			line = TableToString(line);
		end

		line = tostring(line) or "(Unable to covert to string)";

		self.NumOfLines += 1;

		local Line = self.UI.Line:Clone();
		Line.Text = line;
		Line.LayoutOrder = self.NumOfLines;

		Line.Parent = self.UI.Body;
	end
end

function CommandPrompt:Open()
	local Player:Player = game:GetService("Players").LocalPlayer;
	local PlayerGui:PlayerGui = Player:WaitForChild("PlayerGui");

	local CommandPromptScreenGui = PlayerGui:WaitForChild("CommandPrompt");
	self.UI = {
		Window = CommandPromptScreenGui:WaitForChild("Window"),

		Body = CommandPromptScreenGui.Window:WaitForChild("Body"),
		Header = CommandPromptScreenGui.Window:WaitForChild("Header"),
		Storage = CommandPromptScreenGui.Window:WaitForChild("Storage"),

		Line = CommandPromptScreenGui.Window.Storage:WaitForChild("Line"),
		Input = CommandPromptScreenGui.Window.Body:WaitForChild("Input"),

		Command = CommandPromptScreenGui.Window.Body.Input:WaitForChild("Command")
	};

	local NOTICE = "Untitled Game [Version 1.0]\nRoblox Command Language [Version 1.0]\n";
	if (not self:FindLine(NOTICE)) then
		self:WriteLine(NOTICE);
	end

	self.UI.Command:CaptureFocus();

	local UserInputService = game:GetService("UserInputService");

	self.Maid.ListenForTab = UserInputService.InputBegan:Connect(function(Input)
		if (Input.KeyCode == Enum.KeyCode.Tab) then
			self.UI.Command.Text ..= string.rep("\t", 4);
			self.UI.Command.CursorPosition += 4;
		elseif (Input.KeyCode == Enum.KeyCode.Return and CommandPromptScreenGui.Enabled) then
			self:WriteLine(">\t"..string.sub(self.UI.Command.Text, 1, 100)..(#string.sub(self.UI.Command.Text, 1, 100)>100 and "..." or ""));
			local Execution = Executer.Execute(self.UI.Command.Text, self.Directory, self);

			self.Maid.ExecutionDirectoryChanged = Execution.ExecutionDirectoryChanged:Connect(function(Directory)
				self.Directory = Directory;
				self.DirectoryChanged:Fire();
			end)

			self.UI.Body.CanvasPosition = Vector2.new(0, math.huge);
			self.UI.Command.Text = "";
		end
	end)
	self.Maid.DirectoryChanged = self.DirectoryChanged:Connect(function()
		self.UI.Input:WaitForChild("Location").Text = string.sub(self.Directory, 1, #self.Directory - 1)..":\\>";
	end)
	self.DirectoryChanged:Fire();
end

function CommandPrompt:FindLine(Line)
	local StringLine = self:ToString(Line);

	for i = 1, #StringLine do
		local Letter = string.sub(Line, i, i);
		if (not self.LinesPrinted[Letter]) then
			return false;
		end
	end
	
	return true;
end

return CommandPrompt;