local ReplicatedStorage = game:GetService("ReplicatedStorage");
local Shared = ReplicatedStorage:WaitForChild("Aero"):WaitForChild("Shared");

local Signal = require(Shared:WaitForChild("Signal"));
local Maid = require(Shared:WaitForChild("Maid"));

local ExecuterCommands = require(script.Parent:WaitForChild("ExecuterCommands"));

local Executer = {};
Executer.__index = Executer;

function Executer.Execute(Command:string, Directory, Console)
	local start = os.clock();

	local self = setmetatable({
		Command = Command,
		Console = Console,
		Environment = {
			Variables = {},
		},
		ExecutionDirectoryChanged = Signal.new(),
	}, Executer);

	local readable, strings = self:FormatIntoReadable();
	self.Readable = readable;
	self.strings = strings;
	self:Compile();

	Console:WriteLine("Execution finished! time:", os.clock() - start);

	return self;
end

function Executer:Error(Message)
	if (self.Errored) then return; end;

	self.Console:WriteLine("ERROR: ", Message.."\n");
	self.Errored = true;
end

function Executer:Compile()
	self.Compiled = {};

	-- self.Console:WriteLine(self.Readable);
	
	local ExpectedToClose = {
		["\""] = "\"",
		["("] = ")",
		["["] = "]"
	};
	
	local tracking = {};
	for index, command in ipairs(self.Readable) do
		if (ExpectedToClose[command]) then
			tracking[command] = tracking[command] and tracking[command] + 1 or 1;
		end
		
		for ToClose, Closing in pairs(ExpectedToClose) do
			if (command == Closing) then
				if (tracking[ToClose] and tracking[ToClose] > 0) then
					tracking[ToClose] -= 1;
				else
					self:Error("Unexpected symbol: \"".. ToClose.."\"");
				end
			end
		end
	end
	
	if (self.Errored) then return; end;
	
	for expectedToClose, DidClose in pairs(tracking) do
		if (DidClose > 0) then
			self:Error(string.format("Expected to close \"%s\" with \"%s\".", expectedToClose, ExpectedToClose[expectedToClose]));
		end
	end
	
	if (self.Errored) then return; end;
	
	local SkipTo = nil;
	local isString = false;
	for index, command in ipairs(self.Readable) do
		if (self.Errored) then return; end;

		if (SkipTo and index <= SkipTo) then print("skipping line", command); continue; end;

		if (self.strings[index] and not isString) then
			isString = true;
		end
		if (isString) then
			if (string.sub(command, #command, #command) == "\"") then
				isString = false;
			end
		end

		if (ExecuterCommands[command]) then
			local Instructions = ExecuterCommands[command]:CompilerHandle(index, command, self.Compiled, self.Readable, self.Console, self.Environment, self.Command, self.strings);
			
			if (Instructions.SkipToLine) then
				warn("SKIPPING TO ", Instructions.SkipToLine);
				SkipTo = Instructions.SkipToLine;
			end
			if (Instructions.Error) then
				self:Error(Instructions.Error);
			end
		elseif(self.Readable[index+1] == "(") then
			if (not self.Environment.Variables[command]) then
				self:Error(string.format("Attempt to call a nil value: \"%s\".", command))
			end
		elseif (command ~= " " and command ~= "") then
			if (isString) then
				self:Error("Incomplete statement. "..command);
			end
		end
	end
end

function Executer:Run()
	-- for index, Word in ipairs()
end

local Ignore = {};
local Separators = {
	["{"] = 2,
	["}"] = 2,
	[" "] = -1,
	["("] = 2,
	[")"] = 2,
	["'"] = 2,
	["="] = 2,
}
function Executer:FormatIntoReadable()
	local lex = {""};
	local strings = {};

	self.Command = string.gsub(self.Command, "%s+", " ")

	for i = 1, #self.Command do
		local letter = string.sub(self.Command, i, i);

		if (letter == "\"") then
			local found = false;
			for _, str in pairs(strings) do
				if (str[2] == i) then
					found = true;
					break;
				end
			end

			if (not found) then
				local end_;
				for i2 = i + 1, #self.Command do
					local letter2 = string.sub(self.Command, i2, i2);

					if (letter2 == "\"" or letter2 == "'") then
						end_ = i2;
						break;
					end
				end

				strings[#lex] = {i, end_};
			end
		end

		local cur = lex[#lex];

		if (Separators[letter] and (#cur > 0)) then
			lex[#lex + 1] = Separators[letter] ~= -1 and letter or "";

			if (Separators[letter] == 2) then
				lex[#lex + 1] = "";
			end

			continue;
		end

		cur ..= letter ~= " " and letter or "";
		lex[#lex] = cur;
	end

	warn("STRINGS:", strings);

	-- warn("Last lex: ", lex[#lex]);
	if (lex[#lex] == "") then
		lex[#lex] = nil;
	end

	-- self.Console:WriteLine(lex);
	return lex, strings;
end

return Executer;