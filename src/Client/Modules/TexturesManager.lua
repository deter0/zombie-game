-- Textures Manager
-- Deter
-- July 1, 2021


local Tag = "DynamicResolution";
local CollectionService = game:GetService("CollectionService");
local ContentProvider = game:GetService("ContentProvider");

local TexturesManager = {
    CurrentQuality = 1024,
    Qualities = {
        ["low"] = 256,
        ["medium"] = 512,
        ["high"] = 756,
        ["ultra"] = 1024
    },

    Objects = {}
};

function TexturesManager:InitObject(Object:Instance)
    local ObjectAttributes = Object:GetAttributes();
    local QualityAbrv = tostring(self.CurrentQuality).."_";

    for AttributeName, _ in pairs(ObjectAttributes) do
        xpcall(function()
            if (string.find(AttributeName, QualityAbrv)) then
                local Property = string.gsub(AttributeName, QualityAbrv, "");
    
                if (Property) then
                    Object:SetAttribute("1024_"..Property, Object[Property]);
                end
            end
        end, function(err)
            warn(err);
        end)
    end
    
    self.Objects[#self.Objects + 1] = Object;
end

function TexturesManager:GetTextureIdFromQuailty(Object:Instance, QualityAbrv:string)
    local ObjectAttributes = Object:GetAttributes();

    for AttributeName, Value in pairs(ObjectAttributes) do
        if (string.find(AttributeName, QualityAbrv)) then
            local Property = string.gsub(AttributeName, QualityAbrv, "");

            if (Property) then
                return Value, AttributeName;
            end
        end
    end
end

function TexturesManager:Start()
    local Tags = CollectionService:GetTagged(Tag);

    for _, TaggedObject:Instance in ipairs(Tags) do
        self:InitObject(TaggedObject);
    end
    CollectionService:GetInstanceAddedSignal(Tag):Connect(function(TaggedObject:Instance)
        self:InitObject(TaggedObject);
    end)
end

function TexturesManager:ResetLoadingQueue()
    if (self.Queue) then
        table.clear(self.Queue);
    end

    self.Queue = {};
end

function TexturesManager:AddToLoadingQueue(ImageId:string, TaggedObject:Instance, Attribute:string)
    if (not self.Queue[ImageId]) then
        warn("Created new spot in queue");

        self.Queue[ImageId] = {{TaggedObject, Attribute}};
    else
        warn("Spot in loading queue already exists");

        self.Queue[ImageId][#self.Queue[ImageId] + 1] = {TaggedObject, Attribute};
    end
end

function TexturesManager:StartQueue(QualityAbrv)
    local ToLoad = {};
    local Set = {};

    for ImageId:string, Objects in pairs(self.Queue) do
        local Id:number = string.gsub(ImageId, "%a", ""):gsub("%p", "");
        Id = tonumber(Id);

        warn(Id);
        if (Id) then
            Set[Id] = Objects;
            ToLoad[#ToLoad + 1] = ImageId;
        else
            warn("No id", ImageId, Id);
        end
    end

    warn("Loading", self.Queue, ToLoad);

    ContentProvider:PreloadAsync(ToLoad, function(ImageId, Status)
        if (Status == Enum.AssetFetchStatus.Success) then
            local Id:number = string.gsub(ImageId, "%a", ""):gsub("%p", "");
            Id = tonumber(Id);

            local ToSet = Set[Id];

            if (ToSet) then
                for _, ObjectData in ipairs(ToSet) do
                    local Object = ObjectData[1];
                    local Attribute = ObjectData[2];

                    local Property = string.gsub(Attribute, QualityAbrv, "");

                    if (Property) then
                        pcall(function()
                            Object[Property] = ImageId;
                        end)
                    else
                        warn("No property found", Property, Attribute, QualityAbrv);
                    end
                end
            end
        end
    end)
end

function TexturesManager:SetQuality(Quality:string|number)
    if (type(Quality) == "string") then
        Quality = self.Qualities[Quality:lower()];
    end

    self.CurrentQuality = Quality;
    local QualityAbrv = tostring(self.CurrentQuality).."_";

    self:ResetLoadingQueue();

    for _, TaggedObject:Instance in ipairs(self.Objects) do
        local TextureId, AttributeName = self:GetTextureIdFromQuailty(TaggedObject, QualityAbrv);

        if (TextureId) then
            self:AddToLoadingQueue(TextureId, TaggedObject, AttributeName);
        else
            warn("no texture id");
        end
    end

    self:StartQueue(QualityAbrv);
end

return TexturesManager;