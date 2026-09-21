-- Tests for Modules/ProceduralInfill.lua

local roblox = require("@lune/roblox")
local fs = require("@lune/fs")

Vector3 = roblox.Vector3
CFrame = roblox.CFrame
Enum = roblox.Enum
Color3 = roblox.Color3
Instance = roblox.Instance
task = { wait = function() end }

local function assert_approx_eq(expected, actual, tolerance)
    tolerance = tolerance or 0.001
    if math.abs(expected - actual) > tolerance then
        error(string.format("Assertion failed: expected approx %f, got %f", expected, actual))
    end
end

-- Instead of string manipulation, mock the environment so we can require ProceduralInfill.lua directly
local original_require = require
getfenv().require = function(arg)
    -- ProceduralInfill requires WayOperations. We just need to return an empty table for WayOperations.
    if type(arg) == "table" and arg.name == "MockWayOperations" then
        return {}
    end
    -- Also mock WayOperations in case it matches string
    if type(arg) == "string" and string.find(arg, "WayOperations") then
        return {}
    end
    -- Fallback to original require
    return original_require(arg)
end

-- Mock game:GetService
getfenv().game = {
    GetService = function(self, serviceName)
        if serviceName == "CollectionService" then
            return {
                AddTag = function() end
            }
        end
    end
}

-- Mock script.Parent...
local mockScript = {
    Parent = {
        Parent = {
            Objects = {
                Values = {
                    Scale = { Value = 1 }
                }
            }
        },
        WaitForChild = function(self, childName)
            if childName == "WayOperations" then
                return { name = "MockWayOperations" }
            end
        end
    }
}
getfenv().script = mockScript

local ProceduralInfill = original_require("../Modules/ProceduralInfill")

print("--- Testing ProceduralInfill.polygonBounds ---")

local success, err = pcall(function()
    -- Test 1: Square polygon
    local squareRing = {
        Vector3.new(0, 0, 0),
        Vector3.new(10, 0, 0),
        Vector3.new(10, 0, 10),
        Vector3.new(0, 0, 10)
    }
    local minX, maxX, minZ, maxZ = ProceduralInfill.polygonBounds(squareRing)
    assert_approx_eq(0, minX)
    assert_approx_eq(10, maxX)
    assert_approx_eq(0, minZ)
    assert_approx_eq(10, maxZ)
    print("Test 1 (Square polygon) passed")

    -- Test 2: Triangle with arbitrary points
    local triangleRing = {
        Vector3.new(5, 0, 2),
        Vector3.new(15, 0, 8),
        Vector3.new(10, 0, 20)
    }
    minX, maxX, minZ, maxZ = ProceduralInfill.polygonBounds(triangleRing)
    assert_approx_eq(5, minX)
    assert_approx_eq(15, maxX)
    assert_approx_eq(2, minZ)
    assert_approx_eq(20, maxZ)
    print("Test 2 (Triangle) passed")

    -- Test 3: Polygon with negative coordinates
    local negativeRing = {
        Vector3.new(-10, 0, -5),
        Vector3.new(-2, 0, -20),
        Vector3.new(-15, 0, -15)
    }
    minX, maxX, minZ, maxZ = ProceduralInfill.polygonBounds(negativeRing)
    assert_approx_eq(-15, minX)
    assert_approx_eq(-2, maxX)
    assert_approx_eq(-20, minZ)
    assert_approx_eq(-5, maxZ)
    print("Test 3 (Negative coordinates) passed")

    -- Test 4: Mixed positive and negative coordinates
    local mixedRing = {
        Vector3.new(-10, 0, 10),
        Vector3.new(10, 0, -10),
        Vector3.new(5, 0, 5),
        Vector3.new(-5, 0, -5)
    }
    minX, maxX, minZ, maxZ = ProceduralInfill.polygonBounds(mixedRing)
    assert_approx_eq(-10, minX)
    assert_approx_eq(10, maxX)
    assert_approx_eq(-10, minZ)
    assert_approx_eq(10, maxZ)
    print("Test 4 (Mixed coordinates) passed")

    -- Test 5: Colinear points
    local colinearRing = {
        Vector3.new(0, 0, 0),
        Vector3.new(5, 0, 5),
        Vector3.new(10, 0, 10)
    }
    minX, maxX, minZ, maxZ = ProceduralInfill.polygonBounds(colinearRing)
    assert_approx_eq(0, minX)
    assert_approx_eq(10, maxX)
    assert_approx_eq(0, minZ)
    assert_approx_eq(10, maxZ)
    print("Test 5 (Colinear points) passed")

    print("All tests passed for ProceduralInfill.polygonBounds!")
end)

if not success then
    print("Test failed: ", err)
    os.exit(1)
end
