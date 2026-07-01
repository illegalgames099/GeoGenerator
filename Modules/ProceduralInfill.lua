-- ProceduralInfill.lua
-- Fills in landuse polygons (residential/commercial/retail/industrial) that
-- have few or no OSM-mapped buildings inside them, by grid-subdividing the
-- polygon into lots and generating a simple building on lots that don't
-- already overlap a real OSM building.
--
-- Unlike GetExtraBuildings.lua, this needs NO external data source, NO script
-- to run, and NO file to host: the WorldLoader Overpass query already pulls
-- every tagged way in the bbox unfiltered, so landuse polygons are already
-- sitting in `data["elements"]` whenever this runs. This is purely a
-- geometry pass over data you already downloaded.
--
-- Tradeoff vs GetExtraBuildings: these are NOT real buildings -- there's no
-- actual structure at these coordinates, just a plausible filler box sized
-- and colored to match the surrounding landuse type. Good for visual density
-- when driving through a neighborhood; not useful if you care about accuracy.

local module = {}

local Objects = script.Parent.Parent.Objects
local Values = Objects.Values

local PolygonTriangulation = require(script.Parent:WaitForChild("PolygonTriangulation"))
local WayOperations = require(script.Parent:WaitForChild("WayOperations"))

local CS = game:GetService("CollectionService")

-- Landuse tag -> filler building profile. Residential gets small,
-- 1-3 story houses; commercial/retail gets flatter wider boxes; industrial
-- gets big single-story sheds. Palette is a small hex list so procedural
-- buildings aren't all identical -- they're read by WayOperations.building's
-- existing building:colour tag support, no new color code needed.
local LANDUSE_PROFILES = {
	residential = {
		lotSize = 14, -- meters, grid cell size
		footprintMin = 7, footprintMax = 11,
		levelsMin = 1, levelsMax = 2,
		palette = {"#c9b79c", "#b5a48a", "#d8cfc0", "#a68a6d", "#c2b8a3"},
	},
	commercial = {
		lotSize = 20,
		footprintMin = 12, footprintMax = 18,
		levelsMin = 1, levelsMax = 4,
		palette = {"#9aa5ad", "#b0b8bd", "#8c99a1", "#c4ccd1"},
	},
	retail = {
		lotSize = 18,
		footprintMin = 10, footprintMax = 16,
		levelsMin = 1, levelsMax = 2,
		palette = {"#c7c1b8", "#a9a49b", "#d1ccc2"},
	},
	industrial = {
		lotSize = 26,
		footprintMin = 16, footprintMax = 24,
		levelsMin = 1, levelsMax = 1,
		palette = {"#8f8f8f", "#7d7d7d", "#9c9c9c"},
	},
}

-- ===== geometry helpers (all operate on X/Z, same convention as the rest of WayOperations) =====

local function pointInPolygon(x: number, z: number, ring: {Vector3}): boolean

	local inside = false
	local n = #ring
	local j = n

	for i = 1, n do
		local xi, zi = ring[i].X, ring[i].Z
		local xj, zj = ring[j].X, ring[j].Z

		if ((zi > z) ~= (zj > z)) and (x < (xj - xi) * (z - zi) / (zj - zi) + xi) then
			inside = not inside
		end

		j = i
	end

	return inside

end

local function wayPositions(way: any, data: any, nodes: any): {Vector3}?

	local positions = {}

	for _,nodeId in way["nodes"] do
		local j = nodes[nodeId]
		if not j then continue end

		local v2 = data["elements"][j]["v2"]
		table.insert(positions, Vector3.new(v2.X, 0, v2.Y))
	end

	if #positions < 3 then
		return nil
	end

	return positions

end

local function polygonBounds(ring: {Vector3})
	local minX, maxX = math.huge, -math.huge
	local minZ, maxZ = math.huge, -math.huge

	for _,p in ring do
		minX = math.min(minX, p.X)
		maxX = math.max(maxX, p.X)
		minZ = math.min(minZ, p.Z)
		maxZ = math.max(maxZ, p.Z)
	end

	return minX, maxX, minZ, maxZ
end


