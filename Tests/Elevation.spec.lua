-- Tests for Modules/Elevation.lua

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

    beforeEach = function(fn) fn() end
    afterEach = function(fn) fn() end
end

local testEZSuite = function()
    local Elevation
    if isLune then
        -- In lune, instead of getfenv hack we dynamically patch standard lua global table
        -- but as `run_tests.sh` already executes this file we want it to work in Lune too.
        -- We've already verified the `require` mock using `getfenv().require` actually worked
        -- for `./test_module.lua` import earlier.
        local original_require = require
        getfenv().require = function(arg)
            if type(arg) == "table" and arg.getGenerationRules then
                return arg
            elseif type(arg) == "table" and arg.name == "MockRayTriangle" then
                return original_require("../Modules/RayTriangleIntersection")
            end
            return original_require(arg)
        end

        getfenv().script = {
            Parent = {
                WaitForChild = function(self, childName)
                    if childName == "UI" then
                        return {
                            PropertiesModule = {
                                getGenerationRules = function() return {["Elevation multiplier"] = 1} end
                            }
                        }
                    end
                end,
                RayTriangleIntersection = {name = "MockRayTriangle"}
            }
        }
        getfenv().task = Task

        getfenv().workspace = {
            Raycast = function(self, origin, direction, params)
                return nil
            end
        }

        Elevation = original_require("../Modules/Elevation")
    else
        describe = _G.describe or getfenv().describe
        it = _G.it or getfenv().it
        expect = _G.expect or getfenv().expect
        beforeEach = _G.beforeEach or getfenv().beforeEach
        afterEach = _G.afterEach or getfenv().afterEach

        Elevation = require(script.Parent.Parent.Modules.Elevation)
    end

    describe("Elevation module", function()
        local flatMap = {
            { {v3=Vector3.new(0, 0, 0)}, {v3=Vector3.new(0, 0, 10)} },
            { {v3=Vector3.new(10, 0, 0)}, {v3=Vector3.new(10, 0, 10)} }
        }

        beforeEach(function()
            if typeof(workspace) == "Instance" then
            end
        end)

        afterEach(function()
            if Elevation then
                Elevation.setElevationOffset(nil)
            end
        end)

        it("should hit exact center of flat map", function()
            local hit = Elevation.getPosition(Vector3.new(5, 50, 5), flatMap)
            expect(hit).to.be.ok()
            expect(hit.X).to.be.near(5, 0.001)
            expect(hit.Y).to.be.near(0, 0.001)
            expect(hit.Z).to.be.near(5, 0.001)
        end)

        it("should return nil when out of bounds", function()
            local hit = Elevation.getPosition(Vector3.new(-5, 50, -5), flatMap)
            expect(hit).never.to.be.ok()
        end)

        it("should hit sloped terrain", function()
            local slopedMap = {
                { {v3=Vector3.new(0, 0, 0)}, {v3=Vector3.new(0, 0, 10)} },
                { {v3=Vector3.new(10, 10, 0)}, {v3=Vector3.new(10, 10, 10)} }
            }
            local hit = Elevation.getPosition(Vector3.new(5, 50, 5), slopedMap)
            expect(hit).to.be.ok()
            expect(hit.X).to.be.near(5, 0.001)
            expect(hit.Y).to.be.near(5, 0.001)
            expect(hit.Z).to.be.near(5, 0.001)
        end)

        it("should return correct offset position", function()
            Elevation.setElevationOffset(10)
            local hit = Elevation.getOffsetPosition(Vector3.new(5, 50, 5), flatMap)
            expect(hit).to.be.ok()
            expect(hit.X).to.be.near(5, 0.001)
            expect(hit.Y).to.be.near(10, 0.001)
            expect(hit.Z).to.be.near(5, 0.001)
        end)

        it("should hit fallback map", function()
            Elevation.setElevationOffset(10)
            local fallbackMap = {
                { {v3=Vector3.new(20, 0, 20)}, {v3=Vector3.new(20, 0, 30)} },
                { {v3=Vector3.new(30, 0, 20)}, {v3=Vector3.new(30, 0, 30)} }
            }
            Elevation.addMapToAllMaps(fallbackMap)
            local hit = Elevation.getOffsetPosition(Vector3.new(25, 50, 25), flatMap)
            expect(hit).to.be.ok()
            expect(hit.X).to.be.near(25, 0.001)
            expect(hit.Y).to.be.near(10, 0.001)
            expect(hit.Z).to.be.near(25, 0.001)
        end)

        it("should return nil on total miss", function()
            local hit = Elevation.getOffsetPosition(Vector3.new(-5, 50, -5), flatMap)
            expect(hit).never.to.be.ok()
        end)
    end)
end

if isLune then
    testEZSuite()
else
    return testEZSuite
end
