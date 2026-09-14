-- tests/test_ColorUtils.lua

-- Mock Roblox Globals
Color3 = {
    fromRGB = function(r, g, b) return {r = r, g = g, b = b, type="Color3"} end,
    new = function(r, g, b) return {R = r, G = g, B = b, type="Color3"} end,
}

Enum = {
    Material = setmetatable({}, {
        __index = function(t, k) return k end
    })
}

local ColorUtils = dofile("Modules/ColorUtils.lua")

local failures = 0
local function assertEqual(expected, actual, message)
    if expected ~= actual then
        print("FAIL: " .. message .. " (Expected: " .. tostring(expected) .. ", Got: " .. tostring(actual) .. ")")
        failures = failures + 1
    end
end

print("Testing ColorUtils.parseColor invalid inputs...")

-- Invalid cases
assertEqual(nil, ColorUtils.parseColor(nil), "nil input")
assertEqual(nil, ColorUtils.parseColor(""), "empty string")
assertEqual(nil, ColorUtils.parseColor(";"), "semicolon only")
assertEqual(nil, ColorUtils.parseColor("not_a_color"), "invalid color name")
assertEqual(nil, ColorUtils.parseColor("#1234"), "invalid hex length 4")
assertEqual(nil, ColorUtils.parseColor("#12345"), "invalid hex length 5")
assertEqual(nil, ColorUtils.parseColor("#1234567"), "invalid hex length 7")
assertEqual(nil, ColorUtils.parseColor("#zzzzzz"), "invalid hex characters")
assertEqual(nil, ColorUtils.parseColor("#z23"), "invalid hex characters in 3-char hex")
assertEqual(nil, ColorUtils.parseColor("!!@@##"), "gibberish")
assertEqual(nil, ColorUtils.parseColor("#"), "just #")
assertEqual(nil, ColorUtils.parseColor("   "), "spaces only")

if failures > 0 then
    print("Tests failed: " .. failures)
    os.exit(1)
else
    print("All tests passed!")
    os.exit(0)
end
