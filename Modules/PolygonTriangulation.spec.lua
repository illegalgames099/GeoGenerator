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
		end)
	end)
end
