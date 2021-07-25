local DebrisService = game:GetService("Debris");
local AudioModule = {
    Cached = {}
};

function AudioModule:GetInstanceFromId(id:String)
    if (self.Cached[id]) then
        local Found;

        for _, Sound in ipairs(self.Cached[id]) do
            if (not Sound.IsPlaying) then
                Found = Sound;
                break;
            end
        end

        if (not Found) then
            local Audio = Instance.new("Sound");
            Audio.SoundId = id;
            Audio.Name = id;
            Audio.Parent = script;

            table.insert(self.Cached[id], Audio);
            Found = Audio;
        end

        return Found;
    end

    local Audio = Instance.new("Sound");
    Audio.SoundId = id;
    Audio.Name = id;
    Audio.Parent = script;

    self.Cached[id] = {Audio};

    return Audio;
end

return AudioModule;