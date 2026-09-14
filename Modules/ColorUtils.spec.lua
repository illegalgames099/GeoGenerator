return function()
    local ColorUtils = require(script.Parent.ColorUtils)

    describe("parseMaterial", function()
        it("should return nil for nil input", function()
            expect(ColorUtils.parseMaterial(nil)).to.equal(nil)
        end)

        it("should return nil for empty string", function()
            expect(ColorUtils.parseMaterial("")).to.equal(nil)
        end)

        it("should parse happy path known materials", function()
            expect(ColorUtils.parseMaterial("brick")).to.equal(Enum.Material.Brick)
        end)

        it("should ignore case", function()
            expect(ColorUtils.parseMaterial("BRICK")).to.equal(Enum.Material.Brick)
        end)

        it("should ignore whitespace", function()
            expect(ColorUtils.parseMaterial(" cement_block  ")).to.equal(Enum.Material.Concrete)
        end)

        it("should take the first material in a semicolon separated list", function()
            expect(ColorUtils.parseMaterial("glass;brick")).to.equal(Enum.Material.Glass)
        end)

        it("should return nil for unknown materials", function()
            expect(ColorUtils.parseMaterial("unknown_mat")).to.equal(nil)
        end)
    end)
end