-- data, nodes, ways: same tables built in GenerateWorld.lua (do not rebuild them)
-- GenerationRules, WayProperties, Corefolder, elevationMode: same as GenerateWorld
-- Map: data["elevation"], passed through to WayOperations.building unchanged
function module.generate(data: any, nodes: any, ways: any, GenerationRules: any, WayProperties: any, Corefolder: Instance, elevationMode: string, Map: any)

	local scale = Values.Scale.Value
	local D = 0.28 / scale -- meters -> studs, matches WayOperations/SimpleOperations

	local buildingProperties = WayProperties["building"] and WayProperties["building"]["nil"]
	if not buildingProperties then
		warn("ProceduralInfill: no building properties found, aborting")
		return 0
	end

	-- ===== Pass 1: collect real OSM building footprints (centroid + radius)
	-- so procedural lots never get placed on top of a mapped building. =====
	local existingBuildings = {}

	for id,i in ways do
		local way = data["elements"][i]
		local tags = way["tags"]
		if not tags or (not tags["building"] and not tags["building:part"]) then
			continue
		end

		local positions = wayPositions(way, data, nodes)
		if not positions then continue end

		local centroid = Vector3.new(0,0,0)
		for _,p in positions do
			centroid += p
		end
		centroid /= #positions

		local radius = 0
		for _,p in positions do
			radius = math.max(radius, (p - centroid).Magnitude)
		end

		table.insert(existingBuildings, {centroid = centroid, radius = radius})
	end

	-- ===== Pass 2: walk landuse polygons, grid-subdivide, fill gaps =====
	local buildingsFolder = Corefolder:FindFirstChild("Buildings")
	if not buildingsFolder then
		buildingsFolder = Instance.new("Folder", Corefolder)
		buildingsFolder.Name = "Buildings"
	end

	local placedThisPass = {} -- centroids of procedural buildings placed so far, avoids stacking them on each other
	local generatedCount = 0
	local maxPerPolygon = GenerationRules["Infill Max Per Polygon"] or 60
	local iter = 0

	for id,i in ways do
		local way = data["elements"][i]
		local tags = way["tags"]
		if not tags or not tags["landuse"] then
			continue
		end

		local profile = LANDUSE_PROFILES[tags["landuse"]]
		if not profile then
			continue
		end

		local ring = wayPositions(way, data, nodes)
		if not ring then continue end

		local lotSize = profile.lotSize / D -- studs

		local minX, maxX, minZ, maxZ = polygonBounds(ring)

		local placedInPolygon = 0

		local x = minX
		while x < maxX and placedInPolygon < maxPerPolygon do

			local z = minZ
			while z < maxZ and placedInPolygon < maxPerPolygon do

				-- jitter within the cell so it doesn't look like a perfect grid
				local jitterX = (math.random() - 0.5) * lotSize * 0.4
				local jitterZ = (math.random() - 0.5) * lotSize * 0.4
				local cx = x + lotSize/2 + jitterX
				local cz = z + lotSize/2 + jitterZ

				z += lotSize

				if not pointInPolygon(cx, cz, ring) then
					continue
				end

				local candidate = Vector3.new(cx, 0, cz)

				-- skip if inside/near a real OSM building
				local blocked = false
				for _,b in existingBuildings do
					if (candidate - b.centroid).Magnitude < b.radius + lotSize * 0.5 then
						blocked = true
						break
					end
				end
				if blocked then continue end

				-- skip if too close to a building we already placed this polygon/pass
				for _,p in placedThisPass do
					if (candidate - p).Magnitude < lotSize * 0.7 then
						blocked = true
						break
					end
				end
				if blocked then continue end

				-- ===== build a simple rectangular footprint for this lot =====
				local footprintMeters = profile.footprintMin + math.random() * (profile.footprintMax - profile.footprintMin)
				local halfW = (footprintMeters / D) / 2
				local halfD = (halfW) * (0.7 + math.random() * 0.6) -- non-square, more house-like

				local positions = {
					candidate + Vector3.new(-halfW, 0, -halfD),
					candidate + Vector3.new(halfW, 0, -halfD),
					candidate + Vector3.new(halfW, 0, halfD),
					candidate + Vector3.new(-halfW, 0, halfD),
					candidate + Vector3.new(-halfW, 0, -halfD), -- closing point, matches OSM ring convention
				}

				local levels = math.random(profile.levelsMin, profile.levelsMax)
				local color = profile.palette[math.random(1, #profile.palette)]

				local syntheticTags = {
					["building"] = "yes",
					["building:levels"] = tostring(levels),
					["building:colour"] = color,
				}

				local model = Instance.new("Model")
				model.Name = "InfillBuilding"

				local ok, parts = pcall(function()
					return WayOperations["building"](syntheticTags, model, buildingProperties, positions, {}, GenerationRules, Map, elevationMode)
				end)

				if ok and parts and #parts > 0 then
					model.Parent = buildingsFolder
					CS:AddTag(model, "ProceduralInfill")

					table.insert(placedThisPass, candidate)
					placedInPolygon += 1
					generatedCount += 1

					iter += 1
					if iter % 15 == 0 then
						task.wait()
					end
				else
					model:Destroy()
				end

			end

			x += lotSize

		end

	end

	return generatedCount

end

return module
