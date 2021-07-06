local DebrisService = game:GetService("Debris");
local AudioModule = {
    Cached = {}
};

function AudioModule:GetInstanceFromId(id:String)
    if (self.Cached[id]) then
        return self.Cached[id];
    end

    local Audio = Instance.new("Sound");
    Audio.SoundId = id;
    Audio.Name = id;
    Audio.Parent = script;

    self.Cached[id] = Audio;

    return Audio;
end

return AudioModule;