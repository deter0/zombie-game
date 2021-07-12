-- Settings Manager
-- Deter
-- July 4, 2021

local DefaultSettings = {
    Graphics = {
        {
            Name = "Wind Effects",
            Type = "Checkbox",
            Order = 1,
            DefaultValue = true,
            Description = "Trees, bushes, grass, etc. will shake naturally when enabled. Average performance impact ~1.8%"
        },
        {
            Name = "Wind Noise Iterations",
            Type = "Slider",
            If = "Wind Effects",
            Order = 2,
            DefaultValue = 6,
            Range = NumberRange.new(1, 8),
            Description = "How many iterations of noises are calculated for wind effects, lower will result in more unnatural results more will require more computer power but will produce better visuals. Average performance impact ~.4%"
        },
        {
            Name = "Wind Streaming Radius",
            Type = "Slider",
            Range = NumberRange.new(30, 400),
            Order = 3,
            If = "Wind Effects",
            DefaultValue = 250,
            -- DefaultValue = 
            Description = "How close objects need to be to be effected ny wind. Average performance impact ~1%"
        },
        {
            Name = "Interactive Beams",
            Type = "Checkbox",
            DefaultValue = true,
            Description = "Deterimines if beams will be dynamic or not. Average performance impact ~.2%"
        },
        {
            Name = "Interactive Beams Update Tick",
            Type = "Slider",
            DefaultValue = .3,
            Range = NumberRange.new(0, 1),
            If = "Interactive Beams",
            Description = "Determines how fast interactive beams update. Average performance impact ~.1%"
        },
        {
            Name = "Texture Quality",
            Type = "Selection",
            Order = 4,
            DefaultValue = "Ultra",
            Values = {"Low", "Medium", "High", "Ultra"},
            Description = "Higher texture quality will lead to more memory usage but textures will be more blurry, please note that this doesn't affect PBR materials as roblox does not allow us to change textures on the fly. (Performance affects may only be noticable apon a restart of the game :: Low = 256px, Medium = 512, High = 756, Ultra = 1024)"
        },
        {
            Name = "Low Quaility Models",
            Type = "Checkbox",
            Order = 5,
            DefaultValue = false,
            Description = "Low quaility models are more performant with less vertices to render. (Please note that there might be some issues with using this mode)"
        },
        {
            Name = "Blood deforms with surface",
            Type = "Checkbox",
            Order = 6,
            DefaultValue = true,
            Description = "Currently roblox mesh deformation makes a big performance impact. Maybe they'll fix it in the future. This may cause some fps (60 -> 55) drops when changing blood's bones' positions for a split second."
        }
    },
};

local SettingsManager = {
    Settings = DefaultSettings
};

function SettingsManager:Start()
	-- TODO: Settings saving & loading
end

function SettingsManager:GetSettings()
	return self.Settings;
end

return SettingsManager;