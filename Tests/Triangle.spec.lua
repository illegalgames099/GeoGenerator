local isLune = false
local success, roblox = pcall(require, "@lune/roblox")
if success then
    isLune = true
    Vector3 = roblox.Vector3
    CFrame = roblox.CFrame
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
                equal = function(expected) assert(val == expected, "Expected " .. tostring(expected) .. ", got " .. tostring(val)) end
            }
        }
    end

    beforeEach = function(fn) fn() end
    afterEach = function(fn) fn() end
end

local testEZSuite = function()
    local Triangle
    if isLune then
        local luau = require("@lune/luau")
        local fs = require("@lune/fs")

        local source = fs.readFile("Modules/Triangle.lua")
        local chunk = luau.load(source, { debugName = "Modules/Triangle.lua", injectGlobals = true })

        local env = getfenv(chunk)

        local original_require = require
        env.require = function(arg)
            if arg == "CreatePartMock" then
                return function(parent, cframe, size)
                    -- Triangle uses CreatePart which internally returns a Part
                    return {
                        Parent = parent,
                        CFrame = cframe,
                        Size = size,
                        Shape = "Part",
                    }
                end
            end
            return original_require(arg)
        end

        env.script = {
            Parent = {
                WaitForChild = function(self, childName)
                    if childName == "CreatePart" then
                        return "CreatePartMock"
                    end
                    return nil
                end
            }
        }

        env.Vector3 = Vector3
        env.CFrame = CFrame
        env.math = math
        env.table = table
        env.typeof = typeof
        env.Instance = roblox.Instance
        env.Enum = roblox.Enum

        setfenv(chunk, env)
        Triangle = chunk()
    else
        describe = _G.describe or getfenv().describe
        it = _G.it or getfenv().it
        expect = _G.expect or getfenv().expect
        beforeEach = _G.beforeEach or getfenv().beforeEach
        afterEach = _G.afterEach or getfenv().afterEach

        Triangle = require(script.Parent.Parent.Modules.Triangle)
    end

    describe("Triangle module", function()
        local parentMock

        beforeEach(function()
            if not isLune then
                -- In native Roblox, we need a real Instance to pass to CreatePart
                parentMock = Instance.new("Folder")
            else
                parentMock = {}
            end
        end)

        afterEach(function()
            if not isLune and parentMock then
                parentMock:Destroy()
            end
        end)

        it("should generate two wedges for a regular small triangle", function()
            local a = Vector3.new(0, 0, 0)
            local b = Vector3.new(10, 0, 0)
            local c = Vector3.new(0, 0, 10)

            local wedges = Triangle(parentMock, a, b, c)

            expect(#wedges).to.equal(2)

            if isLune then
                expect(wedges[1].Shape).to.equal("Wedge")
                expect(wedges[2].Shape).to.equal("Wedge")
            else
                -- In Roblox environment, setting shape to "Wedge" via the code
                -- creates an Enum.PartType.Wedge Part (since it uses an Instance.new("Part"))
                -- The script does wedge.Shape = "Wedge" which maps to Enum.PartType.Wedge
                expect(wedges[1].Shape).to.equal(Enum.PartType.Wedge)
                expect(wedges[2].Shape).to.equal(Enum.PartType.Wedge)
            end

            expect(wedges[1].Parent).to.equal(parentMock)

            -- Verify size.X is 0 as per the note in the source code
            expect(wedges[1].Size.X).to.be.near(0)
            expect(wedges[2].Size.X).to.be.near(0)
        end)

        it("should recursively split large triangles exceeding the 2048 size limit", function()
            local a = Vector3.new(0, 0, 0)
            local b = Vector3.new(3000, 0, 0) -- Exceeds 2048
            local c = Vector3.new(0, 0, 3000)

            local wedges = Triangle(parentMock, a, b, c)

            -- Because it splits, it should result in more than 2 wedges
            -- A single triangle exceeding 2048 gets split into 4 children triangles per wedge that exceeds it.
            assert(#wedges > 2, "Expected more than 2 wedges for a large triangle, got " .. tostring(#wedges))

            -- Verify all generated parts are wedges
            for i, wedge in ipairs(wedges) do
                if isLune then
                    expect(wedge.Shape).to.equal("Wedge")
                else
                    expect(wedge.Shape).to.equal(Enum.PartType.Wedge)
                end

                expect(wedge.Parent).to.equal(parentMock)
                expect(wedge.Size.X).to.be.near(0)

                -- Check that all resulting wedges respect the limit
                assert(wedge.Size.Y <= 2048.001, "Wedge Y size exceeds 2048")
                assert(wedge.Size.Z <= 2048.001, "Wedge Z size exceeds 2048")
            end
        end)
    end)
end

if isLune then
    testEZSuite()
else
    return testEZSuite
end
