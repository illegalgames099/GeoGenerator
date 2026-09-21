local isLune = false
local success, roblox = pcall(require, "@lune/roblox")
if success then
    isLune = true
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
                    if val ~= expected then
                        error("Expected " .. tostring(expected) .. ", got " .. tostring(val))
                    end
                end
            }
        }
    end
else
    describe = _G.describe or getfenv().describe
    it = _G.it or getfenv().it
    expect = _G.expect or getfenv().expect
end

local function runTests()
    local GetData

    if isLune then
        -- Mock required dependencies in lune
        local original_require = require
        getfenv().require = function(arg)
            if type(arg) == "table" then
                -- Match `script.Parent.WidgetModule` and similar object references
                if arg.Name == "WidgetModule" then return {} end
                if arg.Name == "Coordinates" then return {} end
                if arg.Name == "Elevation" then return {} end
            end
            if arg == "WidgetModule" or arg == "Coordinates" or arg == "Elevation" then
                return {}
            end
            return original_require(arg)
        end

        getfenv().script = {
            Parent = {
                WidgetModule = { Name = "WidgetModule" },
                Coordinates = { Name = "Coordinates" },
                Elevation = { Name = "Elevation" }
            },
            FindFirstAncestorWhichIsA = function(self, className)
                return nil
            end
        }

        getfenv().game = {
            GetService = function(self, serviceName)
                if serviceName == "HttpService" then
                    return {}
                end
            end
        }

        GetData = require("../Modules/GetData")
    else
        GetData = require(script.Parent.Parent.Modules.GetData)
    end

    describe("GetData.cacheKey", function()
        it("should generate a basic prefix and key", function()
            local key = GetData.cacheKey("elevation", "https://api.open-meteo.com")
            expect(key).to.equal("elevation:2:https://api.open-meteo.com")
        end)

        it("should handle an empty prefix", function()
            local key = GetData.cacheKey("", "some_key")
            expect(key).to.equal(":2:some_key")
        end)

        it("should handle an empty key", function()
            local key = GetData.cacheKey("osm", "")
            expect(key).to.equal("osm:2:")
        end)

        it("should handle special characters in key", function()
            local key = GetData.cacheKey("test", "a/b?c=1&d=2")
            expect(key).to.equal("test:2:a/b?c=1&d=2")
        end)
    end)
end

if isLune then
    runTests()
else
    return runTests
end
