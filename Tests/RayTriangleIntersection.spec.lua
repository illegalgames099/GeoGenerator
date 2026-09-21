-- Tests for Modules/RayTriangleIntersection.lua

local isLune = false
local success, roblox = pcall(require, "@lune/roblox")
if success then
    isLune = true
    Vector3 = roblox.Vector3
end

local ray_intersects_triangle = require("../Modules/RayTriangleIntersection")

local function assert_vec3_approx(v1, v2, tol)
    tol = tol or 1e-4
    if math.abs(v1.X - v2.X) > tol or math.abs(v1.Y - v2.Y) > tol or math.abs(v1.Z - v2.Z) > tol then
        error(string.format("Vector mismatch: expected %s, got %s", tostring(v1), tostring(v2)))
    end
end

print("--- Testing ray_intersects_triangle ---")

local a = Vector3.new(0, 0, 0)
local b = Vector3.new(10, 0, 0)
local c = Vector3.new(0, 10, 0)

local pass = true

local function runTest(name, fn)
    local status, err = pcall(fn)
    if status then
        print("  ✅ " .. name)
    else
        print("  ❌ " .. name .. " : " .. tostring(err))
        pass = false
    end
end

runTest("Ray intersects triangle in the middle", function()
    local origin = Vector3.new(2, 2, 5)
    local dir = Vector3.new(0, 0, -1)
    local intersection = ray_intersects_triangle(origin, dir, a, b, c)
    assert(intersection ~= nil, "Expected intersection")
    assert_vec3_approx(Vector3.new(2, 2, 0), intersection)
end)

runTest("Ray misses triangle (outside bounds)", function()
    local origin = Vector3.new(12, 12, 5)
    local dir = Vector3.new(0, 0, -1)
    local intersection = ray_intersects_triangle(origin, dir, a, b, c)
    assert(intersection == nil, "Expected no intersection (outside)")
end)

runTest("Ray points away from triangle", function()
    local origin = Vector3.new(2, 2, 5)
    local dir = Vector3.new(0, 0, 1)
    local intersection = ray_intersects_triangle(origin, dir, a, b, c)
    assert(intersection == nil, "Expected no intersection (pointing away)")
end)

runTest("Ray is parallel to the triangle", function()
    local origin = Vector3.new(2, 2, 5)
    local dir = Vector3.new(1, 0, 0)
    local intersection = ray_intersects_triangle(origin, dir, a, b, c)
    assert(intersection == nil, "Expected no intersection (parallel)")
end)

runTest("Ray intersects exactly on a vertex", function()
    local origin = Vector3.new(0, 0, 5)
    local dir = Vector3.new(0, 0, -1)
    local intersection = ray_intersects_triangle(origin, dir, a, b, c)
    assert(intersection ~= nil, "Expected intersection on vertex")
    assert_vec3_approx(Vector3.new(0, 0, 0), intersection)
end)

runTest("Ray intersects exactly on an edge", function()
    local origin = Vector3.new(5, 0, 5)
    local dir = Vector3.new(0, 0, -1)
    local intersection = ray_intersects_triangle(origin, dir, a, b, c)
    assert(intersection ~= nil, "Expected intersection on edge")
    assert_vec3_approx(Vector3.new(5, 0, 0), intersection)
end)

if not pass then
    error("Some tests failed")
end
