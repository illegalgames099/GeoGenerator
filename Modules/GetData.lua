-- Gets Data from apis

-- Modules
local WidgetModule = require(script.Parent.WidgetModule)
local Coordinates = require(script.Parent.Coordinates)
local Triangle = require(script.Parent.Triangle)
local Elevation = require(script.Parent.Elevation)
local CreatePart = require(script.Parent.CreatePart)

-- Services
local HS = game:GetService("HttpService")
local plugin = script:FindFirstAncestorWhichIsA("Plugin")

local CACHE_SETTING_KEY = "GeoGeneratorHttpCacheV1"
local CACHE_SCHEMA_VERSION = 2
local MAX_PERSISTED_CACHE_CHARS = 180000
local MAX_OSM_CHUNK_DEGREES = 0.01

local memoryCache = {}
local persistentCacheLoaded = false
local persistentCache = {}


local function rN(num: number, numDecimalPlaces: number)
	return tonumber(string.format("%." .. (numDecimalPlaces or 0) .. "f", num))
end

local function cacheKey(prefix: string, key: string)
	return prefix..":"..CACHE_SCHEMA_VERSION..":"..key
end

local function loadPersistentCache()
	if persistentCacheLoaded then return end
	persistentCacheLoaded = true
	if not plugin then return end
	local encoded = plugin:GetSetting(CACHE_SETTING_KEY)
	if type(encoded) ~= "string" or encoded == "" then return end
	local success, decoded = pcall(function() return HS:JSONDecode(encoded) end)
	if success and type(decoded) == "table" then persistentCache = decoded end
end

local function getCachedResponse(key: string)
	if memoryCache[key] then return memoryCache[key], "memory" end
	loadPersistentCache()
	local cached = persistentCache[key]
	if cached and cached.response then
		memoryCache[key] = cached.response
		return cached.response, "settings"
	end
	return nil
end

local function setCachedResponse(key: string, response: string)
	memoryCache[key] = response
	if not plugin or #response > MAX_PERSISTED_CACHE_CHARS then return end
	loadPersistentCache()
	persistentCache[key] = { response = response, created = os.time() }
	local success, encoded = pcall(function() return HS:JSONEncode(persistentCache) end)
	if success and #encoded <= MAX_PERSISTED_CACHE_CHARS then plugin:SetSetting(CACHE_SETTING_KEY, encoded) end
end

local function splitBBox(south: number, west: number, north: number, east: number, maxDegrees: number)
	local chunks = {}
	local latSpan = math.max(0.000001, north - south)
	local lonSpan = math.max(0.000001, east - west)
	local latSteps = math.max(1, math.ceil(latSpan / maxDegrees))
	local lonSteps = math.max(1, math.ceil(lonSpan / maxDegrees))
	for latIndex = 0, latSteps - 1 do
		local chunkSouth = south + latSpan * latIndex / latSteps
		local chunkNorth = south + latSpan * (latIndex + 1) / latSteps
		for lonIndex = 0, lonSteps - 1 do
			local chunkWest = west + lonSpan * lonIndex / lonSteps
			local chunkEast = west + lonSpan * (lonIndex + 1) / lonSteps
			table.insert(chunks, {
				coords = tostring(rN(chunkSouth, 5))..","..tostring(rN(chunkWest, 5))..","..tostring(rN(chunkNorth, 5))..","..tostring(rN(chunkEast, 5)),
			})
		end
	end
	return chunks
end

local function mergeElements(target: {any}, seen: {[string]: boolean}, elements: {any})
	for _,element in elements do
		local key = tostring(element.type)..":"..tostring(element.id)
		if not seen[key] then
			seen[key] = true
			table.insert(target, element)
		end
	end
end


local SENTRY_DNS = "https://eb659e634e4f9d39207eab0dace42488@o4510438574653440.ingest.de.sentry.io/4510438593790032"
local SENTRY_KEY = "eb659e634e4f9d39207eab0dace42488"
local SENTRY_HOST = "o4510438574653440.ingest.de.sentry.io"
local SENTRY_PROJECT = "4510438593790032"

-- Sentry is used to log errors on an online dashboard
local function sendToSentry(message: string, extra: any)
	
	warn("An error occurred while using GeoGenerator, it has been sent to the developers to investigate.")
	
	local payload = {
		message = message,
		extra = extra
	}
	
	local json = HS:JSONEncode(payload)
	
	local url = ("https://%s/api/%s/store/?sentry_key=%s"):format(
		SENTRY_HOST,
		SENTRY_PROJECT,
		SENTRY_KEY
	)
	
	local success, response = pcall(function()
		HS:PostAsync(url, json, Enum.HttpContentType.ApplicationJson)
	end)
	
	if not success then
		print(response)
	end
	
