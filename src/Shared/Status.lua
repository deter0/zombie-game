local Status = {
	Code = -1,
	Message = ""
};

function Status:DidNotFail():boolean
	return self.Code <= 200 and self.Code < 299;
end

function Status.new(Code:number, Message:string?)
	return setmetatable({ Code = Code, Message = Message or "" }, Status);
end

return Status.new;