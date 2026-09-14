-- Tests for Modules.ColorUtils
-- We mock _G.Color3 and _G.Enum for testing outside of Roblox environment.
-- The module is loaded and stripped in-memory during testing.

_G.Enum = {
    Material = {
        Brick = "Brick",
        Concrete = "Concrete",
        Glass = "Glass",
        Wood = "Wood",
        WoodPlanks = "WoodPlanks",
        Rock = "Rock",
        Limestone = "Limestone",
        Sandstone = "Sandstone",
        Granite = "Granite",
        Marble = "Marble",
        Basalt = "Basalt",
        SmoothPlastic = "SmoothPlastic",
        Plastic = "Plastic",
        Metal = "Metal",
        CorrodedMetal = "CorrodedMetal",
        Slate = "Slate",
        Asphalt = "Asphalt",
        Pebble = "Pebble",
        Grass = "Grass",
        Fabric = "Fabric"
    }
}

_G.Color3 = {
    fromRGB = function(r, g, b)
        return { R = r/255, G = g/255, B = b/255, r = r, g = g, b = b, type = "Color3" }
    end,
    new = function(r, g, b)
        return { R = r, G = g, B = b, r = r*255, g = g*255, b = b*255, type = "Color3" }
    end
}

local function assertEqual(a, b, msg)
    if a ~= b then
        error(string.format("Assertion failed: %s ~= %s. %s", tostring(a), tostring(b), msg or ""))
    end
end

local function assertNil(a, msg)
    if a ~= nil then
        error(string.format("Assertion failed: expected nil, got %s. %s", tostring(a), msg or ""))
    end
end

-- A helper to load the real module by stripping type annotations in-memory,
-- avoiding detached copies of the source file.
local function loadLuauModule(path)
    local f = io.open(path, "r")
    local content = f:read("*all")
    f:close()

    -- Strip Luau type annotations
    content = content:gsub(":%s*string%?", "")
    content = content:gsub(":%s*Color3%?", "")
    content = content:gsub(":%s*Enum.Material%?", "")
    content = content:gsub("c:%s*Color3", "c")
    content = content:gsub("amount:%s*number", "amount")
    content = content:gsub(":%s*Color3", "")

    local func, err = loadstring(content, path)
    if not func then
        error("Failed to load module: " .. tostring(err))
    end
    return func()
end

local ColorUtils = loadLuauModule("Modules/ColorUtils.lua")

print("Testing ColorUtils.parseColor")

-- 1. nil and empty cases
assertNil(ColorUtils.parseColor(nil), "nil input")
assertNil(ColorUtils.parseColor(""), "empty string input")

-- 2. hex6 cases
local c1 = ColorUtils.parseColor("#ff0000")
assertEqual(c1.r, 255, "hex6 red")
assertEqual(c1.g, 0, "hex6 green")
assertEqual(c1.b, 0, "hex6 blue")

local c2 = ColorUtils.parseColor("00FF00") -- No hash, uppercase
assertEqual(c2.r, 0, "hex6 upper red")
assertEqual(c2.g, 255, "hex6 upper green")
assertEqual(c2.b, 0, "hex6 upper blue")

-- 3. hex3 cases
local c3 = ColorUtils.parseColor("#0f0")
assertEqual(c3.r, 0, "hex3 red")
assertEqual(c3.g, 255, "hex3 green")
assertEqual(c3.b, 0, "hex3 blue")

local c4 = ColorUtils.parseColor("F0F") -- No hash, uppercase
assertEqual(c4.r, 255, "hex3 upper red")
assertEqual(c4.g, 0, "hex3 upper green")
assertEqual(c4.b, 255, "hex3 upper blue")

-- 4. named colors
local c5 = ColorUtils.parseColor("red")
assertEqual(c5.r, 180, "named red")
assertEqual(c5.g, 40, "named green")
assertEqual(c5.b, 40, "named blue")

local c6 = ColorUtils.parseColor("  gReEn  ") -- whitespace and mixed case
assertEqual(c6.r, 80, "named green red")
assertEqual(c6.g, 120, "named green green")
assertEqual(c6.b, 80, "named green blue")

-- 5. multiple colors (semicolon separated)
local c7 = ColorUtils.parseColor("#ff0000;#00ff00")
assertEqual(c7.r, 255, "multiple red")
assertEqual(c7.g, 0, "multiple green")
assertEqual(c7.b, 0, "multiple blue")

local c8 = ColorUtils.parseColor(" blue ; red ")
assertEqual(c8.r, 70, "multiple named red")
assertEqual(c8.g, 100, "multiple named green")
assertEqual(c8.b, 140, "multiple named blue")

-- 6. invalid input
assertNil(ColorUtils.parseColor("not_a_real_color"), "invalid string")
assertNil(ColorUtils.parseColor("#zzzzzz"), "invalid hex")
assertNil(ColorUtils.parseColor("12345"), "invalid string format")

print("All tests passed.")
