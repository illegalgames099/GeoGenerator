-- Tests for Modules/BezierModule.lua

local roblox = require("@lune/roblox")
local Vector3 = roblox.Vector3

local BezierModule = require("../Modules/BezierModule")

local function assert_vector3_approx_eq(expected, actual, tolerance)
    tolerance = tolerance or 0.001
    if math.abs(expected.X - actual.X) > tolerance or math.abs(expected.Y - actual.Y) > tolerance or math.abs(expected.Z - actual.Z) > tolerance then
        error(string.format("Assertion failed: expected approx Vector3(%f, %f, %f), got Vector3(%f, %f, %f)", expected.X, expected.Y, expected.Z, actual.X, actual.Y, actual.Z))
    end
end

print("--- Testing BezierModule.lerp ---")

local a = Vector3.new(1, 2, 3)
local b = Vector3.new(5, 6, 7)

-- Test 1: t = 0 (returns a)
local res1 = BezierModule.lerp(a, b, 0)
assert_vector3_approx_eq(a, res1)
print("Test 1 (t = 0) passed")

-- Test 2: t = 1 (returns b)
local res2 = BezierModule.lerp(a, b, 1)
assert_vector3_approx_eq(b, res2)
print("Test 2 (t = 1) passed")

-- Test 3: t = 0.5 (returns midpoint)
local res3 = BezierModule.lerp(a, b, 0.5)
assert_vector3_approx_eq(Vector3.new(3, 4, 5), res3)
print("Test 3 (t = 0.5) passed")

-- Test 4: t > 1 (extrapolation)
local res4 = BezierModule.lerp(a, b, 1.5)
assert_vector3_approx_eq(Vector3.new(7, 8, 9), res4)
print("Test 4 (t > 1 extrapolation) passed")

-- Test 5: t < 0 (extrapolation)
local res5 = BezierModule.lerp(a, b, -0.5)
assert_vector3_approx_eq(Vector3.new(-1, 0, 1), res5)
print("Test 5 (t < 0 extrapolation) passed")

-- Test 6: Same points (a == b)
local c = Vector3.new(4, 5, 6)
local res6 = BezierModule.lerp(c, c, 0.3)
assert_vector3_approx_eq(c, res6)
print("Test 6 (a == b) passed")

-- Test 7: Zero vectors
local zero1 = Vector3.new(0, 0, 0)
local zero2 = Vector3.new(0, 0, 0)
local res7 = BezierModule.lerp(zero1, zero2, 0.8)
assert_vector3_approx_eq(zero1, res7)
print("Test 7 (zero vectors) passed")

print("All tests passed for BezierModule.lerp!")