end


local function getV3(result: any, offsetVector: Vector2, worldScale: number)
	
	local height = result["elevation"]
	local lat = result["location"]["lat"]
	local lon = result["location"]["lng"]

	if not height then
		height = 0
	end

	--convert meters to studs
	height = height * 3.57 * worldScale

	local v2 = Coordinates.toRobloxOffset(lat, lon, offsetVector.X, offsetVector.Y)
	local v3 = Vector3.new(v2.X,height,v2.Y)

	return v3
	
end


local function getOSM(coords: string)
	local timeout = 300
	local key = cacheKey("osm", coords)
	local cachedResponse = getCachedResponse(key)
	local startedHttp = os.clock()
	local response

	if cachedResponse then
		response = cachedResponse
	else
		local query = "[out:json][timeout:".. timeout .."];"..
			"("..
			"way[building]("..coords..");"..
			"way[building:part]("..coords..");"..
			"way[highway]("..coords..");"..
			"way[railway]("..coords..");"..
			"way[landuse]("..coords..");"..
			"way[natural]("..coords..");"..
			"way[leisure]("..coords..");"..
			"way[amenity]("..coords..");"..
			"way[waterway]("..coords..");"..
			"way[barrier]("..coords..");"..
			"rel[!network]("..coords..");"..
			")->.a;(._;>;);out body qt;"
		local url = "https://overpass-api.de/api/interpreter?data="..HS:UrlEncode(query)
		local success
		success, response = pcall(function() return HS:GetAsync(url) end)
		if not success then
			sendToSentry("get osm failed", response)
			return
		end
		setCachedResponse(key, response)
	end

	local data = HS:JSONDecode(response)
	local responseSize = rN(string.len(tostring(response))/1000000,3).."MB"
	local responseTime = os.clock()-startedHttp
	return data["elements"], responseSize, responseTime, cachedResponse ~= nil
end

