-- Tests for Modules/GetExtraBuildings.lua

local roblox = require("@lune/roblox")
Vector3 = roblox.Vector3
Vector2 = roblox.Vector2
Instance = roblox.Instance
game = roblox.game

-- Mock GetService for HttpService and CollectionService
game = {
    GetService = function(self, service)
        return {
            GetAsync = function() return "" end,
            JSONDecode = function() return {} end,
            AddTag = function() end
        }
    end
}

-- Create a mock function for WayOperations and Coordinates
local MockWayOperations = {}
local MockCoordinates = {}

-- Trick the require system
local old_require = require
local function custom_require(path)
    if type(path) == "table" and path.Name == "Coordinates" then
        return MockCoordinates
    end
    if type(path) == "table" and path.Name == "WayOperations" then
        return MockWayOperations
    end
    return old_require(path)
end

getfenv(0).require = custom_require

-- Mock script.Parent
if not script then
    getfenv(0).script = {
        Parent = {
            WaitForChild = function(self, name)
                return {
                    Name = name
                }
            end
        }
    }
end

local GetExtraBuildings = custom_require("../Modules/GetExtraBuildings")

local function assert_approx_eq(expected, actual, tolerance)
    tolerance = tolerance or 0.001
    if math.abs(expected - actual) > tolerance then
        error(string.format("Assertion failed: expected approx %f, got %f", expected, actual))
    end
end

local function assert_vector3_approx_eq(expected, actual, tolerance)
    assert_approx_eq(expected.X, actual.X, tolerance)
    assert_approx_eq(expected.Y, actual.Y, tolerance)
    assert_approx_eq(expected.Z, actual.Z, tolerance)
end

print("--- Testing GetExtraBuildings._ringCentroid ---")

-- Test 1: Empty positions table
local emptyPositions = {}
local c1 = GetExtraBuildings._ringCentroid(emptyPositions)
assert_vector3_approx_eq(Vector3.new(0, 0, 0), c1)
print("Test 1 (Empty positions table) passed")

-- Test 2: Basic polygon test (square)
-- The last point duplicates the first point
local squarePositions = {
    Vector3.new(0, 0, 0),
    Vector3.new(10, 0, 0),
    Vector3.new(10, 0, 10),
    Vector3.new(0, 0, 10),
    Vector3.new(0, 0, 0)
}
local c2 = GetExtraBuildings._ringCentroid(squarePositions)
assert_vector3_approx_eq(Vector3.new(5, 0, 5), c2)
print("Test 2 (Basic polygon test - square) passed")

-- Test 3: Triangle test
local trianglePositions = {
    Vector3.new(0, 0, 0),
    Vector3.new(6, 0, 0),
    Vector3.new(3, 0, 6),
    Vector3.new(0, 0, 0)
}
local c3 = GetExtraBuildings._ringCentroid(trianglePositions)
assert_vector3_approx_eq(Vector3.new(3, 0, 2), c3)
print("Test 3 (Basic polygon test - triangle) passed")

print("All tests passed for GetExtraBuildings!")
