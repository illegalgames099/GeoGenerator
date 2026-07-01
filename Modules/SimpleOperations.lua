-- This one is a mess, but hey, it (mostly) works!!!1!

local module = {}

-- Modules
local PolygonTriangulation = require(script.Parent:WaitForChild("PolygonTriangulation"))
local CreatePart = require(script.Parent:WaitForChild("CreatePart"))
local Bezier = require(script.Parent:WaitForChild("BezierModule"))
local Elevation = require(script.Parent:WaitForChild("Elevation"))
local Triangle = require(script.Parent:WaitForChild("Triangle"))

-- Other
local ignoreBoundary
local CS = game:GetService("CollectionService")
local terrain = game.Workspace.Terrain
local Objects = script.Parent.Parent.Objects
local Values = Objects.Values

-- Borders of chunk
local minX
local maxX
local minZ
local maxZ

local function isEnabled(value: any, default: boolean?)
	if value == nil then
		return default == true
	end

	return value == true
end

local function addTopTexture(part: BasePart, textureId: string?, studsPerTile: number?, transparency: number?)
	if not textureId or textureId == "" then
		return
	end

	if tonumber(textureId) then
		textureId = "rbxassetid://"..textureId
	end

	local texture = Instance.new("Texture")
	texture.Name = "SatelliteTexture"
	texture.Texture = textureId
	texture.Face = Enum.NormalId.Top
	texture.StudsPerTileU = studsPerTile or 64
	texture.StudsPerTileV = studsPerTile or 64
	texture.Transparency = transparency or 0
	texture.Parent = part
end

local function shouldUseRoadDetails(tags: any, properties: any, GenerationRules: any)
	if not isEnabled(GenerationRules["Realistic Roads"], true) then
		return false
	end

	if not tags or tags["area"] == "yes" then
		return false
	end

	local highway = tags["highway"]
	if highway == "footway" or highway == "path" or highway == "cycleway" or highway == "pedestrian" or highway == "steps" or highway == "track" then
		return false
	end

	return properties and (properties.material == Enum.Material.Asphalt or properties.material == "Asphalt")
end

local function createDashedLaneMarkings(model: Instance, cfrm: CFrame, dist: number, roadWidth: number, roadHeight: number, laneCount: number, GenerationRules: any)
	if not isEnabled(GenerationRules["Road Lane Markings"], true) or dist < 6 then
		return {}
	end

	local markings = {}
	local dashLength = GenerationRules["Lane Marking Length"] or 3
	local gapLength = GenerationRules["Lane Marking Gap"] or 6
	local stripeWidth = math.max(0.05, roadWidth * 0.025)
	local yOffset = roadHeight / 2 + 0.015
	local laneSpacing = roadWidth / laneCount

	for lane = 1, laneCount - 1 do
		local xOffset = -roadWidth / 2 + laneSpacing * lane
		local z = -dist / 2 + dashLength / 2

		while z < dist / 2 do
			local currentLength = math.min(dashLength, dist / 2 - z + dashLength / 2)
			if currentLength > 0.5 then
				local marking = CreatePart(
					model,
					cfrm * CFrame.new(xOffset, yOffset, z),
					Vector3.new(stripeWidth, 0.025, currentLength),
					Color3.fromRGB(245, 245, 220),
					Enum.Material.SmoothPlastic
				)
				marking.Name = "Lane Marking"
				table.insert(markings, marking)
			end

			z += dashLength + gapLength
		end
	end

	return markings
end

-- For all mentions of the value of 'D' variable below:
-- Its a divider value, properties are in meters, 1 stud is 0.28cm so we do property/D to determine it in studs 

local function findMesh(p: Instance)
	for _,c in p:GetChildren() do
		if c:IsA("BlockMesh") or c:IsA("SpecialMesh") or c:IsA("MeshPart") then
			return c
		end
	end
end

