-- Tests for Modules/ProceduralInfill.lua

local isLune = false
local success, roblox = pcall(require, "@lune/roblox")
if success then
    isLune = true
    Vector3 = roblox.Vector3
    Task = { wait = function() end }
end

local function assert_approx_eq(expected, actual, tolerance)
    tolerance = tolerance or 0.001
    if math.abs(expected - actual) > tolerance then
        error(string.format("Assertion failed: expected approx %f, got %f", expected, actual))
    end
end

local describe, it, expect, beforeEach, afterEach

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
                be = {
                    ok = function() assert(val ~= nil, "Expected ok (not nil)") end,
                    near = function(expected, tol) assert_approx_eq(expected, val, tol) end
                },
                equal = function(expected) assert(val == expected, string.format("Expected %s, got %s", tostring(expected), tostring(val))) end
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

    beforeEach = function(fn) fn() end
    afterEach = function(fn) fn() end
end

local testEZSuite = function()
    local ProceduralInfill
    if isLune then
        local luau = require("@lune/luau")
        local fs = require("@lune/fs")

        local source = fs.readFile("Modules/ProceduralInfill.lua")

        local chunk = luau.load(source, { debugName = "Modules/ProceduralInfill.lua", injectGlobals = true })

        local env = getfenv(chunk)

        local original_require = require
        env.require = function(arg)
            if type(arg) == "table" and arg.name == "MockWayOperations" then
                return {}
            end
            return original_require(arg)
        end

        env.script = {
            Parent = {
                Parent = {
                    Objects = {
                        Values = {
                            Scale = { Value = 1 }
                        }
                    }
                },
                WaitForChild = function(self, childName)
                    if childName == "WayOperations" then
                        return { name = "MockWayOperations" }
                    end
                end,
            }
        }

        env.game = {
            GetService = function(self, serviceName)
                if serviceName == "CollectionService" then
                    return {
                        AddTag = function() end
                    }
                end
            end
        }

        env.task = Task
        env.Vector3 = Vector3

        setfenv(chunk, env)
        ProceduralInfill = chunk()
    else
        describe = _G.describe or getfenv().describe
        it = _G.it or getfenv().it
        expect = _G.expect or getfenv().expect
        beforeEach = _G.beforeEach or getfenv().beforeEach
        afterEach = _G.afterEach or getfenv().afterEach

        ProceduralInfill = require(script.Parent.Parent.Modules.ProceduralInfill)
    end

    describe("ProceduralInfill module", function()

        it("polygonBounds should return min and max X and Z", function()
            local ring = {
                Vector3.new(0, 0, 0),
                Vector3.new(10, 0, 0),
                Vector3.new(10, 0, 10),
                Vector3.new(0, 0, 10)
            }
            local minX, maxX, minZ, maxZ = ProceduralInfill.polygonBounds(ring)
            expect(minX).to.equal(0)
            expect(maxX).to.equal(10)
            expect(minZ).to.equal(0)
            expect(maxZ).to.equal(10)
        end)

        it("pointInPolygon should correctly identify points", function()
            local ring = {
                Vector3.new(0, 0, 0),
                Vector3.new(10, 0, 0),
                Vector3.new(10, 0, 10),
                Vector3.new(0, 0, 10)
            }

            -- Inside
            expect(ProceduralInfill.pointInPolygon(5, 5, ring)).to.equal(true)

            -- Outside
            expect(ProceduralInfill.pointInPolygon(15, 5, ring)).to.equal(false)
            expect(ProceduralInfill.pointInPolygon(-5, 5, ring)).to.equal(false)
            expect(ProceduralInfill.pointInPolygon(5, 15, ring)).to.equal(false)
            expect(ProceduralInfill.pointInPolygon(5, -5, ring)).to.equal(false)
        end)

        it("wayPositions should map node IDs to positions", function()
            local data = {
                elements = {
                    { v2 = { X = 1, Y = 2 } },
                    { v2 = { X = 3, Y = 4 } },
                    { v2 = { X = 5, Y = 6 } }
                }
            }
            local nodes = {
                [101] = 1,
                [102] = 2,
                [103] = 3
            }
            local way = {
                nodes = {101, 102, 103}
            }

            local positions = ProceduralInfill.wayPositions(way, data, nodes)
            expect(positions).to.be.ok()
            expect(#positions).to.equal(3)

            expect(positions[1].X).to.equal(1)
            expect(positions[1].Z).to.equal(2)

            expect(positions[2].X).to.equal(3)
            expect(positions[2].Z).to.equal(4)

            expect(positions[3].X).to.equal(5)
            expect(positions[3].Z).to.equal(6)
        end)

        it("wayPositions should return nil if less than 3 positions", function()
            local data = {
                elements = {
                    { v2 = { X = 1, Y = 2 } },
                    { v2 = { X = 3, Y = 4 } }
                }
            }
            local nodes = {
                [101] = 1,
                [102] = 2
            }
            local way = {
                nodes = {101, 102}
            }

            local positions = ProceduralInfill.wayPositions(way, data, nodes)
            expect(positions).never.to.be.ok()
        end)

    end)
end

if isLune then
    testEZSuite()
else
    return testEZSuite
end
