-- GetExtraBuildings.lua
-- Imports a small, pre-clipped GeoJSON of building footprints (e.g. exported
-- from Microsoft's Global ML Building Footprints via export_extra_buildings.py)
-- and generates them through the same WayOperations.building pipeline used
-- for OSM buildings, so they get the same wall/roof fidelity.
--
-- This does NOT talk to Microsoft's servers directly -- their dataset is
-- distributed as multi-GB per-country/quadkey files with no bbox query API,
-- which HttpService can't handle. Instead this fetches whatever small GeoJSON
-- URL you point it at (host the export script's output on a Gist, your own
-- server, etc).
--
-- Deduping against OSM is done twice on purpose: once heavily in the Python
-- export script (polygon-overlap test against real OSM building geometry),
-- and once cheaply here (centroid-distance test against buildings already
-- placed by this WorldLoader session) as a safety net in case you reuse an
-- export across slightly different areas/OSM edits.

local module = {}

local Coordinates = require(script.Parent:WaitForChild("Coordinates"))
local WayOperations = require(script.Parent:WaitForChild("WayOperations"))

local HS = game:GetService("HttpService")
local CS = game:GetService("CollectionService")


-- Builds a flat list of {x,z} centroids for buildings already generated this
-- session, used as a cheap dedupe safety net against the GeoJSON import.
local function collectExistingCentroids(Corefolder: Instance): {Vector3}

	local centroids = {}

	local buildingsFolder = Corefolder:FindFirstChild("Buildings")
	if not buildingsFolder then
		return centroids
	end

	for _,model in buildingsFolder:GetChildren() do
		if model:IsA("Model") then
			local ok, pivot = pcall(function()
				return model:GetPivot()
			end)
			if ok and pivot then
				table.insert(centroids, pivot.Position)
			end
		end
	end

	return centroids

end


local function ringToPositions(ring: {any}, offsetVector: Vector2): {Vector3}

	local positions = {}

	for _,coord in ring do
		-- GeoJSON coordinates are [lon, lat]
		local lon, lat = coord[1], coord[2]
		local v2 = Coordinates.toRobloxOffset(lat, lon, offsetVector.X, offsetVector.Y)
		table.insert(positions, Vector3.new(v2.X, 0, v2.Y))
	end

	return positions

end


local function ringCentroid(positions: {Vector3}): Vector3

	local sum = Vector3.new(0,0,0)
	local n = math.max(#positions - 1, 1) -- last point duplicates the first

	for i = 1, n do
		sum += positions[i]
	end

	return sum / n

end


-- url: string GeoJSON endpoint (see export_extra_buildings.py)
-- offsetVector: same Vector2 passed into GenerateWorld, used to align coordinates
-- Map, elevationMode, GenerationRules: pass through unchanged from GenerateWorld
-- WayProperties: the resolved property table from GenerateWorld (so extra
--   buildings respect your Building UI settings / EditableModules defaults)
-- Corefolder: workspace.World, used for dedupe + parenting
-- dedupeRadius: studs; extra buildings whose centroid lands within this
--   distance of an existing building are skipped. Defaults to 6 studs.
function module.generate(url: string, offsetVector: Vector2, Map: any, elevationMode: string, GenerationRules: any, WayProperties: any, Corefolder: Instance, dedupeRadius: number?)

	dedupeRadius = dedupeRadius or 6

	local success, response = pcall(function()
		return HS:GetAsync(url)
	end)

	if not success then
		warn("GetExtraBuildings: failed to fetch '"..tostring(url).."': "..tostring(response))
		return 0
	end

	local ok, data = pcall(function()
		return HS:JSONDecode(response)
	end)

	if not ok or not data or not data.features then
		warn("GetExtraBuildings: response was not valid GeoJSON")
		return 0
	end

	local properties = WayProperties["building"] and WayProperties["building"]["nil"]
	if not properties then
		warn("GetExtraBuildings: no building properties found in WayProperties, aborting")
		return 0
	end

	local existingCentroids = collectExistingCentroids(Corefolder)

	local buildingsFolder = Corefolder:FindFirstChild("Buildings")
	if not buildingsFolder then
		buildingsFolder = Instance.new("Folder", Corefolder)
		buildingsFolder.Name = "Buildings"
	end

	local generatedCount = 0

	for i,feature in data.features do

		local geom = feature.geometry
		if not geom or geom.type ~= "Polygon" or not geom.coordinates or not geom.coordinates[1] then
			continue
		end

		local positions = ringToPositions(geom.coordinates[1], offsetVector)

		if #positions < 4 then -- need at least a closed triangle (3 unique + closing point)
			continue
		end

		local centroid = ringCentroid(positions)

		-- Cheap dedupe safety net against buildings placed earlier this session
		local tooClose = false
		for _,c in existingCentroids do
			if (Vector3.new(centroid.X,0,centroid.Z) - Vector3.new(c.X,0,c.Z)).Magnitude < dedupeRadius then
				tooClose = true
				break
			end
		end
		if tooClose then
			continue
		end

		local featureProps = feature.properties or {}
		local tags = {
			["building"] = "yes",
		}
		if featureProps.height then
			tags["height"] = tostring(featureProps.height)
		end

		local model = Instance.new("Model")
		model.Name = "ExtraBuilding"

		local ok2, parts = pcall(function()
			return WayOperations["building"](tags, model, properties, positions, {}, GenerationRules, Map, elevationMode)
		end)

		if not ok2 or not parts or #parts == 0 then
			model:Destroy()
			continue
		end

		model.Parent = buildingsFolder
		CS:AddTag(model, "MSFootprint") -- lets you bulk-select/remove these later, separate from "OSM_id:*"

		table.insert(existingCentroids, centroid)
		generatedCount += 1

		if generatedCount % 15 == 0 then
			task.wait()
		end

	end

	return generatedCount

end


return module
