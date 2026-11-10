-- Tests for Modules/RayTriangleIntersection.lua

local isLune = false
local success, roblox = pcall(require, "@lune/roblox")
if success then
    isLune = true
    _G.Vector3 = roblox.Vector3
else
    _G.Vector3 = _G.Vector3 or {
        new = function(x, y, z)
            local t = {X = x, Y = y, Z = z}
            setmetatable(t, {
                __tostring = function(self) return string.format("Vector3(%f, %f, %f)", self.X, self.Y, self.Z) end,
                __add = function(a, b) return _G.Vector3.new(a.X + b.X, a.Y + b.Y, a.Z + b.Z) end,
                __sub = function(a, b) return _G.Vector3.new(a.X - b.X, a.Y - b.Y, a.Z - b.Z) end,
                __mul = function(a, b)
                    if type(b) == "number" then
                        return _G.Vector3.new(a.X * b, a.Y * b, a.Z * b)
                    end
                    return nil
                end,
            })
            function t:Cross(other)
                return _G.Vector3.new(
                    self.Y * other.Z - self.Z * other.Y,
                    self.Z * other.X - self.X * other.Z,
                    self.X * other.Y - self.Y * other.X
                )
            end
            function t:Dot(other)
                return self.X * other.X + self.Y * other.Y + self.Z * other.Z
            end
            return t
        end
    }
end

local function assert_approx_eq(expected, actual, tolerance)
    tolerance = tolerance or 0.001
    if math.abs(expected - actual) > tolerance then
        error(string.format("Assertion failed: expected approx %f, got %f", expected, actual))
    end
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
                be = {
                    ok = function() assert(val ~= nil, "Expected ok (not nil)") end,
                    near = function(expected, tol) assert_approx_eq(expected, val, tol) end
                },
                equal = function(expected) assert(val == expected, "Expected equal") end
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

local testEZSuite = function()
    local ray_intersects_triangle
    if isLune then
        local luau = require("@lune/luau")
        local fs = require("@lune/fs")
        local chunk = luau.load(fs.readFile("Modules/RayTriangleIntersection.lua"), { debugName = "Modules/RayTriangleIntersection.lua", injectGlobals = true })
        local env = getfenv(chunk)
        for k, v in pairs(getfenv()) do
            if k ~= "_G" then env[k] = v end
        end
        env.Vector3 = _G.Vector3
        setfenv(chunk, env)
        ray_intersects_triangle = chunk()
    else
        describe = _G.describe or getfenv().describe
        it = _G.it or getfenv().it
        expect = _G.expect or getfenv().expect

        ray_intersects_triangle = require(script.Parent.Parent.Modules.RayTriangleIntersection)
    end

    local Vector3 = _G.Vector3 or (roblox and roblox.Vector3) or (isLune and _G.Vector3) or Vector3

    describe("RayTriangleIntersection", function()
        local a = Vector3.new(0, 0, 0)
        local b = Vector3.new(10, 0, 0)
        local c = Vector3.new(0, 0, 10)

        it("should intersect in the center of the triangle", function()
            local origin = Vector3.new(2, 5, 2)
            local direction = Vector3.new(0, -1, 0)
            local hit = ray_intersects_triangle(origin, direction, a, b, c)

            expect(hit).to.be.ok()
            expect(hit.X).to.be.near(2, 0.001)
            expect(hit.Y).to.be.near(0, 0.001)
            expect(hit.Z).to.be.near(2, 0.001)
        end)

        it("should return nil if missing outside the edges", function()
            local origin = Vector3.new(-1, 5, 2)
            local direction = Vector3.new(0, -1, 0)
            local hit = ray_intersects_triangle(origin, direction, a, b, c)

            expect(hit).never.to.be.ok()
        end)

        it("should return nil if missing outside hypotenuse (u+v>1)", function()
            local origin = Vector3.new(6, 5, 6)
            local direction = Vector3.new(0, -1, 0)
            local hit = ray_intersects_triangle(origin, direction, a, b, c)

            expect(hit).never.to.be.ok()
        end)

        it("should return nil if triangle is behind ray origin (t < 0)", function()
            local origin = Vector3.new(2, 5, 2)
            local direction = Vector3.new(0, 1, 0)
            local hit = ray_intersects_triangle(origin, direction, a, b, c)

            expect(hit).never.to.be.ok()
        end)

        it("should return nil if ray is parallel to triangle", function()
            local origin = Vector3.new(2, 5, 2)
            local direction = Vector3.new(1, 0, 0)
            local hit = ray_intersects_triangle(origin, direction, a, b, c)

            expect(hit).never.to.be.ok()
        end)
    end)
end

if isLune then
    testEZSuite()
else
    return testEZSuite
end
