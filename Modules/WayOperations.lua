-- Modules
local CreatePart = require(script.Parent:WaitForChild("CreatePart"))
local PolygonTriangulation = require(script.Parent:WaitForChild("PolygonTriangulation"))
local Bezier = require(script.Parent:WaitForChild("BezierModule"))
local Triangle = require(script.Parent:WaitForChild("Triangle"))
local ColorUtils = require(script.Parent:WaitForChild("ColorUtils"))

local RayTriangleIntersection = require(script.Parent:WaitForChild("RayTriangleIntersection"))
local SimpleOperations = require(script.Parent:WaitForChild("SimpleOperations"))
local Elevation = require(script.Parent:WaitForChild("Elevation"))

local Objects = script.Parent.Parent.Objects
local Values = Objects.Values

local CS = game:GetService("CollectionService")

local function createTrainTrack(cfrm: CFrame,dist: number,properties: any,GenerationRules: any)
	
	local AssetFolder = Objects.Assets
	
	local RO_SCALE = GenerationRules["Ro-Scale"]
	local RO_SCALE_TIES = GenerationRules["Ro-Scale Ties"]
	local RO_SCALE_BALLAST = GenerationRules["Ro-Scale Ballast"]
	
	if not RO_SCALE then
		RO_SCALE_BALLAST, RO_SCALE_TIES = false, false
	end
	
	-- Divider value, properties are in meters, 1 stud is 0.28cm so we do property/D to determine it in studs 
	local D = 0.28 / Values.Scale.Value

	local Track = Instance.new("Model")
	Track.Name = "Track"

	local gauge = properties.gauge / D

	local tiesWidth = gauge*2

	local ballastWidth = properties.ballast.width/D
	local ballastHeight = properties.ballast.height/D

	if RO_SCALE_BALLAST then
		ballastWidth = 2
		ballastHeight = .3
	end

	local ballast = AssetFolder.MeshParts[properties.ballast.meshpart]:Clone()
	ballast.Color = properties.ballast.color
	ballast.Material = properties.ballast.material
	ballast.Size = Vector3.new(ballastWidth,ballastHeight,dist)
	ballast.CFrame = cfrm * CFrame.new(0,ballast.Size.Y/2,0)
	ballast.Name = "Ballast"
	ballast.Parent = Track
	ballast.CanCollide = false


	Track.PrimaryPart = ballast

	--SHIT CODE WARNING: DIFFERENCE BETWEEM tiesWidth AND tieWidth

	local tieHeight = .1/D --dont use in texture ties
	local tieWidth = .4/D --google said that ties are 9 inches long but fuck that, this looks better
	

	if RO_SCALE_TIES then
		tieWidth = .2
		tieHeight = .1
		tiesWidth = 1.2
	end
	
	if properties.ties.ties3D == true then

		--for i = tieWidth+(dist%tieWidth/2),dist-(dist%tieWidth/2),tieWidth*2.5 do
		for i = tieWidth,dist,tieWidth*2.5 do
			local tie = CreatePart(Track,cfrm*CFrame.new(0,0,(dist/2)-i),Vector3.new(tiesWidth,tieHeight,tieWidth))
			tie.Position = Vector3.new(tie.Position.X,ballast.Position.Y+ballast.Size.Y/2+tie.Size.Y/2,tie.Position.Z)
			tie.Color = properties.ties.color
			tie.Material = properties.ties.material
			tie.Name = "Ties"
		end

	else

		local tieSize = Vector3.new(tiesWidth,.04,dist)

		local tie = CreatePart(Track,cfrm*CFrame.new(0,ballast.Size.Y-.019,0),tieSize)
		tie.Transparency = 1
		tie.Name = "Ties"

		local tiesTexture = AssetFolder.Textures[properties.ties.texture]:Clone()
		tiesTexture.Face = "Top"
		tiesTexture.Parent = tie
		tiesTexture.Transparency = properties.ties.transparency
		tiesTexture.StudsPerTileU = tiesWidth
		tiesTexture.StudsPerTileV = tiesWidth*.4

	end


	local railProps = properties.rails
	local offset = gauge/2
	local railSize = Vector3.new(0.2/D,0.2/D, dist)

	if RO_SCALE then
		
		offset = .3
		railSize = Vector3.new(.4,.3,dist)
		
		for i = -offset,offset,offset*2 do

			local j = -i/offset


			local railCfrm = ballast.CFrame * CFrame.new(i+(j*-1*railSize.X/2),railSize.Y/2 + ballast.Size.Y/2,0)
			
			local rail = CreatePart(Track,railCfrm,railSize,nil,railProps.material)
			rail.Name = "Rail"
			rail.Color = railProps.color
			rail.CanCollide = true
			
			if not properties.ties.ties3D then
				rail.Position += Vector3.new(0,-tieHeight,0)
			end


			if i == -offset then
				rail:SetAttribute("num",1) --determining if its the first or second rail
			else
				rail:SetAttribute("num",2)
			end


			local mesh = AssetFolder.Meshes[railProps.mesh]:Clone()

			mesh.Parent = rail

			if mesh:IsA("BlockMesh") then
				mesh.Scale = Vector3.new(mesh.Scale.X,mesh.Scale.Y,1)
				mesh.Offset = Vector3.new(mesh.Offset.X*-j,mesh.Offset.Y,mesh.Offset.Z)
			else
				mesh.Scale = Vector3.new(mesh.Scale.X,mesh.Scale.Y,dist)
				mesh.Offset = Vector3.new(mesh.Offset.X*j,mesh.Offset.Y,mesh.Offset.Z)
			end
			
		end

	else

		for i = -offset,offset,offset*2 do

			local j = -i/offset


			local railCfrm = ballast.CFrame * CFrame.new(i+(j*-1*railSize.X/2),railSize.Y/2 + ballast.Size.Y/2 + tieHeight,0)
			local rail = CreatePart(Track,railCfrm,railSize,railProps.color,railProps.material)
			rail.Name = "Rail"
			rail.CanCollide = true


			if i == -offset then
				rail:SetAttribute("num",1) --determining if its the first or second rail
			else
				rail:SetAttribute("num",2)
			end


			local mesh = AssetFolder.Meshes[railProps.mesh]:Clone()
			local meshOffset = Vector3.new(0,0,0)

			mesh.Parent = rail
			mesh.Scale = railSize
			mesh.Offset = meshOffset

			if mesh:IsA("BlockMesh") then
				mesh.Scale = Vector3.new(1,1,1)
			end

			--local mesh = game.ReplicatedStorage["OSM Assets"].Meshes[railProps.mesh]:Clone()
			--local meshOffset = Vector3.new(0,mesh.Offset.Y,mesh.Offset.Z)

			--mesh.Parent = rail
			--mesh.Scale = Vector3.new(mesh.Scale.X,mesh.Scale.Y, rail.Size.Z)
			--mesh.Offset = meshOffset

		end

	end



	if GenerationRules["Track Handles"] then
		local handleSize = Vector3.new(ballast.Size.X,ballast.Size.Y+railSize.Y,1/D)

		if GenerationRules["Ro-Scale"] then
			handleSize = Vector3.new(ballast.Size.X,railSize.Y,1)
		end

		for i = -dist/2,dist/2,dist do
			local handleCfrm = ballast.CFrame * CFrame.new(0,0,i-((i/(dist/2))*(handleSize.Z/2)))
			if i > 0 then
				handleCfrm = handleCfrm * CFrame.Angles(0,math.rad(180),0)
			end

			local handle = CreatePart(Track,handleCfrm,handleSize)
			handle.CanCollide = false
			handle.Transparency = 1
			handle.Name = "TrackHandle"
		end
	end

	return Track
