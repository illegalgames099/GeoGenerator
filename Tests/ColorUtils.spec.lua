-- Tests for Modules/ColorUtils.lua

local roblox = require("@lune/roblox")
Color3 = roblox.Color3
Enum = roblox.Enum

local ColorUtils = require("../Modules/ColorUtils")

local function assert_approx_eq(expected, actual, tolerance)
    tolerance = tolerance or 0.001
    if math.abs(expected - actual) > tolerance then
        error(string.format("Assertion failed: expected approx %f, got %f", expected, actual))
    end
end

print("--- Testing ColorUtils.parseColor fallback/empty handling ---")

-- Test 1: Nil input
local p1 = ColorUtils.parseColor(nil)
assert(p1 == nil, "Expected nil when parsing nil")
print("Test 1 (Nil input) passed")

-- Test 2: Empty string
local p2 = ColorUtils.parseColor("")
assert(p2 == nil, "Expected nil when parsing empty string")
print("Test 2 (Empty string) passed")

-- Test 3: Semicolon only
local p3 = ColorUtils.parseColor(";")
assert(p3 == nil, "Expected nil when parsing semicolon only")
print("Test 3 (Semicolon only) passed")

-- Test 4: Invalid color name
local p4 = ColorUtils.parseColor("unknown_color")
assert(p4 == nil, "Expected nil when parsing invalid color name")
print("Test 4 (Invalid color name) passed")

print("All tests passed for ColorUtils.parseColor fallback/empty handling!")

print("--- Testing ColorUtils.darken ---")

-- Test 1: Standard darkening with specific amount
local c1 = Color3.new(1, 1, 1)
local d1 = ColorUtils.darken(c1, 0.2)
assert_approx_eq(0.8, d1.R)
assert_approx_eq(0.8, d1.G)
assert_approx_eq(0.8, d1.B)
print("Test 1 (Standard darkening) passed")

-- Test 2: Default amount (0.2) when nil is passed or argument omitted
local c2 = Color3.new(1, 0.5, 0.25)
local d2 = ColorUtils.darken(c2, nil)
assert_approx_eq(0.8, d2.R)
assert_approx_eq(0.4, d2.G)
assert_approx_eq(0.2, d2.B)

local d3 = ColorUtils.darken(c2)
assert_approx_eq(0.8, d3.R)
assert_approx_eq(0.4, d3.G)
assert_approx_eq(0.2, d3.B)
print("Test 2 (Default amount) passed")

-- Test 3: Darkening by 0 (no change)
local c3 = Color3.new(0.5, 0.5, 0.5)
local d4 = ColorUtils.darken(c3, 0)
assert_approx_eq(0.5, d4.R)
assert_approx_eq(0.5, d4.G)
assert_approx_eq(0.5, d4.B)
print("Test 3 (Darkening by 0) passed")

-- Test 4: Darkening by 1 (turns black)
local c4 = Color3.new(0.8, 0.2, 0.1)
local d5 = ColorUtils.darken(c4, 1)
assert_approx_eq(0, d5.R)
assert_approx_eq(0, d5.G)
assert_approx_eq(0, d5.B)
print("Test 4 (Darkening by 1) passed")

-- Test 5: Darkening a color that is already black
local c5 = Color3.new(0, 0, 0)
local d6 = ColorUtils.darken(c5, 0.5)
assert_approx_eq(0, d6.R)
assert_approx_eq(0, d6.G)
assert_approx_eq(0, d6.B)
print("Test 5 (Darkening black) passed")

print("All tests passed for ColorUtils.darken!")
