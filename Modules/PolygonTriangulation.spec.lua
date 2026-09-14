return function()
	local PolygonTriangulation = require(script.Parent.PolygonTriangulation)

	describe("signedPolyArea", function()
		it("should calculate positive area for counter-clockwise polygons", function()
			-- In Lua and Luau, modules loaded via `require()` typically return whatever the module returns.
			-- `PolygonTriangulation` returns a function `TriangulateMain`.
			-- So `PolygonTriangulation` is a function, not a table.
			-- `getfenv(PolygonTriangulation)` gets the environment of that function, where `signedPolyArea` is defined.
			local signedPolyArea = signedPolyArea or getfenv(PolygonTriangulation).signedPolyArea
			local square = {
				{x = 0, y = 0},
				{x = 10, y = 0},
				{x = 10, y = 10},
				{x = 0, y = 10}
			}
			-- 10*10 = 100, signedPolyArea returns twice the signed area -> 200
			expect(signedPolyArea(square)).to.equal(200)

			local triangle = {
				{x = 0, y = 0},
				{x = 10, y = 0},
				{x = 0, y = 10}
			}
			expect(signedPolyArea(triangle)).to.equal(100)
		end)

		it("should calculate negative area for clockwise polygons", function()
			local signedPolyArea = signedPolyArea or getfenv(PolygonTriangulation).signedPolyArea
			local reversedSquare = {
				{x = 0, y = 10},
				{x = 10, y = 10},
				{x = 10, y = 0},
				{x = 0, y = 0}
			}
			expect(signedPolyArea(reversedSquare)).to.equal(-200)
		end)

		it("should return 0 for degenerate polygons (lines/points)", function()
			local signedPolyArea = signedPolyArea or getfenv(PolygonTriangulation).signedPolyArea
			local line = {
				{x = 0, y = 0},
				{x = 10, y = 10},
				{x = 20, y = 20}
			}
			expect(signedPolyArea(line)).to.equal(0)

			local point = {
				{x = 5, y = 5}
			}
			expect(signedPolyArea(point)).to.equal(0)
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