local function getElevation(corners1: {Vector2} ,corners2: {Vector2}, offsetVector: Vector2, loadingWidget: any, centerLat: number, centerLon: number, worldScale: number)
	
	if not workspace:FindFirstChild("World") then
		local world = Instance.new("Folder",workspace)
		world.Name = "World"
	end
	
	
	local startedHttp = os.clock()
	local totalJSONsize = 0
	local totalLocations = 0
	
	local totalChains = 0
	local usedChains = 0

	local elevation = {}

	local resolution = 0.0003
	
	-- The terrain api has a limit of 100 locations per request
	local limitPerUrl = 100
	
	-- The terrain api has a limit of 1 request per second
	local waitInterval = 1.1
	
	local rad_lat = math.rad(corners1[1].X)

	-- Calculate the scale factor using the Mercator projection formula
	-- further from the equator we get, the more stretched out cooridnates become, so we need to correct it
	local scale_factor = 1 / math.cos(rad_lat)
	
	local resLat = resolution
	local resLon = resolution * scale_factor

	-- Get a point in the middle of one of the parts that serves as an offset for all elevations
	local url = "https://api.opentopodata.org/v1/aster30m?locations="
	local centerUrl = url .. tostring(centerLat) .. "," .. tostring(centerLon)
	
	local success, response
	
	do
		
		local attempts = 0
		
		while true do

			local cachedCenter = getCachedResponse(cacheKey("elevation", centerUrl))
			if cachedCenter then
				success = true
				response = cachedCenter
			else
				success, response = pcall(function() return HS:GetAsync(centerUrl) end)
				if success then setCachedResponse(cacheKey("elevation", centerUrl), response) end
			end
			
			attempts += 1

			if success then
				break
			else
				warn(response)
			end
			
			if attempts > 10 then
				sendToSentry("get terrain midpoint failed, too many attempts", response)
			end

			task.wait(waitInterval)

		end
		
	end
	
	
	
	local centerResponseT = HS:JSONDecode(response)
	local centerV3 = getV3(centerResponseT["results"][1], offsetVector, worldScale)
	local elevationOffset = -centerV3.Y
	
	Elevation.setElevationOffset(elevationOffset+300)
	
	local neededData: {
		{
			longitudes: {number},
			latitudes: {number},
			longitudeChains: {string},
			latitudeChains: {string},
		}
	} = {}
	
	local Maps = {}

	for i = 1, #corners1 do
		
		neededData[i] = { 
			longitudes = {},
			latitudes = {},
			longitudeChains = {},
			latitudeChains = {}
		}
		
		local limit = 0
		local cur = 0
		
		local corner1 = corners1[i]
		local corner2 = corners2[i]
		
		local diffX = corner1.X - corner2.X
		local diffY = corner2.Y - corner1.Y
		
		local nStepsX = math.max(1, math.floor(diffX / resLat + 0.5))
		local stepX = diffX / nStepsX
		local nStepsY = math.max(1, math.floor(diffY / resLon + 0.5))
		local stepY = diffY / nStepsY
		
		for j = 0, nStepsX do
			for k = 0, nStepsY do
				local lat = corner2.X + stepX * j
				local lon = corner1.Y + stepY * k
				
				table.insert(neededData[i].latitudes,lat)
				table.insert(neededData[i].longitudes,lon)
				totalLocations += 1
			end
		end

		local t = {}
		totalChains += 1
		for j,lat in neededData[i].latitudes do
			if (j - 1) % limitPerUrl == 0 and j ~= 1 then
				
				limit += 1
				totalChains += 1
				
				table.insert(neededData[i].latitudeChains,t)
				t = {}
				
			end
			table.insert(t,lat)
		end
		
		table.insert(neededData[i].latitudeChains,t)

		local t = {}
		for j,lon in neededData[i].longitudes do
			if (j - 1) % limitPerUrl == 0 and j ~= 1 then
				table.insert(neededData[i].longitudeChains,t)
				t = {}
			end
			table.insert(t,lon)
		end
		
		table.insert(neededData[i].longitudeChains,t)

	end
	
	
	local balls = {}
	
	for i = 1, #corners1 do
		
		local Legend = {}
		local Map = {}
		
		for j = 1, #neededData[i].latitudeChains do
			
			local latitudes = neededData[i].latitudeChains[j]
			local longitudes = neededData[i].longitudeChains[j]
			
			-- Need to define the url every loop iteration so the old locations get recycled
			local url = "https://api.opentopodata.org/v1/aster30m?locations="

			local n = #latitudes
			for k = 1,n do
			
				local lon = longitudes[k]
				local lat = latitudes[k]

				url = url .. lat .. "," .. lon

				if k ~= n then
					url = url .. "|"
				end
			end

			url = url .. "&interpolation=cubic"


			local success, response
			local failures = 0

			while true do

				-- Make the HTTP GET request
				local cachedElevation = getCachedResponse(cacheKey("elevation", url))
				if cachedElevation then
					success = true
					response = cachedElevation
				else
					success, response = pcall(function() return HS:GetAsync(url) end)
					if success then setCachedResponse(cacheKey("elevation", url), response) end
				end

				if success then
					usedChains += 1
					
					local secondsLeft = totalChains - usedChains * 1.1
					local timeLeft
					if secondsLeft > 59 then
						local minutes = math.round(secondsLeft / 60)
						if minutes == 1 then
							timeLeft = tostring(minutes) .. " minute"
						else
							timeLeft = tostring(minutes) .. " minutes"
						end
					else
						timeLeft = "Less than 1 minute"
					end

					loadingWidget:ChangeText("Street data loaded successfully! \n Downloading elevation data... \n "..tostring(usedChains).."/"..tostring(totalChains).. "\n Time left: "..timeLeft)
					break
				else
					failures += 1
					
					if failures > 30 then
						WidgetModule.error("Elevation data failed, try again later")
						
						-- Send the unsuccessful response to a sentry dashboard I can monitor
						sendToSentry("get terrain failed, too many failures", response)
						
						return
					end
				end

				task.wait(waitInterval)

			end
			

			if success then

				totalJSONsize += string.len(response)

				response = HS:JSONDecode(response)

				for _,result in response["results"] do
					local height = result["elevation"]
					local lat = result["location"]["lat"]
					local lon = result["location"]["lng"]

					if not height then
						height = 0
					end

					-- Convert meters to studs
					height = height * 3.57 * worldScale

					local v2 = Coordinates.toRobloxOffset(lat, lon, offsetVector.X, offsetVector.Y)
					local v3 = Vector3.new(v2.X,height,v2.Y)


					if not Legend[tostring(lat)] then
						local newIndex = #Map + 1
						Legend[tostring(lat)] = newIndex
						Map[newIndex] = {}
					end
					local index = Legend[tostring(lat)]
					table.insert(Map[index],{
						["lat"] = lat,
						["lon"] = lon,
						["v3"] = v3
					})

					-- Visualization for debuging purposes
					local visualize = false
					
					if visualize then
						
						local part = Instance.new("Part")
						part.Shape = "Ball"
						part.Size = Vector3.new(20,20,20)
						part.Color = Color3.new(0.180392, 0.639216, 0.121569)
						part.Position = v3
						part.Anchored = true
						part.Parent = workspace.World

						table.insert(balls,part)
						
					end

				end
			end
			
		end
		
		table.insert(Maps, Map)
		
	end
	
	for _,part: Part in balls do
		part:Destroy()
	end
	
	local responseSize = rN(totalJSONsize/1000000,3).."MB"
	local responseTime = os.clock()-startedHttp
	

	return Maps, responseTime
