--> Credit to uglyburger0

local main = {}

main.SoundIds = {

	Concrete = {
		"rbxassetid://6026529903",
		"rbxassetid://6026529887",
		"rbxassetid://6026529862",
		"rbxassetid://6026529840",
		"rbxassetid://6026529818",
		"rbxassetid://6026529791",
		"rbxassetid://6026529773",
		"rbxassetid://6026529752",
		"rbxassetid://6026529732",
		"rbxassetid://6026529709",
		"rbxassetid://6026529682",
		"rbxassetid://6026529649",
		"rbxassetid://6026529624",
		"rbxassetid://6026529596",
		"rbxassetid://6026529570",
		"rbxassetid://6026529548",
		"rbxassetid://6026529529"
	},

	Dirt = {
		"rbxassetid://6026529510",
		"rbxassetid://6026529479",
		"rbxassetid://6026529455",
		"rbxassetid://6026529426",
		"rbxassetid://6026529403",
		"rbxassetid://6026529380",
		"rbxassetid://6026529353",
		"rbxassetid://6026529332",
		"rbxassetid://6026529302",
		"rbxassetid://6026529285",
		"rbxassetid://6026529263",
		"rbxassetid://6026529241",
		"rbxassetid://6026529218",
		"rbxassetid://6026529201"
	},

	Glass = {
		"rbxassetid://6026529185",
		"rbxassetid://6026529160",
		"rbxassetid://6026529132",
		"rbxassetid://6026529110",
		"rbxassetid://6026529091",
		"rbxassetid://6026529067",
		"rbxassetid://6026529041",
		"rbxassetid://6026529021"
	},

	Gravel = {
		"rbxassetid://6026528992",
		"rbxassetid://6026528968",
		"rbxassetid://6026528938",
		"rbxassetid://6026528910",
		"rbxassetid://6026528890",
		"rbxassetid://6026528867",
		"rbxassetid://6026528838",
		"rbxassetid://6026528810",
		"rbxassetid://6026528783",
		"rbxassetid://6026528757"
	},

	Metal_Chainlink = {
		"rbxassetid://6026528733",
		"rbxassetid://6026528705",
		"rbxassetid://6026528676",
		"rbxassetid://6026528646",
		"rbxassetid://6026528628",
		"rbxassetid://6026528611",
		"rbxassetid://6026528585",
		"rbxassetid://6026528552"
	},

	Metal_Grate = {
		"rbxassetid://6026528156",
		"rbxassetid://6026528216",
		"rbxassetid://6026528188",
		"rbxassetid://6026528244",
		"rbxassetid://6026528266",
		"rbxassetid://6026528287",
		"rbxassetid://6026528308",
		"rbxassetid://6026528332",
		"rbxassetid://6026528357",
		"rbxassetid://6026528385",
		"rbxassetid://6026528410",
		"rbxassetid://6026528441",
		"rbxassetid://6026528469",
		"rbxassetid://6026528496",
		"rbxassetid://6026528524"
	},

	Metal_Solid = {
		"rbxassetid://6026527724",
		"rbxassetid://6026527764",
		"rbxassetid://6026527787",
		"rbxassetid://6026527808",
		"rbxassetid://6026527837",
		"rbxassetid://6026527863",
		"rbxassetid://6026527891",
		"rbxassetid://6026527914",
		"rbxassetid://6026527941",
		"rbxassetid://6026527966",
		"rbxassetid://6026527992",
		"rbxassetid://6026528021",
		"rbxassetid://6026528049",
		"rbxassetid://6026528077",
		"rbxassetid://6026528109",
		"rbxassetid://6026528135"
	},

	Mud = {
		"rbxassetid://6026527485",
		"rbxassetid://6026527515",
		"rbxassetid://6026527542",
		"rbxassetid://6026527565",
		"rbxassetid://6026527590",
		"rbxassetid://6026527619",
		"rbxassetid://6026527643",
		"rbxassetid://6026527701",
		"rbxassetid://6026527665"
	},

	Rubber = {
		"rbxassetid://6026527312",
		"rbxassetid://6026527333",
		"rbxassetid://6026527355",
		"rbxassetid://6026527373",
		"rbxassetid://6026527397",
		"rbxassetid://6026527418",
		"rbxassetid://6026527438",
		"rbxassetid://6026527460"
	},

	Sand = {
		"rbxassetid://6026526986",
		"rbxassetid://6026527009",
		"rbxassetid://6026527039",
		"rbxassetid://6026527068",
		"rbxassetid://6026527096",
		"rbxassetid://6026527126",
		"rbxassetid://6026527161",
		"rbxassetid://6026527185",
		"rbxassetid://6026527213",
		"rbxassetid://6026527233",
		"rbxassetid://6026527251",
		"rbxassetid://6026527280"
	},

	Tile = {
		"rbxassetid://6026526636",
		"rbxassetid://6026526656",
		"rbxassetid://6026526679",
		"rbxassetid://6026526696",
		"rbxassetid://6026526715",
		"rbxassetid://6026526748",
		"rbxassetid://6026526771",
		"rbxassetid://6026526795",
		"rbxassetid://6026526825",
		"rbxassetid://6026526840",
		"rbxassetid://6026526866",
		"rbxassetid://6026526891",
		"rbxassetid://6026526928",
		"rbxassetid://6026526956"
	},

	Wood = {
		"rbxassetid://6026526251",
		"rbxassetid://6026526275",
		"rbxassetid://6026526300",
		"rbxassetid://6026526323",
		"rbxassetid://6026526351",
		"rbxassetid://6026526385",
		"rbxassetid://6026526422",
		"rbxassetid://6026526450",
		"rbxassetid://6026526470",
		"rbxassetid://6026526499",
		"rbxassetid://6026526518",
		"rbxassetid://6026526541",
		"rbxassetid://6026526561",
		"rbxassetid://6026526588",
		"rbxassetid://6026526612"
	},
	
	Snow = {
		"rbxassetid://6045131088",
		"rbxassetid://6045131054",
		"rbxassetid://6045131022",
		"rbxassetid://6045130992",
		"rbxassetid://6045130947",
		"rbxassetid://6045130914",
		"rbxassetid://6045130868",
		"rbxassetid://6045130832",
		"rbxassetid://6045130795",
		"rbxassetid://6045130744",
		"rbxassetid://6045130703",
		"rbxassetid://6045130649"
	}

}