function module.smoothConnectFlat(parts: {Instance},GenerationRules: any?)
	
	local RO_SCALE
	if GenerationRules and GenerationRules["Ro-Scale"] then
		RO_SCALE = true
	end

	for i,part in parts do

		if not parts[i-1] then 
			continue
		end

		local prevPart = parts[i-1]

		local angle = Bezier.CFramesAngle(part.CFrame,prevPart.CFrame)

		if angle < 90.2 or 179.8 < angle then

			if 179.6 < angle then
				continue
			else

				-- We need to scale the part to the intersect and not further (i think, this is me 2 weeks later)

				local intersect = Bezier.CFrameCFrameIntersect3D(part.CFrame,prevPart.CFrame)

				if not intersect then continue end

				for j,p in {part,prevPart} do

					local dist = (p.Position-intersect).Magnitude
					local oldDist = p.Size.Z/2
					local diff = dist-oldDist

					local m = -1 if j == 2 then m = 1 end

					local offset = diff/2*m

					-- If the part has a mesh, we need to properly scale it
					local mesh = findMesh(p)

					if mesh then
						local scaleRatio = mesh.Scale.Z/p.Size.Z
						if mesh:IsA("BlockMesh") then
							mesh.Scale = Vector3.new(mesh.Scale.X,mesh.Scale.Y,1)
						else
							mesh.Scale = Vector3.new(mesh.Scale.X,mesh.Scale.Y,dist+oldDist)
						end

						p.Size = Vector3.new(p.Size.X,p.Size.Y,dist+oldDist)

					else
						p.Size = Vector3.new(p.Size.X,p.Size.Y,dist+oldDist)
					end

					p.CFrame = p.CFrame * CFrame.new(0,0,offset)

				end

			end

			continue

		end


		local cfrm1a = part.CFrame * CFrame.new(part.size.X/2,0,0)
		local cfrm1b = part.CFrame * CFrame.new(-part.size.X/2,0,0)

		local cfrm2a = prevPart.CFrame * CFrame.new(prevPart.size.X/2,0,0)
		local cfrm2b = prevPart.CFrame * CFrame.new(-prevPart.size.X/2,0,0)

		local intersectA = Bezier.CFrameCFrameIntersect3D(cfrm1a,cfrm2a)
		local intersectB = Bezier.CFrameCFrameIntersect3D(cfrm1b,cfrm2b)

		local sum = (cfrm1a.Position+cfrm1b.Position)/2


		local furtherIntersect = intersectA
		local closestIntersect = intersectB

		if (intersectB-sum).Magnitude > (intersectA-sum).Magnitude then
			furtherIntersect = intersectB
			closestIntersect = intersectA
		end

		-- If its nan or inf then i give up
		if furtherIntersect.X ~= furtherIntersect.X or furtherIntersect.X > 99999999 or furtherIntersect.X < -99999999 then
			continue
		end


		for j,T in {{part,cfrm1a,cfrm1b},{prevPart,cfrm2a,cfrm2b}} do
			local p = T[1]
			local cfrmA = T[2]
			local cfrmB = T[3]

			local closerPos = cfrmA.Position
			if (cfrmA.Position-furtherIntersect).Magnitude > (cfrmB.Position-furtherIntersect).Magnitude then
				closerPos = cfrmB.Position
			end

			local dist = (closerPos-furtherIntersect).Magnitude
			local oldDist = p.Size.Z/2
			local diff = dist-oldDist

			local m = -1 if j == 2 then m = 1 end

			local offset = diff/2*m

			-- Again, we need to scale the mesh properly (if found)
			local mesh = findMesh(p)

			if mesh then

				if mesh:IsA("BlockMesh") then
					mesh.Scale = Vector3.new(mesh.Scale.X,mesh.Scale.Y,1)
				else
					mesh.Scale = Vector3.new(mesh.Scale.X,mesh.Scale.Y,dist+oldDist)
				end

				p.Size = Vector3.new(p.Size.X,p.Size.Y,dist+oldDist)

			else
				p.Size = Vector3.new(p.Size.X,p.Size.Y,dist+oldDist)
			end

			p.CFrame = p.CFrame * CFrame.new(0,0,offset)

		end

	end
	
	
	
end


function module.smoothRailConnect(tracks: {Instance},GenerationRules: any?)

	local rails1 = {}
	local rails2 = {}
	local ballasts = {}
	local ties = {}

	for _,track in tracks do
		for  _,child in track:GetChildren() do
			if child.Name == "Rail" then
				if child:GetAttribute("num") == 1 then
					table.insert(rails1,child)
				else
					table.insert(rails2,child)
				end
			elseif child.Name == "Ballast" then
				table.insert(ballasts,child)
			elseif child.Name == "Ties" then
				table.insert(ties,child)
			end
		end
	end

	local offsets = {}

	for i,tie in ties do
		local ballast = tie.Parent:FindFirstChild("Ballast") if not ballast then continue end
		offsets[tie] = tie.Position - ballast.Position
	end

	for _,T in {rails1,rails2,ballasts} do
		module.smoothConnectFlat(T,GenerationRules)
	end

	for i,tie in ties do
		local offset = offsets[tie]
		local ballast = tie.Parent:FindFirstChild("Ballast") if not ballast then continue end
		tie.Position = ballast.Position + offset
	end

end


function module.area(tags: any, model: Instance, properties: any, positions: {Vector3}, corners: {Vector3}, GenerationRules: any)

	local D = 0.28 / Values.Scale.Value

	local triangles = PolygonTriangulation(positions)

	if #triangles > 100 then
		task.wait()
	end

	local height = properties.height or .1
	height = height/D
	
	if tags["railway"] and tags["railway"] == "platform" then
		height *= GenerationRules["Train platform height multiplier"]
	end

	for _,t in triangles do
		t.Color = properties.color
		t.Material = properties.material
		t.Size = Vector3.new(height,t.Size.Y,t.Size.Z)
		t.Position += Vector3.new(0,t.Size.X/2,0)
		addTopTexture(t, GenerationRules["Satellite Texture Id"], GenerationRules["Satellite Texture Tile Size"], GenerationRules["Satellite Texture Transparency"])
		t.Parent = model
	end

	model.WorldPivot = CFrame.new(model.WorldPivot.X,0,model.WorldPivot.Z)

	return triangles

