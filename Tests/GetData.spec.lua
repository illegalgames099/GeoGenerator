local isLune = false
local success, roblox = pcall(require, "@lune/roblox")
if success then
    isLune = true
    Vector3 = roblox.Vector3
    Task = { wait = function() end }
end

local describe, it, expect

if isLune then
    describe = function(name, fn)
        print("--- " .. name .. " ---")
        fn()
    end

    it = function(name, fn)
        local status, err = pcall(fn)
        if status then
            print("  ✅ " .. name)
        else
            print("  ❌ " .. name .. " : " .. tostring(err))
            error("Test failed")
        end
    end

    expect = function(val)
        return {
            to = {
                equal = function(expected)
                    if val ~= expected then error("Expected " .. tostring(expected) .. ", got " .. tostring(val)) end
                end
            }
        }
    end
end

local testEZSuite = function()
    local GetData
    if isLune then
        local original_require = require
        getfenv().require = function(arg)
            if type(arg) == "table" then return arg end
            return original_require(arg)
        end
        getfenv().script = {
            Parent = {
                WidgetModule = {},
                Coordinates = {},
                Elevation = {}
            },
            FindFirstAncestorWhichIsA = function() return nil end
        }
        getfenv().game = { GetService = function() return {} end }
        getfenv().workspace = {}
        getfenv().task = { wait = function() end }
        GetData = original_require("../Modules/GetData")
    else
        describe = _G.describe or getfenv().describe
        it = _G.it or getfenv().it
        expect = _G.expect or getfenv().expect
        GetData = require(script.Parent.Parent.Modules.GetData)
    end

    describe("GetData.rN", function()
        it("should round to specified decimal places", function()
            expect(GetData.rN(1.2345, 2)).to.equal(1.23)
            expect(GetData.rN(1.2365, 2)).to.equal(1.24)
        end)

        it("should default to 0 decimal places if omitted", function()
            expect(GetData.rN(1.5)).to.equal(2)
            expect(GetData.rN(1.4)).to.equal(1)
        end)

        it("should round properly for exact matches", function()
            expect(GetData.rN(1.5000, 3)).to.equal(1.5)
        end)

        it("should handle negative numbers correctly", function()
            expect(GetData.rN(-1.2345, 2)).to.equal(-1.23)
            expect(GetData.rN(-1.5)).to.equal(-2)
        end)
    end)
end

if isLune then
    testEZSuite()
else
    return testEZSuite
end
