local Coordinates = require("Modules.Coordinates")

-- Mock Vector3 and Vector2 to avoid test failures
_G.Vector3 = _G.Vector3 or {
    new = function(x, y, z)
        local t = {X = x, Y = y, Z = z}
        setmetatable(t, {__tostring = function(self) return string.format("Vector3(%f, %f, %f)", self.X, self.Y, self.Z) end})
        return t
    end
}
_G.Vector2 = _G.Vector2 or {
    new = function(x, y)
        local t = {X = x, Y = y}
        setmetatable(t, {__tostring = function(self) return string.format("Vector2(%f, %f)", self.X, self.Y) end})
        return t
    end
}

local function assert_close(a, b, tolerance, msg)
    if math.abs(a - b) > tolerance then
        error(msg .. ": expected " .. tostring(b) .. " but got " .. tostring(a) .. " (diff: " .. tostring(math.abs(a-b)) .. ")")
    end
end

-- Start testing
print("Testing Coordinates.geoToWorld")

-- Save original state
local origLat, origLon = Coordinates.getOrigin()

-- Set up origin to Null Island
Coordinates.setOrigin(0, 0)
Coordinates.newScaler(1) -- scaleFactor 1, WORLD_SCALE = 3.57
local EARTH_RADIUS = 6378137
local WORLD_SCALE = 3.57

-- Test 1: Origin point (0, 0) should return Vector3(0, 0, 0)
local v1 = Coordinates.geoToWorld(0, 0, 0)
assert_close(v1.X, 0, 1e-5, "Origin X should be 0")
assert_close(v1.Y, 0, 1e-5, "Origin Y should be 0")
assert_close(v1.Z, 0, 1e-5, "Origin Z should be 0")

-- Test 2: Point to the North
-- For latitude 1, longitude 0:
-- lat1 = 0, lon1 = 0, lat2 = 1 deg, lon2 = 0
-- X = 0 (since lon2 - lon1 = 0)
-- Z = EARTH_RADIUS * (lat2 - lat1) = EARTH_RADIUS * math.rad(1)
-- Vector3.Z = -Z * WORLD_SCALE
local v2 = Coordinates.geoToWorld(1, 0, 0)
assert_close(v2.X, 0, 1e-5, "North X should be 0")
assert_close(v2.Y, 0, 1e-5, "North Y should be 0")
assert_close(v2.Z, -EARTH_RADIUS * math.rad(1) * WORLD_SCALE, 1e-5, "North Z should match expected formula")

-- Test 3: Point to the East
-- For latitude 0, longitude 1:
-- lat1 = 0, lon1 = 0, lat2 = 0, lon2 = 1 deg
-- X = EARTH_RADIUS * math.rad(1) * math.cos(0) = EARTH_RADIUS * math.rad(1)
-- Vector3.X = X * WORLD_SCALE
local v3 = Coordinates.geoToWorld(0, 1, 0)
assert_close(v3.X, EARTH_RADIUS * math.rad(1) * WORLD_SCALE, 1e-5, "East X should match expected formula")
assert_close(v3.Y, 0, 1e-5, "East Y should be 0")
assert_close(v3.Z, 0, 1e-5, "East Z should be 0")

-- Test 4: Altitude
local altitude = 100
local v4 = Coordinates.geoToWorld(0, 0, altitude)
assert_close(v4.X, 0, 1e-5, "Altitude X should be 0")
assert_close(v4.Y, altitude * WORLD_SCALE, 1e-5, "Altitude Y should be scaled properly")
assert_close(v4.Z, 0, 1e-5, "Altitude Z should be 0")

-- Test 5: Custom origin (San Francisco)
Coordinates.setOrigin(37.7749, -122.4194)
-- Point is San Francisco
local v5 = Coordinates.geoToWorld(37.7749, -122.4194, 10)
assert_close(v5.X, 0, 1e-5, "Custom origin X should be 0")
assert_close(v5.Y, 10 * WORLD_SCALE, 1e-5, "Custom origin Y should be scaled properly")
assert_close(v5.Z, 0, 1e-5, "Custom origin Z should be 0")

-- Point slightly north-east
local v6 = Coordinates.geoToWorld(37.7849, -122.4094, 0)
local expectedX = EARTH_RADIUS * math.rad(-122.4094 - -122.4194) * math.cos(math.rad(37.7749 + 37.7849)/2) * WORLD_SCALE
local expectedZ = -EARTH_RADIUS * math.rad(37.7849 - 37.7749) * WORLD_SCALE
assert_close(v6.X, expectedX, 1e-5, "Offset point X should match formula")
assert_close(v6.Z, expectedZ, 1e-5, "Offset point Z should match formula")

-- Restore original state
Coordinates.setOrigin(origLat, origLon)

print("All tests passed for Coordinates.geoToWorld!")
return function()
    local Coordinates = require(script.Parent.Parent.Modules.Coordinates)

    describe("Coordinates.worldToGeo", function()
        it("should correctly inverse geoToWorld", function()
            Coordinates.setOrigin(37.7749, -122.4194)
            local wp = Coordinates.geoToWorld(37.7800, -122.4100, 10)
            local resLat, resLon, resAlt = Coordinates.worldToGeo(wp)

            expect(math.abs(resLat - 37.7800) < 0.0001).to.equal(true)
            expect(math.abs(resLon - -122.4100) < 0.0001).to.equal(true)
            expect(math.abs(resAlt - 10) < 0.0001).to.equal(true)
        end)

        it("should correctly inverse geoToWorld when altitude is omitted", function()
            Coordinates.setOrigin(37.7749, -122.4194)
            local wp = Coordinates.geoToWorld(37.7800, -122.4100)
            local resLat, resLon, resAlt = Coordinates.worldToGeo(wp)

            expect(math.abs(resLat - 37.7800) < 0.0001).to.equal(true)
            expect(math.abs(resLon - -122.4100) < 0.0001).to.equal(true)
            expect(math.abs(resAlt - 0) < 0.0001).to.equal(true)
        end)

        it("should correctly handle origin coordinates", function()
            Coordinates.setOrigin(0, 0)
            local wp = Coordinates.geoToWorld(0, 0, 0)
            local resLat, resLon, resAlt = Coordinates.worldToGeo(wp)

            expect(math.abs(resLat - 0) < 0.0001).to.equal(true)
            expect(math.abs(resLon - 0) < 0.0001).to.equal(true)
            expect(math.abs(resAlt - 0) < 0.0001).to.equal(true)
        end)

        it("should correctly invert negative coordinates", function()
            Coordinates.setOrigin(-33.8688, 151.2093)
            local wp = Coordinates.geoToWorld(-33.8700, 151.2100, -5)
            local resLat, resLon, resAlt = Coordinates.worldToGeo(wp)

            expect(math.abs(resLat - -33.8700) < 0.0001).to.equal(true)
            expect(math.abs(resLon - 151.2100) < 0.0001).to.equal(true)
            expect(math.abs(resAlt - -5) < 0.0001).to.equal(true)
        end)
    end)
end
