local isLune = false
local success, roblox = pcall(require, "@lune/roblox")
local fs, luau

if success then
    isLune = true
    fs = require("@lune/fs")
    luau = require("@lune/luau")
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
            error("Test failed: " .. tostring(err))
        end
    end

    expect = function(val)
        return {
            to = {
                be = {
                    ok = function() assert(val ~= nil, "Expected ok (not nil)") end,
                    near = function(expected, tol)
                        tol = tol or 0.001
                        assert(math.abs(expected - val) <= tol, "Expected " .. expected .. ", got " .. val)
                    end,
                    equal = function(expected)
                        assert(val == expected, "Expected " .. tostring(expected) .. ", got " .. tostring(val))
                    end,
                    a = function(t)
                        assert(type(val) == t, "Expected type " .. t .. ", got " .. type(val))
                    end
                }
            },
            never = {
                to = {
                    be = {
                        ok = function() assert(val == nil, "Expected not ok (nil), got value") end
                    }
                }
            }
        }
    end
end

local function getMockedGetData()
    if isLune then
        local source = fs.readFile("Modules/GetData.lua")
        local chunk = luau.load(luau.compile(source))
        local mockPluginSettings = {}
        local mockPlugin = {
            GetSetting = function(self, key)
                return mockPluginSettings[key]
            end,
            SetSetting = function(self, key, value)
                mockPluginSettings[key] = value
            end
        }

        local mockHttpService = {
            JSONDecode = function(self, str)
                if str == '{"test":{"response":"cached"}}' then
                    return {test = {response = "cached"}}
                end
                if str == '{"key":{"response":"data"}}' then
                    return {key = {response = "data"}}
                end
                return {}
            end,
            JSONEncode = function(self, tab)
                if tab.key and tab.key.response == "data" then
                    return '{"key":{"response":"data"}}'
                end
                return "{}"
            end
        }

        local mockEnv = setmetatable({
            script = {
                Parent = {},
                FindFirstAncestorWhichIsA = function(self, className)
                    if className == "Plugin" then
                        return mockPlugin
                    end
                    return nil
                end,
                GetAttribute = function(self, key)
                    if key == "_TESTING" then return true end
                    return nil
                end
            },
            game = {
                GetService = function(self, name)
                    if name == "HttpService" then
                        return mockHttpService
                    end
                    return {}
                end
            },
            require = function() return {} end,
            warn = function() end,
            os = os,
            math = math,
            table = table,
            tostring = tostring,
            tonumber = tonumber,
            type = type,
            pcall = pcall,
            string = string
        }, { __index = getfenv() })

        setfenv(chunk, mockEnv)
        return chunk(), mockPluginSettings
    else
        -- If running in TestEZ, assume the environment is set up appropriately for Roblox
        local GetData = require(game:GetService("ServerScriptService"):FindFirstChild("Modules", true).GetData)
        return GetData, {}
    end
end

local function testEZSuite()
    describe("GetData module", function()
        it("splitBBox correctly handles standard box", function()
            local funcs = getMockedGetData()
            if not funcs.splitBBox then return end -- Skip if testing flag isn't set in TestEZ
            local splitBBox = funcs.splitBBox
            local chunks = splitBBox(0, 0, 0.02, 0.02, 0.01)

            expect(#chunks).to.be.equal(4)
            expect(chunks[1].coords).to.be.equal("0,0,0.01,0.01")
            expect(chunks[2].coords).to.be.equal("0,0.01,0.01,0.02")
            expect(chunks[3].coords).to.be.equal("0.01,0,0.02,0.01")
            expect(chunks[4].coords).to.be.equal("0.01,0.01,0.02,0.02")
        end)

        it("mergeElements prevents duplicates", function()
            local funcs = getMockedGetData()
            if not funcs.mergeElements then return end
            local mergeElements = funcs.mergeElements

            local target = {}
            local seen = {}
            local chunk1 = {
                { type = "node", id = 123 },
                { type = "way", id = 456 }
            }
            local chunk2 = {
                { type = "way", id = 456 },
                { type = "node", id = 789 }
            }

            mergeElements(target, seen, chunk1)
            expect(#target).to.be.equal(2)
            expect(seen["node:123"]).to.be.equal(true)
            expect(seen["way:456"]).to.be.equal(true)

            mergeElements(target, seen, chunk2)
            expect(#target).to.be.equal(3)
            expect(target[3].id).to.be.equal(789)
        end)

        it("cacheKey creates correct format", function()
            local funcs = getMockedGetData()
            if not funcs.cacheKey then return end
            local cacheKey = funcs.cacheKey

            local key = cacheKey("osm", "1,2,3,4")
            expect(key).to.be.equal("osm:2:1,2,3,4")
        end)

        it("getCachedResponse handles memory and persistence", function()
            local funcs, settings = getMockedGetData()
            if not funcs.getCachedResponse then return end

            settings["GeoGeneratorHttpCacheV1"] = '{"test":{"response":"cached"}}'

            local response, source = funcs.getCachedResponse("test")
            expect(response).to.be.equal("cached")
            expect(source).to.be.equal("settings")

            local response2, source2 = funcs.getCachedResponse("test")
            expect(response2).to.be.equal("cached")
            expect(source2).to.be.equal("memory")

            local response3 = funcs.getCachedResponse("missing")
            expect(response3).never.to.be.ok()
        end)

        it("setCachedResponse writes to memory and persistence", function()
            local funcs, settings = getMockedGetData()
            if not funcs.setCachedResponse then return end

            funcs.setCachedResponse("key", "data")

            local response, source = funcs.getCachedResponse("key")
            expect(response).to.be.equal("data")
            expect(source).to.be.equal("memory")

            expect(settings["GeoGeneratorHttpCacheV1"]).to.be.equal('{"key":{"response":"data"}}')
        end)
    end)
end

if isLune then
    testEZSuite()
else
    return testEZSuite
end
