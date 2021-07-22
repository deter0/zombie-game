local Instructions = {};
Instructions.__index = Instructions;

function Instructions.new()
	return setmetatable({
		Error = nil
	}, Instructions);
end
function Instructions.FromError(ErrorMessage, ...)
	return setmetatable({
		Error = string.format(ErrorMessage, ...)
	}, Instructions);
end
function Instructions.FromSkipToLine(Line)
	return setmetatable({
		SkipToLine = Line,
		Error = nil,
	}, Instructions);
end

local Errors = {
	["ArgumentMissing"] = "Argument %d missing or nil.\n",
	["NoFunctionRequirement"] = "Expected %s when declaring function."
};

local ExecuterCommand = {
	['cd'] = {},
	['function'] = {},
	['var'] = {},
	['print'] = {}
};

function ExecuterCommand.cd:CompilerHandle(index, command, compiled, readable, console)
	if (not readable[index + 1]) then
		return Instructions.FromError(Errors.ArgumentMissing, 1);
	end

	console:WriteLine("Success", readable[index + 1]);

	return Instructions.FromSkipToLine(index + 1);
end

local types = {
	["str"] = "string",
	["bool"] = "boolean",
	["int"] = "number",
};

local function getType(var)
	if (type(var) == 'string' and string.sub(var, 1, 1) == '"' and string.sub(var, #var, #var) == '"') then
		return "str";
	elseif (tonumber(var) ~= nil) then
		return "int";
	elseif (var == "false" or var == "true") then
		return "bool";
	end
end

function ExecuterCommand.var:CompilerHandle(index, command, compiled, readable, console, environment)
	local varType = readable[index + 1];
	local varName = readable[index + 2];
	local equals = readable[index + 3];
	local value = readable[index + 4];

	if (not varName) then
		return Instructions.FromError("Cannot declare function without function name.");
	end

	-- if (not string.match(varName, "%W")) then
	-- 	return Instructions.FromError("Variable name contains illegal characters.");
	-- end

	local variable = {
		varName = varName;
	};

	-- console:WriteLine('/'..value..'\\', varName);

	if (varType and types[varType]) then
		if (equals and equals == "=") then
			if (value) then
				local type = getType(value);

				print("type", type);
				if (type == nil) then
					value = environment.Variables[value] and environment.Variables[value].Value;
					type = getType(value);
				end

				if (type == varType or type == nil) then
					variable.Value = value;
				else
					return Instructions.FromError("Cannot declare variable of type %s to value \"%s\"", varType, value);
				end
			end
		end
	else
		return Instructions.FromError("Unknown type \"%s\".", varType);
	end

	-- console:WriteLine(variable);
	environment.Variables[varName] = variable;
	return Instructions.FromSkipToLine(index + (equals and 4 or 2));
end



ExecuterCommand["function"].CompilerHandler = function(self, index, command, compiled, readable, console, environment)
	local functionName = readable[index + 1];
	local bracketA = readable[index + 2];
	local bracketB = readable[index + 3];
	local bodyA = readable[index + 4];
	local bodyB = readable[index + 5];

	--TODO: Parameters
	
	if (functionName) then -- function name
		if (bracketA == "(") then -- bracket one
			if (bracketB == ")") then -- bracket two
				if (bodyA == "{") then -- body
					if (bodyB == "}") then -- end
						environment[functionName] = {
							type = "function"
						};
						return Instructions.FromSkipToLine(6);
					else
						return Instructions.FromError(Errors.NoFunctionRequirement, "}");
					end
				else
					return Instructions.FromError(Errors.NoFunctionRequirement, "{");
				end
			else
				return Instructions.FromError(Errors.NoFunctionRequirement, "\")\"");
			end
		else
			return Instructions.FromError(Errors.NoFunctionRequirement, "\"(\"");
		end
	else
		return Instructions.FromError(Errors.NoFunctionRequirement, "Identifier");
	end
end

function ExecuterCommand.print:CompilerHandle(index, command, compiled, readable, console, environment, command, strings)
	local parenthesisA = readable[index + 1];
	if (parenthesisA == "(") then
		local arguments = {};
		
		local current;

		local i = 1;
		while current ~= ")" or not current do
			arguments[#arguments + 1] = {readable[index + i + 1], index+i+1};
			i += 1;
			current = readable[index + i + 1];
		end

		local toPrint = {};

		local skip;
		for i2, v in pairs(arguments) do
			if (skip and i2 < skip) then continue; end;

			if (type(v[1]) == "string" and string.sub(v[1], 1, 1) == "\"") then
				local current_ = string.sub(command, strings[v[2]][1], strings[v[2]][2]);

				for i3 = i2, #arguments do
					local argument = arguments[i3][1];
					if (not string.sub(argument, #argument, #argument) ~= "\"") then
						skip = i3;
						break;
					end
				end

				toPrint[#toPrint + 1] = current_;
			elseif (environment.Variables[v[1]]) then
				toPrint[#toPrint + 1] = environment.Variables[v[1]].Value;
			else
				toPrint[#toPrint + 1] = "nil";
			end
		end

		console:WriteLine(unpack(toPrint));
		--[[var int x = 5 var int y = 15 var int z = 24 var bool f = false print(x) print(y) print(z) print(f)]]
		console:WriteLine("\n");

		return Instructions.FromSkipToLine(index + i + 1);
	else
		print('no parentisis');
	end
end

return ExecuterCommand;