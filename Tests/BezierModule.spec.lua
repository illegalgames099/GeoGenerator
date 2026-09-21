-- Tests for Modules/BezierModule.lua

local roblox = require("@lune/roblox")
Vector3 = roblox.Vector3
CFrame = roblox.CFrame

local BezierModule = require("../Modules/BezierModule")

local function assert_approx_eq(expected, actual, tolerance)
    tolerance = tolerance or 0.001
    if math.abs(expected - actual) > tolerance then
        error(string.format("Assertion failed: expected approx %f, got %f", expected, actual))
    end
end

print("--- Testing BezierModule.CFramesAngle ---")

-- Test 1: Same direction
local cf1 = CFrame.new(0, 0, 0)
local cf2 = CFrame.new(10, 0, 0) -- Position doesn't matter for LookVector
local angle1 = BezierModule.CFramesAngle(cf1, cf2)
assert_approx_eq(180, angle1)
print("Test 1 (0 degree angle / same direction) passed")

-- Test 2: Opposite direction
local cf3 = CFrame.new(0, 0, 0)
local cf4 = CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(180), 0)
local angle2 = BezierModule.CFramesAngle(cf3, cf4)
assert_approx_eq(0, angle2)
print("Test 2 (180 degree angle / opposite direction) passed")

-- Test 3: 90 degree angle
local cf5 = CFrame.new(0, 0, 0)
local cf6 = CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(90), 0)
local angle3 = BezierModule.CFramesAngle(cf5, cf6)
assert_approx_eq(90, angle3)
print("Test 3 (90 degree angle) passed")

-- Test 4: 45 degree angle
local cf7 = CFrame.new(0, 0, 0)
local cf8 = CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(45), 0)
local angle4 = BezierModule.CFramesAngle(cf7, cf8)
assert_approx_eq(135, angle4)
print("Test 4 (45 degree angle) passed")

print("All tests passed for BezierModule.CFramesAngle!")
