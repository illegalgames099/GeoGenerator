-- TestEZ spec for PolygonTriangulation
return function()
	local PolygonTriangulation = require(script.Parent.Parent.Modules.PolygonTriangulation)

	describe("pointInTri", function()
		it("should return true for points strictly inside the triangle", function()
			local p1 = {x = 0, y = 0}
			local p2 = {x = 10, y = 0}
			local p3 = {x = 0, y = 10}

			expect(PolygonTriangulation.pointInTri({x = 2, y = 2}, p1, p2, p3)).to.equal(true)
			expect(PolygonTriangulation.pointInTri({x = 1, y = 1}, p1, p2, p3)).to.equal(true)
			expect(PolygonTriangulation.pointInTri({x = 1, y = 8}, p1, p2, p3)).to.equal(true)
		end)

		it("should return false for points strictly outside the triangle", function()
			local p1 = {x = 0, y = 0}
			local p2 = {x = 10, y = 0}
			local p3 = {x = 0, y = 10}

			expect(PolygonTriangulation.pointInTri({x = 10, y = 10}, p1, p2, p3)).to.equal(false)
			expect(PolygonTriangulation.pointInTri({x = -1, y = -1}, p1, p2, p3)).to.equal(false)
			expect(PolygonTriangulation.pointInTri({x = -1, y = 5}, p1, p2, p3)).to.equal(false)
			expect(PolygonTriangulation.pointInTri({x = 5, y = -1}, p1, p2, p3)).to.equal(false)
		end)

		it("should handle edges", function()
			local p1 = {x = 0, y = 0}
			local p2 = {x = 10, y = 0}
			local p3 = {x = 0, y = 10}

			expect(PolygonTriangulation.pointInTri({x = 5, y = 0}, p1, p2, p3)).to.equal(true)
			expect(PolygonTriangulation.pointInTri({x = 0, y = 5}, p1, p2, p3)).to.equal(true)
			expect(PolygonTriangulation.pointInTri({x = 5, y = 5}, p1, p2, p3)).to.equal(true)
		end)

		it("should handle negative coordinates correctly", function()
			local p1 = {x = -10, y = -10}
			local p2 = {x = 10, y = -10}
			local p3 = {x = 0, y = 10}

			expect(PolygonTriangulation.pointInTri({x = 0, y = 0}, p1, p2, p3)).to.equal(true)
			expect(PolygonTriangulation.pointInTri({x = -5, y = -5}, p1, p2, p3)).to.equal(true)

			expect(PolygonTriangulation.pointInTri({x = 0, y = 15}, p1, p2, p3)).to.equal(false)
			expect(PolygonTriangulation.pointInTri({x = -15, y = -10}, p1, p2, p3)).to.equal(false)
		end)

		it("should handle collinear points properly", function()
			local p1 = {x = 0, y = 0}
			local p2 = {x = 5, y = 0}
			local p3 = {x = 10, y = 0}

			expect(PolygonTriangulation.pointInTri({x = 5, y = 0}, p1, p2, p3)).to.equal(true)
			expect(PolygonTriangulation.pointInTri({x = 5, y = 5}, p1, p2, p3)).to.equal(false)
		end)
	end)
end
