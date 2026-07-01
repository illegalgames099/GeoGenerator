-- ColorUtils.lua
-- Parses OSM building/roof colour + material tags (building:colour, roof:colour,
-- building:material, roof:material) into Roblox Color3 / Enum.Material values.
-- Returns nil on anything it can't confidently parse, so callers can fall back
-- to the EditableModules defaults.

local ColorUtils = {}

-- Common OSM colour names (hex values are not always used in the wild)
ColorUtils.NamedColors = {
	["red"] = Color3.fromRGB(180, 40, 40),
	["white"] = Color3.fromRGB(235, 235, 230),
	["black"] = Color3.fromRGB(30, 30, 30),
	["grey"] = Color3.fromRGB(140, 140, 140),
	["gray"] = Color3.fromRGB(140, 140, 140),
	["silver"] = Color3.fromRGB(190, 190, 190),
	["brown"] = Color3.fromRGB(110, 75, 50),
	["tan"] = Color3.fromRGB(190, 170, 130),
	["beige"] = Color3.fromRGB(210, 195, 165),
	["cream"] = Color3.fromRGB(225, 215, 185),
	["yellow"] = Color3.fromRGB(210, 180, 60),
	["orange"] = Color3.fromRGB(200, 120, 50),
	["green"] = Color3.fromRGB(80, 120, 80),
	["blue"] = Color3.fromRGB(70, 100, 140),
	["gold"] = Color3.fromRGB(190, 160, 80),
	["copper"] = Color3.fromRGB(120, 150, 130), -- oxidized copper green-grey
	["pink"] = Color3.fromRGB(210, 160, 170),
	["purple"] = Color3.fromRGB(120, 90, 130),
}

-- OSM building:material / roof:material -> Roblox Enum.Material
ColorUtils.MaterialMap = {
	["brick"] = Enum.Material.Brick,
	["bricks"] = Enum.Material.Brick,
	["concrete"] = Enum.Material.Concrete,
	["cement_block"] = Enum.Material.Concrete,
	["glass"] = Enum.Material.Glass,
	["glass_mosaic"] = Enum.Material.Glass,
	["curtain_wall"] = Enum.Material.Glass,
	["wood"] = Enum.Material.Wood,
	["timber_framing"] = Enum.Material.WoodPlanks,
	["stone"] = Enum.Material.Rock,
	["limestone"] = Enum.Material.Limestone,
	["sandstone"] = Enum.Material.Sandstone,
	["granite"] = Enum.Material.Granite,
	["marble"] = Enum.Material.Marble,
	["basalt"] = Enum.Material.Basalt,
	["plaster"] = Enum.Material.SmoothPlastic,
	["stucco"] = Enum.Material.SmoothPlastic,
	["render"] = Enum.Material.SmoothPlastic,
	["plastic"] = Enum.Material.Plastic,
	["metal"] = Enum.Material.Metal,
	["steel"] = Enum.Material.Metal,
	["aluminium"] = Enum.Material.Metal,
	["aluminum"] = Enum.Material.Metal,
	["corrugated_steel"] = Enum.Material.CorrodedMetal,
	["copper"] = Enum.Material.Metal,
	["tile"] = Enum.Material.Slate,
	["roof_tiles"] = Enum.Material.Slate,
	["tiles"] = Enum.Material.Slate,
	["slate"] = Enum.Material.Slate,
	["asphalt"] = Enum.Material.Asphalt,
	["tar_paper"] = Enum.Material.Asphalt,
	["gravel"] = Enum.Material.Pebble,
	["thatch"] = Enum.Material.Grass,
	["grass"] = Enum.Material.Grass,
	["fabric"] = Enum.Material.Fabric,
	["membrane"] = Enum.Material.Fabric,
}

-- Parses a hex colour ("#rrggbb", "#rgb", "rrggbb") or a known colour name.
-- OSM sometimes lists multiple semicolon-separated colours for striped/patterned
-- buildings -- we just take the first one.
function ColorUtils.parseColor(input: string?): Color3?

	if not input or input == "" then
		return nil
	end

	local first = input:match("^[^;]+")
	if not first then
		return nil
	end

	first = first:gsub("%s+", ""):lower()

	local hex6 = first:match("^#?(%x%x%x%x%x%x)$")
	if hex6 then
		local r = tonumber(hex6:sub(1, 2), 16)
		local g = tonumber(hex6:sub(3, 4), 16)
		local b = tonumber(hex6:sub(5, 6), 16)
		return Color3.fromRGB(r, g, b)
	end

	local hex3 = first:match("^#?(%x%x%x)$")
	if hex3 then
		local r = tonumber(hex3:sub(1, 1):rep(2), 16)
		local g = tonumber(hex3:sub(2, 2):rep(2), 16)
		local b = tonumber(hex3:sub(3, 3):rep(2), 16)
		return Color3.fromRGB(r, g, b)
	end

	return ColorUtils.NamedColors[first]

end

-- Parses an OSM material tag into an Enum.Material, taking the first value
-- from a semicolon-separated list if present.
function ColorUtils.parseMaterial(input: string?): Enum.Material?

	if not input or input == "" then
		return nil
	end

	local first = input:match("^[^;]+")
	if not first then
		return nil
	end

	first = first:gsub("%s+", ""):lower()

	return ColorUtils.MaterialMap[first]

end

-- Returns a darker version of a colour, used to auto-derive a roof colour
-- from the wall colour when no roof:colour tag or override is present.
function ColorUtils.darken(c: Color3, amount: number): Color3
	amount = amount or 0.2
	return Color3.new(c.R * (1 - amount), c.G * (1 - amount), c.B * (1 - amount))
end

return ColorUtils