end


function module.way(tags: any,model: Instance, properties: any, positions: {Vector3}, corners: {any}, GenerationRules: any, Map: any, elevationMode: string)
	
	local scale = Values.Scale.Value
	local D = 0.28 / scale
	local parts = {}

	if #positions < 2 then return end

	local M = 1 --multiplier

	local taggedLaneCount = tonumber(tags["lanes"])
	if taggedLaneCount then
		if taggedLaneCount == 1 then
			M = 1.2 -- One lane roads look very thin, so add a little extra width
		else
			M *= taggedLaneCount / 1.8 -- most untagged roads already represent roughly two lanes
		end
	end
	

	if elevationMode == "terrain" or elevationMode == "elevation" then
		
		local newPositions = {}
		
		
		for i,pos in positions do
			
			if i == 1 then
				table.insert(newPositions,pos)
				continue
			end

			local a = pos
			local b = positions[i-1]

			local dist = (a-b).Magnitude

			local distMeters = dist * D
			if distMeters > 10 then
				local multiple = (distMeters - (distMeters % 10)) / 10

				for j = 1, multiple do
					local alpha = j / (multiple + 1)
					local newPosition = b:Lerp(a, alpha)
					table.insert(newPositions, newPosition)
				end

			end
			
			table.insert(newPositions,pos)

		end
		
		positions = newPositions
		newPositions = {}
		
		for i,pos in positions do
			local newPos = Elevation.getOffsetPosition(pos, Map)
			if newPos then
				table.insert(newPositions,newPos)
			end
		end
		
		positions = newPositions
		
		if #positions < 2 then
			return
		end
		
	end
	

	local sidewalkLeftParts = {}
	local sidewalkRightParts = {}
	local useRoadDetails = shouldUseRoadDetails(tags, properties, GenerationRules)
	local sidewalkWidth = (GenerationRules["Sidewalk Width"] or properties.sidewalkWidth or 1.8) / D
	local curbHeight = (GenerationRules["Curb Height"] or properties.curbHeight or 0.18) / D

	for i,pos1 in positions do
		local pos2 = positions[i-1]
		if not pos2 then
			continue
		end

		local dist = (pos1-pos2).Magnitude
		local roadWidth = properties.width/D*M
		local roadHeight = properties.height/D
		local size = Vector3.new(roadWidth,roadHeight,dist)
		local cfrm = CFrame.new((pos1+pos2)/2) * CFrame.lookAt(pos1,pos2).Rotation

		cfrm += Vector3.new(0,roadHeight/2,0)

		if useRoadDetails and (tags["sidewalk"] ~= "no" and tags["sidewalk:both"] ~= "no") then
			local sidewalkHeight = roadHeight + curbHeight
			local sidewalkSize = Vector3.new(sidewalkWidth, sidewalkHeight, dist)
			local sidewalkColor = properties.sidewalkColor or Color3.fromRGB(126, 126, 126)
			local sidewalkMaterial = properties.sidewalkMaterial or Enum.Material.Concrete
			local sideOffset = roadWidth / 2 + sidewalkWidth / 2

			if tags["sidewalk"] ~= "right" and tags["sidewalk:left"] ~= "no" then
				local left = CreatePart(model,cfrm * CFrame.new(-sideOffset, curbHeight / 2, 0),sidewalkSize,sidewalkColor,sidewalkMaterial)
				left.Name = "Sidewalk"
				table.insert(sidewalkLeftParts,left)
			end

			if tags["sidewalk"] ~= "left" and tags["sidewalk:right"] ~= "no" then
				local right = CreatePart(model,cfrm * CFrame.new(sideOffset, curbHeight / 2, 0),sidewalkSize,sidewalkColor,sidewalkMaterial)
				right.Name = "Sidewalk"
				table.insert(sidewalkRightParts,right)
			end
		end

		local part = CreatePart(model,cfrm,size,properties.color,properties.material)
		part.Name = "Road Surface"
		addTopTexture(part, GenerationRules["Satellite Texture Id"], GenerationRules["Satellite Texture Tile Size"], GenerationRules["Satellite Texture Transparency"])
		table.insert(parts,part)

		if useRoadDetails then
			local laneCount = math.max(1, taggedLaneCount or 2)
			createDashedLaneMarkings(model, cfrm, dist, roadWidth, roadHeight, laneCount, GenerationRules)
		end

	end

	-- Makes it so the way parts are nicely connected (like with archimedes plugin) and not clipping
	if elevationMode == "flat" then
		if #parts > 1 then
			module.smoothConnectFlat(parts)
		end
		if #sidewalkLeftParts > 1 then
			module.smoothConnectFlat(sidewalkLeftParts)
		end
		if #sidewalkRightParts > 1 then
			module.smoothConnectFlat(sidewalkRightParts)
		end
	end

	return parts

end

return module
