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
local ColorUtils = require(script.Parent.ColorUtils)

return function()
	describe("parseMaterial", function()
		it("should return nil for nil or empty string", function()
			expect(ColorUtils.parseMaterial(nil)).to.equal(nil)
			expect(ColorUtils.parseMaterial("")).to.equal(nil)
		end)

		it("should parse exact material strings correctly", function()
			expect(ColorUtils.parseMaterial("brick")).to.equal(Enum.Material.Brick)
			expect(ColorUtils.parseMaterial("concrete")).to.equal(Enum.Material.Concrete)
			expect(ColorUtils.parseMaterial("glass")).to.equal(Enum.Material.Glass)
			expect(ColorUtils.parseMaterial("wood")).to.equal(Enum.Material.Wood)
			expect(ColorUtils.parseMaterial("stone")).to.equal(Enum.Material.Rock)
		end)

		it("should handle whitespace and mixed casing correctly", function()
			expect(ColorUtils.parseMaterial("  gLASS  ")).to.equal(Enum.Material.Glass)
			expect(ColorUtils.parseMaterial("BriCks")).to.equal(Enum.Material.Brick)
			expect(ColorUtils.parseMaterial("  pLasTiC \t")).to.equal(Enum.Material.Plastic)
		end)

		it("should take the first material from a semicolon-separated list", function()
			expect(ColorUtils.parseMaterial("concrete;wood")).to.equal(Enum.Material.Concrete)
			expect(ColorUtils.parseMaterial("metal;glass")).to.equal(Enum.Material.Metal)
			expect(ColorUtils.parseMaterial(" glass ; metal ")).to.equal(Enum.Material.Glass)
		end)

		it("should return nil for unknown materials", function()
			expect(ColorUtils.parseMaterial("unknown_material")).to.equal(nil)
			expect(ColorUtils.parseMaterial("vibranium")).to.equal(nil)
		end)
	end)
end
