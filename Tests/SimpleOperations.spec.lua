-- Tests for Modules/SimpleOperations.lua

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

local function assert_approx_vec3(expected, actual, tolerance)
    assert_approx_eq(expected.X, actual.X, tolerance)
    assert_approx_eq(expected.Y, actual.Y, tolerance)
    assert_approx_eq(expected.Z, actual.Z, tolerance)
end

-- We'll mock the Roblox Instance methods required for tests
local function createMockPart(size, cframe)
    local part = {
        Size = size or Vector3.new(10, 1, 10),
        CFrame = cframe or CFrame.new(0, 0, 0),
        _children = {}
    }
    -- Setup metamethod for Position which depends on CFrame
    setmetatable(part, {
        __index = function(t, key)
            if key == "Position" then
                return t.CFrame.Position
            elseif key == "size" then
                return t.Size
            end
            return rawget(t, key)
        end
    })

    function part:GetChildren()
        return self._children
    end

    function part:IsA(className)
        return className == "Part" or className == "BasePart"
    end

    function part:AddChild(child)
        table.insert(self._children, child)
    end

    return part
end

local function createMockMesh(meshType)
    local mesh = {
        Scale = Vector3.new(1, 1, 1),
    }
    function mesh:IsA(className)
        return className == meshType
    end
    return mesh
end

-- Read and patch SimpleOperations.lua to be executable in this environment
local code = fs.readFile("Modules/SimpleOperations.lua")

-- Patch the environment to bypass Roblox services and script.Parent dependencies
code = string.gsub(code, "local PolygonTriangulation = require%(script%.Parent:WaitForChild%(\"PolygonTriangulation\"%)%)", "local PolygonTriangulation = {}")
code = string.gsub(code, "local CreatePart = require%(script%.Parent:WaitForChild%(\"CreatePart\"%)%)", "local CreatePart = function() return {Name=\"Part\"} end")
code = string.gsub(code, "local Bezier = require%(script%.Parent:WaitForChild%(\"BezierModule\"%)%)", "local Bezier = require(\"../Modules/BezierModule\")")
code = string.gsub(code, "local Elevation = require%(script%.Parent:WaitForChild%(\"Elevation\"%)%)", "local Elevation = {}")
code = string.gsub(code, "local Triangle = require%(script%.Parent:WaitForChild%(\"Triangle\"%)%)", "local Triangle = {}")

code = string.gsub(code, "local CS = game:GetService%(\"CollectionService\"%)", "local CS = {}")
code = string.gsub(code, "local terrain = game.Workspace.Terrain", "local terrain = {}")
code = string.gsub(code, "local Objects = script%.Parent%.Parent%.Objects", "local Objects = {Values = {Scale = {Value = 1}}}")
code = string.gsub(code, "local Values = Objects%.Values", "local Values = Objects.Values")

-- Write it out temporarily and load it normally via lune since it allows caching and better stack traces
fs.writeFile("Tests/_SimpleOperations_patched.lua", code)
local SimpleOperations = require("./_SimpleOperations_patched")

print("--- Testing SimpleOperations.smoothConnectFlat ---")

-- Test 1: Connect two parts at a slight angle (to trigger < 179.6 degrees but > 90.2)
-- If it's completely straight (180), it skips via `179.6 < angle`.
-- So let's test a 45 degree angle where the intersects are calculated via `intersectA/intersectB`.
local p1 = createMockPart(Vector3.new(10, 1, 10), CFrame.new(0, 0, 0))
local p2 = createMockPart(Vector3.new(10, 1, 10), CFrame.new(0, 0, -10) * CFrame.Angles(0, math.rad(45), 0))
SimpleOperations.smoothConnectFlat({p1, p2})
-- Length is modified based on intersection math
assert_approx_vec3(Vector3.new(10, 1, 17.071), p1.Size, 0.01)
assert_approx_vec3(Vector3.new(10, 1, 7.071), p2.Size, 0.01)
print("Test 1 (45-degree turn) passed")

-- Test 2: 90 degree turn (less than 90.2)
local p3 = createMockPart(Vector3.new(10, 1, 10), CFrame.new(0, 0, 0))
local p4 = createMockPart(Vector3.new(10, 1, 10), CFrame.new(0, 0, -10) * CFrame.Angles(0, math.rad(90), 0))
SimpleOperations.smoothConnectFlat({p3, p4})
assert_approx_vec3(Vector3.new(10, 1, 15), p3.Size, 0.1)
assert_approx_vec3(Vector3.new(10, 1, 5), p4.Size, 0.1)
print("Test 2 (90-degree connection) passed")

-- Test 3: Block Mesh scaling (at 90 degrees to trigger scaling)
local pm1 = createMockPart(Vector3.new(10, 1, 10), CFrame.new(0, 0, 0))
local pm2 = createMockPart(Vector3.new(10, 1, 10), CFrame.new(0, 0, -10) * CFrame.Angles(0, math.rad(90), 0))
local mesh1 = createMockMesh("BlockMesh")
local mesh2 = createMockMesh("SpecialMesh")
mesh2.Scale = Vector3.new(1, 1, 10) -- initial scale matches initial size
pm1:AddChild(mesh1)
pm2:AddChild(mesh2)
SimpleOperations.smoothConnectFlat({pm1, pm2})
-- BlockMesh scale Z is reset to 1
assert_approx_vec3(Vector3.new(1, 1, 1), mesh1.Scale, 0.01)
-- SpecialMesh scale Z is expanded to match the new size which is 5
assert_approx_vec3(Vector3.new(1, 1, 5), mesh2.Scale, 0.1)
print("Test 3 (Mesh scaling) passed")

-- Cleanup
fs.removeFile("Tests/_SimpleOperations_patched.lua")
print("All tests passed for SimpleOperations.smoothConnectFlat!")
