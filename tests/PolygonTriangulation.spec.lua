local PolygonTriangulation = require(game.ReplicatedStorage.Modules.PolygonTriangulation)

return function()
	describe("PolygonTriangulation.isPolyCCW", function()
		it("should return true for a counter-clockwise polygon", function()
			local ccwPoly = {
				{x = 0, y = 0},
				{x = 10, y = 0},
				{x = 10, y = 10},
				{x = 0, y = 10}
			}
			expect(PolygonTriangulation.isPolyCCW(ccwPoly)).to.equal(true)
		end)

		it("should return false for a clockwise polygon", function()
			local cwPoly = {
				{x = 0, y = 0},
				{x = 0, y = 10},
				{x = 10, y = 10},
				{x = 10, y = 0}
			}
			expect(PolygonTriangulation.isPolyCCW(cwPoly)).to.equal(false)
		end)

		it("should return false for a colinear polygon", function()
			local colinearPoly = {
				{x = 0, y = 0},
				{x = 5, y = 0},
				{x = 10, y = 0}
			}
			expect(PolygonTriangulation.isPolyCCW(colinearPoly)).to.equal(false)
		end)
	end)
end
