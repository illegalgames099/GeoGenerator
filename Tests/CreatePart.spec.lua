-- Tests for Modules/CreatePart.lua

local isLune = false
local success, roblox = pcall(require, "@lune/roblox")
if success then
    isLune = true
    Instance = roblox.Instance
    CFrame = roblox.CFrame
    Vector3 = roblox.Vector3
    Color3 = roblox.Color3
    Enum = roblox.Enum
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
end

local testEZSuite = function()
    local createPart
    if isLune then
        local original_require = require
        getfenv().require = function(arg)
            if arg == "../Modules/CreatePart" then
                local mod = original_require(arg)
                local env = getfenv(mod)
                env.Instance = Instance
                env.CFrame = CFrame
                env.Vector3 = Vector3
                env.Color3 = Color3
                env.Enum = Enum
                env.typeof = typeof
                setfenv(mod, env)
                return mod
            end
            return original_require(arg)
        end
        createPart = require("../Modules/CreatePart")
    else
        describe = _G.describe or getfenv().describe
        it = _G.it or getfenv().it
        expect = _G.expect or getfenv().expect
        createPart = require(script.Parent.Parent.Modules.CreatePart)
    end

    describe("CreatePart module", function()
        it("Required parameters only (CFrame)", function()
            local parent = Instance.new("Folder")
            local cframe = CFrame.new(1, 2, 3)
            local part = createPart(parent, cframe)

            expect(part.ClassName).to.equal("Part")
            expect(part.Parent).to.equal(parent)
            expect(part.CFrame).to.equal(cframe)
            expect(part.CanCollide).to.equal(false)
            expect(part.Anchored).to.equal(true)
        end)

        it("Required parameters only (Vector3)", function()
            local parent = Instance.new("Folder")
            local vec = Vector3.new(4, 5, 6)
            local part = createPart(parent, vec)

            expect(part.CFrame).to.equal(CFrame.new(vec))
        end)

        it("Optional parameters (size, color, material)", function()
            local parent = Instance.new("Folder")
            local cframe = CFrame.new(0, 0, 0)
            local size = Vector3.new(10, 20, 30)
            local color = Color3.new(1, 0, 0)
            local material = Enum.Material.Neon

            local part = createPart(parent, cframe, size, color, material)

            expect(math.abs(part.Size.X - size.X) < 0.001).to.equal(true)
            expect(math.abs(part.Size.Y - size.Y) < 0.001).to.equal(true)
            expect(math.abs(part.Size.Z - size.Z) < 0.001).to.equal(true)

            expect(part.Color).to.equal(color)
            expect(part.Material).to.equal(material)
        end)
    end)
end

if isLune then
    testEZSuite()
else
    return testEZSuite
end