main.MaterialMap = {

	[Enum.Material.Slate] = 		main.SoundIds.Concrete,
	[Enum.Material.Concrete] = 		main.SoundIds.Concrete,
	[Enum.Material.Brick] = 		main.SoundIds.Concrete,
	[Enum.Material.Cobblestone] = 	main.SoundIds.Concrete,
	[Enum.Material.Sandstone] =		main.SoundIds.Concrete,
	[Enum.Material.Rock] = 			main.SoundIds.Concrete,
	[Enum.Material.Basalt] = 		main.SoundIds.Concrete,
	[Enum.Material.CrackedLava] = 	main.SoundIds.Concrete,
	[Enum.Material.Asphalt] = 		main.SoundIds.Concrete,
	[Enum.Material.Limestone] = 	main.SoundIds.Concrete,
	[Enum.Material.Pavement] = 		main.SoundIds.Concrete,

	[Enum.Material.Plastic] = 		main.SoundIds.Tile,
	[Enum.Material.Marble] = 		main.SoundIds.Tile,
	[Enum.Material.Granite] = 		main.SoundIds.Tile,
	[Enum.Material.Neon] = 			main.SoundIds.Tile,

	[Enum.Material.Wood] = 			main.SoundIds.Wood,
	[Enum.Material.WoodPlanks] = 	main.SoundIds.Wood,

	[Enum.Material.CorrodedMetal] = main.SoundIds.Metal_Solid,
	[Enum.Material.DiamondPlate] = 	main.SoundIds.Metal_Solid,
	[Enum.Material.Metal] = 		main.SoundIds.Metal_Solid,

	[Enum.Material.Foil] = 			main.SoundIds.Metal_Grate,

	[Enum.Material.Grass] = 		main.SoundIds.Dirt,
	[Enum.Material.Ground] = 		main.SoundIds.Dirt,
	[Enum.Material.LeafyGrass] = 	main.SoundIds.Dirt,

	[Enum.Material.Sand] = 			main.SoundIds.Sand,
	[Enum.Material.Fabric] = 		main.SoundIds.Sand,
	[Enum.Material.Salt] = 			main.SoundIds.Sand,
	
	[Enum.Material.Snow] = 			main.SoundIds.Snow,

	[Enum.Material.Ice] = 			main.SoundIds.Glass,
	[Enum.Material.Glacier] = 		main.SoundIds.Glass,
	[Enum.Material.Glass] = 		main.SoundIds.Glass,

	[Enum.Material.Pebble] = 		main.SoundIds.Gravel,

	[Enum.Material.SmoothPlastic] = main.SoundIds.Rubber,
	[Enum.Material.ForceField] = 	main.SoundIds.Rubber,

	[Enum.Material.Mud] = 			main.SoundIds.Mud

}

function main:GetTableFromMaterial(EnumItem)
	if typeof(EnumItem) == "string" then -- CONVERSION
		EnumItem = Enum.Material[EnumItem]
	end
	return main.MaterialMap[EnumItem]
end

function main:GetRandomSound(SoundTable)
	return SoundTable[math.random(#SoundTable)]
end

return main