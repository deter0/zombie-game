-- Lighting Config Manager
-- deter
-- August 3, 2021

local TerrainService:Terrain = workspace:WaitForChild("Terrain");
local LightingService = game:GetService("Lighting");
local LightingConfigManager = {
	CurrentConfig = "Game"
};

function LightingConfigManager:SetConfig(ConfigName:string):boolean
	if (LightingService:FindFirstChild(ConfigName) and self.CurrentConfig ~= ConfigName) then
		local Config = LightingService:FindFirstChild(ConfigName);

		if (Config:IsA("Model")) then
			self:UnloadSettingsInto(self.CurrentConfig);
			self:LoadDirectory(ConfigName);
			self.CurrentConfig = ConfigName;

			return true;
		end
	end

	return false;
end

local Blacklist = {
	'Model', 'Folder', 'Configuration'
};

local function DoesPassBlacklist(Instance:Instance):boolean
	for _, BlacklistedClass in ipairs(Blacklist) do
		if (Instance:IsA(BlacklistedClass)) then
			return false;
		end
	end

	return true;
end

function LightingConfigManager:LoadDirectory(DirectoryName:string)
	local DirectoryLighting = LightingService:FindFirstChild(DirectoryName);
	local DirectoryTerrain = TerrainService:FindFirstChild(DirectoryName);

	if (DirectoryTerrain and DirectoryLighting) then
		for _, PostEffect:PostEffect in ipairs(DirectoryLighting:GetChildren()) do
			if (not DoesPassBlacklist(PostEffect)) then continue; end;

			PostEffect.Parent = LightingService;
		end
		for _, PostEffect:PostEffect in ipairs(DirectoryTerrain:GetChildren()) do
			if (not DoesPassBlacklist(PostEffect)) then continue; end;

			PostEffect.Parent = TerrainService;
		end

		--TODO(deter): Configurations for terrain colors and stuff

		local LightingConfigurations:Configuration = DirectoryLighting:FindFirstChildWhichIsA("Configuration");

		if (LightingConfigurations) then
			for _, Configuration:ValueBase in ipairs(LightingConfigurations:GetChildren()) do
				LightingService[Configuration.Name] = Configuration.Value;
			end
		else
			print("no lighting configuration. searched in;", DirectoryLighting);
		end
	end
end

function LightingConfigManager:UnloadSettingsInto(DirectoryName:string):nil
	local DirectoryLighting = LightingService:FindFirstChild(DirectoryName);
	local DirectoryTerrain = TerrainService:FindFirstChild(DirectoryName);

	local function MakeDirectoryInto(Parent:Instance):Model
		local NewDirectory = Instance.new("Model");
		NewDirectory.Name = DirectoryName;
		NewDirectory.Parent = Parent;

		return NewDirectory;
	end

	if (not DirectoryLighting) then
		MakeDirectoryInto(LightingService);
	end
	if (not DirectoryTerrain) then
		MakeDirectoryInto(TerrainService);
	end

	for _, PostEffect:PostEffect in ipairs(LightingService:GetChildren()) do
		if (not DoesPassBlacklist(PostEffect)) then continue; end;

		PostEffect.Parent = DirectoryLighting;
	end
	for _, PostEffect:PostEffect in ipairs(TerrainService:GetChildren()) do
		if (not DoesPassBlacklist(PostEffect)) then continue; end;

		PostEffect.Parent = DirectoryTerrain;
	end
end

return LightingConfigManager;