end


local function getData(corners1: {Vector2}, corners2: {Vector2}, offsetVector: Vector2, elevationMode: string, centerLat: number, centerLon: number, worldScale: number)
	
	--sendToSentry("sentry test", {sup="ayo"})
	
	-- Initializing the loading widget
	local loadingWidget = WidgetModule.loading("Downloading street data...")
	local datas = {}
	
	local totalElevationResponseTime = 0
	local totalStreetResponseTime = 0
	
	for i = 1, #corners1 do
		
		local corner1 = corners1[i]
		local corner2 = corners2[i]
		
		local south = math.min(corner1.X, corner2.X)
		local north = math.max(corner1.X, corner2.X)
		local west = math.min(corner1.Y, corner2.Y)
		local east = math.max(corner1.Y, corner2.Y)
		local chunks = splitBBox(south, west, north, east, MAX_OSM_CHUNK_DEGREES)
		local elements = {}
		local seenElements = {}

		for chunkIndex, chunk in chunks do
			loadingWidget:ChangeText("Downloading street data...\nChunk "..chunkIndex.."/"..#chunks)
			local chunkElements, SresponseSize, SresponseTime = getOSM(chunk.coords)
			if chunkElements then
				totalStreetResponseTime += SresponseTime
				mergeElements(elements, seenElements, chunkElements)
			end

			if not chunkElements then
				loadingWidget:Kill()
				local streetDataFailedMessage = "Failed to get street data, this could mean:\n"
					.. "• No internet connection\n"
					.. "• Area you are trying to generate is too large\n"
					.. "• You have downloaded a lot of data and are being rate limited, try again in a few minutes"
				WidgetModule.error(streetDataFailedMessage)
				return
			end

			task.wait()
		end

		datas[i] = {
			elements = elements
		}
	end
	
	-- Elevation data
	loadingWidget:ChangeText("Street data loaded successfully! \n Downloading elevation data...")

	if elevationMode ~= "flat" then

		local elevations, EresponseTime = getElevation(corners1, corners2, offsetVector, loadingWidget, centerLat, centerLon, worldScale)
		if elevations then
			totalElevationResponseTime += EresponseTime
		end

		if not elevations then
			loadingWidget:Kill()
			WidgetModule.error("Failed to get Elevation data, check your internet and try again.")
			return
		end

		for i,el in elevations do
			datas[i].elevation = el
		end

	end
	
	if elevationMode == "flat" then
		loadingWidget:FinishLoading("Data loaded successfully! \n  Street Data: "..rN(totalStreetResponseTime,3).."s")
	else
		loadingWidget:FinishLoading("Data loaded successfully! \n  Street Data: "..rN(totalStreetResponseTime,3).."s \n Elevation Data: "..rN(totalElevationResponseTime,3).."s")
	end
	

	for _,data in datas do
		if data.elevation then
			Elevation.addMapToAllMaps(data.elevation)
		end
	end
	
	return datas
end

return getData


--[[
	
	--CURRENT overpass turbo prompt, KEEP IT HERE
	
	[out:json][timeout:25];
	(node({{bbox}});
	way({{bbox}});
	)->.a;
	out body;>;out skel qt;
	(rel[!network](bw.a)({{bbox}}););out body;
	
	
	--Old urls:
	
	local url = "https://overpass-api.de/api/interpreter?data=[out:json];(node("..coords..");way("..coords.."););out body;"
	local url = "https://overpass-api.de/api/interpreter?data=[out:json];(way("..coords.."););out body;"

]]

