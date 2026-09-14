local PolygonTriangulation = require(script.Parent.PolygonTriangulation)

return function()
	describe("pointInTri", function()
		local pointInTri = PolygonTriangulation.pointInTri

		it("should return true when point is inside triangle", function()
			local p = {x=0.5, y=0.5}
			local p1 = {x=0, y=0}
			local p2 = {x=1, y=0}
			local p3 = {x=0, y=1}
			expect(pointInTri(p, p1, p2, p3)).to.equal(true)
		end)

		it("should return false when point is outside triangle", function()
			local p = {x=2, y=2}
			local p1 = {x=0, y=0}
			local p2 = {x=1, y=0}
			local p3 = {x=0, y=1}
			expect(pointInTri(p, p1, p2, p3)).to.equal(false)
		end)

		it("should return a boolean for point on edge", function()
			local p = {x=0.5, y=0}
			local p1 = {x=0, y=0}
			local p2 = {x=1, y=0}
			local p3 = {x=0, y=1}
			expect(type(pointInTri(p, p1, p2, p3))).to.equal("boolean")
		end)

		it("should return a boolean for point on vertex", function()
			local p = {x=0, y=0}
			local p1 = {x=0, y=0}
			local p2 = {x=1, y=0}
			local p3 = {x=0, y=1}
			expect(type(pointInTri(p, p1, p2, p3))).to.equal("boolean")
		end)

		it("should handle collinear vertices by returning boolean", function()
			local p = {x=0.5, y=0.5}
			local p1 = {x=0, y=0}
			local p2 = {x=1, y=1}
			local p3 = {x=2, y=2}
			expect(type(pointInTri(p, p1, p2, p3))).to.equal("boolean")
		end)

		it("should return a boolean with different winding orders", function()
			local p = {x=0.5, y=0.5}
			local p1 = {x=0, y=0}
			local p2 = {x=1, y=0}
			local p3 = {x=0, y=1}
			-- CCW
			expect(type(pointInTri(p, p1, p2, p3))).to.equal("boolean")
			-- CW
			expect(type(pointInTri(p, p3, p2, p1))).to.equal("boolean")
		end)
	end)
end
