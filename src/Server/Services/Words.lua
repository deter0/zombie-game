-- Words
-- Deter
-- July 26, 2021

local ReplicatedStorage = game:GetService("ReplicatedStorage");
local Shared = ReplicatedStorage:WaitForChild("Aero"):WaitForChild("Shared");

local HttpService = game:GetService("HttpService");
local StringUtil = require(Shared:WaitForChild("StringUtil"));

local Words = {Client = {}}


function Words:Start()
	if (true) then return; end;
	
	self.Words = HttpService:GetAsync("https://raw.githubusercontent.com/dwyl/english-words/master/words_dictionary.json", false);
	self.Words = HttpService:JSONDecode(self.Words);

	self.WordsSearchable = {};

	for word, _ in pairs(self.Words) do
		self.WordsSearchable[#self.WordsSearchable + 1] = word;
	end

	self.Trie = {};

	for _, word in pairs(self.WordsSearchable) do
		local par = self.Trie;

		for i = 1, #word do
			local letter = string.sub(word, i, i);

			if (not par[letter]) then
				par[letter] = {};
				par = par[letter];
			else
				par = par[letter];
			end
		end
	end

	print(self.Trie['a']['b']['c']);

	local search = "like";
	local s = os.clock();
	print(("Searching '%s'"):format(search));
	print(Words:TrieSearch(search));
	print("Search time:", os.clock() - s, ". Searched", #self.WordsSearchable);
end

function Words:TrieSearch(str:string)
	local matches = 0;
	local word = "";
	local par = self.Trie;

	for i = 1, #str do
		local letter = string.sub(str, i, i);

		if (par[letter]) then
			matches += 1;
			par = par[letter];
			word ..= letter;
		end
	end

	local words = {};

	local function getWord(word, sub)
		local subWords = {};

		for letter, children in pairs(sub) do
			local newWord = word..letter;
			subWords[#subWords+1] = newWord;

			local subSubWords = getWord(newWord, children);
			for _, _word in ipairs(subSubWords) do
				subWords[#subWords+1] = _word;
 			end
		end

		return subWords;
	end
	
	print(getWord(word, par));

	print(par);
end

function Words:Search(str:string)
	local Result = {
		_CloseMatches = {},
		RoughMatches = {}
	};

	str = string.lower(str);

	local function getWordMatch(word)
		if (word == str) then return math.huge; end;

		local _, matches = string.find(word, str);
		return matches/#word;
	end

	local rm, cm = 0, 0;
	for _, word in ipairs(self.WordsSearchable) do
		if (StringUtil.StartsWith(word, str) and cm < 30) then
			Result._CloseMatches[word] = getWordMatch(word);
			cm += 1;
		end

		if (cm > 30) then break; end;
	end

	Result.CloseMatches = {};
	for word, match in pairs(Result._CloseMatches) do Result.CloseMatches[#Result.CloseMatches+1] = {word, match}; end;
	table.sort(Result.CloseMatches, function(a, b)
		return a[2] > b[2];
	end)
	for i, v in ipairs(Result.CloseMatches) do
		Result.CloseMatches[i] = v[1];
	end

	return Result;
end

function Words:Init()
	
end


return Words