end



--operation types
local WayOperations = {
	["area"] = function(tags: any, model: Instance, properties: any, positions: {Vector3},corners: {Vector3},GenerationRules: any, Map: any)

		return SimpleOperations.area(tags,model,properties,positions,corners,GenerationRules)

	end,

	["way"] = function(tags: any, model: Instance, properties: any, positions: {Vector3},corners: {Vector3},GenerationRules: any, Map: any, elevationMode: string)

		return SimpleOperations.way(tags,model,properties,positions,corners,GenerationRules,Map,elevationMode)

	end,

	["area/way"] = function(tags: any, model: Instance, properties: any, positions: {Vector3},corners: {Vector3},GenerationRules: any, Map: any, elevationMode: string)

		if tags["area"] and tags["area"] == "yes" then

			return SimpleOperations.area(tags,model,properties,positions,corners,GenerationRules)

		else

			return SimpleOperations.way(tags,model,properties,positions,corners,GenerationRules,Map,elevationMode)

		end

	end,


	-- It looks pretty weird, used to have a way to cut off rails at borders of chunks but i removed that
	["rail"] = function(tags: any, model: Instance, properties: any, positions: {Vector3},corners: {Vector3},GenerationRules: any, Map: any, elevationMode: string)

		local newPositions = {}

		local firstPos,lastPos,firstPart
		

		for i,pos in positions do
			if not positions[i-1] then
				table.insert(newPositions,pos)
				continue
			end

			local A,B = pos,positions[i-1]
			local intersects = {}

			local function comp(a,b)
				if (a-pos).Magnitude < (b-pos).Magnitude then
					return a else return b
				end
			end

			table.sort(intersects,comp)
			for _,intersect in intersects do
				table.insert(newPositions,intersect)
			end

			table.insert(newPositions,pos)

		end

		positions = newPositions
		
		
		
		if elevationMode == "terrain" or elevationMode == "elevation" then

			local newPositions = {}

			for i,pos in positions do
				local newPos = Elevation.getOffsetPosition(pos, Map)
				if newPos then
					table.insert(newPositions,newPos)
				end
			end

			for i,pos in positions do
				if i == 1 then
					continue
				end

				local a = pos
				local b = positions[i-1]

				local dist = (a-b).Magnitude

			end

			positions = newPositions

			if #positions < 2 then
				return
			end

		end
		
		

		local parts = {}
		local partsPositions = {} --the smoothConnect module needs positions for angles between parts


		for i,pos in positions do
			if not positions[i-1] then
				firstPos = pos
				continue
			elseif i == #positions then
				lastPos = pos
			end


			local dist = (pos-positions[i-1]).Magnitude
			local cfrm = CFrame.new((positions[i-1]+pos)/2) * CFrame.lookAt(pos,positions[i-1]).Rotation

			local Track = createTrainTrack(cfrm,dist,properties,GenerationRules)

			Track.Parent = model
			table.insert(parts,Track)
			table.insert(partsPositions,positions[i-1])

		end

		if #parts > 1 then
			SimpleOperations.smoothRailConnect(parts,GenerationRules)
		end

		return parts

	end,

	["building"] = function(tags: any, model: Instance, properties: any, positions: {Vector3}, corners: {Vector3}, GenerationRules: any, Map: any, elevationMode: string)
		
		local scale = Values.Scale.Value
		local D = 0.28
		local heightUnderground = 15 * scale --studs

		-- ===== Wall height: explicit "height" tag (meters) > building:levels*3 > default =====
		local height
		if tags["height"] and tonumber(tags["height"]) then
			height = tonumber(tags["height"]) / D
		elseif tags["building:levels"] and tonumber(tags["building:levels"]) then
			height = tonumber(tags["building:levels"]) * 3/D
		else
			height = properties.defaultHeight / D
		end

		-- convert meters to studs according to scale
		height *= scale

		-- ===== min_height: lets podiums / arcades / stacked building:part volumes
		-- start above ground instead of every part starting at grade =====
		local minHeight = 0
		if tags["min_height"] and tonumber(tags["min_height"]) then
			minHeight = tonumber(tags["min_height"]) / D
		elseif tags["building:min_height"] and tonumber(tags["building:min_height"]) then
			minHeight = tonumber(tags["building:min_height"]) / D
		elseif tags["building:min_level"] and tonumber(tags["building:min_level"]) then
			minHeight = tonumber(tags["building:min_level"]) * (properties.heightPerFloor or 3) / D
		end
		minHeight *= scale

		-- guard against bad/contradictory OSM data eating the whole building
		if minHeight >= height then
			minHeight = 0
		end

		local wallHeight = height - minHeight

		local totalHeight = wallHeight
		local addedHeight = minHeight + wallHeight/2
		
		-- add more height so building does not clip through the ground
		if elevationMode ~= "flat" then
			totalHeight = wallHeight + heightUnderground
			addedHeight = minHeight + wallHeight/2 - heightUnderground /2
		end
		
		
		local mid = Vector3.new(0,0,0)
		for _,pos in positions do
			mid += pos
		end
		mid /= #positions
		
		
		if elevationMode ~= "flat" then
			mid = Elevation.getOffsetPosition(mid, Map)
		end
		
		if not mid then
			return {}
		end

		-- ===== Colour/material: OSM tags first, EditableModules defaults as fallback.
		-- building:colour/material and roof:colour/material are already present in
		-- every Overpass response this plugin pulls -- they were just unused before. =====
		local wallColor = ColorUtils.parseColor(tags["building:colour"]) or properties.color
		local wallMaterial = ColorUtils.parseMaterial(tags["building:material"]) or properties.material

		local roofColor = ColorUtils.parseColor(tags["roof:colour"]) or properties.roofColor or ColorUtils.darken(wallColor, 0.2)
		local roofMaterial = ColorUtils.parseMaterial(tags["roof:material"]) or properties.roofMaterial or Enum.Material.Slate

		local roofThicknessMeters = properties.roofThickness or 0.35
		local roofThickness = roofThicknessMeters / D * scale
		
		local buildingPositions = {}
		for i = 1,#positions-1 do
			local pos = positions[i]
			
			pos += Vector3.new(0, mid.Y + addedHeight, 0)
			
			table.insert(buildingPositions, pos)
		end


		local triangles = PolygonTriangulation(buildingPositions)

		for _,t in triangles do
			t.Color = wallColor
			t.Material = wallMaterial
			t.Size = Vector3.new(totalHeight,t.Size.Y,t.Size.Z)
			t.Name = "BuildingPart"
			t:SetAttribute("OSM_type","building_part")
			t.Parent = model
		end

		-- ===== Roof =====
		-- topY is independent of the underground padding added above -- that padding
		-- only extends the walls downward, the visible top stays at minHeight+wallHeight.
		local topY = mid.Y + minHeight + wallHeight
		local roofParts = {}
		local roofShape = tags["roof:shape"]

		if (roofShape == "pyramidal" or roofShape == "hipped" or roofShape == "dome") and #positions >= 4 then

			-- Simple hip/pyramid approximation: fan-triangulate from an apex above the
			-- footprint centroid to each footprint edge. Not a true multi-ridge hipped
			-- roof, but a big step up from a flat cap on anything roughly tower/house-shaped.
			-- True gabled/skillion ridge geometry is a reasonable next extension here.
			local roofHeightMeters = tonumber(tags["roof:height"]) or properties.roofHeight or 2.5
			local apexHeight = roofHeightMeters / D * scale

			local centroid = Vector3.new(0,0,0)
			local n = #positions-1
			for i = 1,n do
				centroid += positions[i]
			end
			centroid /= n
			centroid = Vector3.new(centroid.X, topY, centroid.Z)

			local apex = centroid + Vector3.new(0, apexHeight, 0)

			for i = 1,n do
				local p1 = Vector3.new(positions[i].X, topY, positions[i].Z)
				local p2Index = i+1
				if p2Index > n then p2Index = 1 end
				local p2 = Vector3.new(positions[p2Index].X, topY, positions[p2Index].Z)

				local wedges = Triangle(model, p1, p2, apex)
				for _,w in wedges do
					w.Size = Vector3.new(roofThickness, w.Size.Y, w.Size.Z)
					w.Color = roofColor
					w.Material = roofMaterial
					w.Name = "RoofPart"
					w:SetAttribute("OSM_type","building_roof")
					table.insert(roofParts, w)
				end
			end

		else

			-- Flat cap -- correct for roof:shape == "flat" or unset, and a safe fallback
			-- for shapes (gabled, skillion, etc.) we don't model precisely yet.
			local roofPositions = {}
			for i = 1,#positions-1 do
				local pos = positions[i]
				pos = Vector3.new(pos.X, topY, pos.Z)
				table.insert(roofPositions, pos)
			end

			local capTriangles = PolygonTriangulation(roofPositions)

			for _,t in capTriangles do
				t.Color = roofColor
				t.Material = roofMaterial
				t.Size = Vector3.new(roofThickness, t.Size.Y, t.Size.Z)
				t.Position += Vector3.new(0, t.Size.X/2, 0)
				t.Name = "RoofPart"
				t:SetAttribute("OSM_type","building_roof")
				t.Parent = model
				table.insert(roofParts, t)
			end

		end

		model:SetAttribute("OSM_type","building")

		local allParts = {}
		table.move(triangles, 1, #triangles, 1, allParts)
		table.move(roofParts, 1, #roofParts, #allParts+1, allParts)

		return allParts

	end,

}

return WayOperations
