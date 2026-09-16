-- TestEZ specification for Elevation.lua
return function()
	local Elevation = require(script.Parent.Parent.Modules.Elevation)

	describe("Elevation.getOffsetPosition", function()

		local oldGetPosition

		before_each(function()
			Elevation.setElevationOffset(5)
			oldGetPosition = Elevation.getPosition
		end)

		after_each(function()
			-- Ensure mock restoration happens even if assertions throw errors
			if oldGetPosition then
				Elevation.getPosition = oldGetPosition
			end
		end)

		it("returns nil if no intersection is found anywhere", function()
			local emptyMap = {
				{ {v3=Vector3.new(0,0,0)}, {v3=Vector3.new(1,0,0)} },
				{ {v3=Vector3.new(0,0,1)}, {v3=Vector3.new(1,0,1)} }
			}
			local pos = Vector3.new(0,0,0)

			-- Mock intersection to return nil
			Elevation.getPosition = function() return nil end

			local result = Elevation.getOffsetPosition(pos, emptyMap)
			expect(result).to.equal(nil)
		end)

		it("calculates offset position when intersection is found", function()
			local mockMap = {
				{ {v3=Vector3.new(0,0,1)}, {v3=Vector3.new(1,0,1)} },
				{ {v3=Vector3.new(0,0,2)}, {v3=Vector3.new(1,0,2)} }
			}
			local pos = Vector3.new(0,0,0)

			-- Mock intersection to return a fixed Vector3
			Elevation.getPosition = function() return Vector3.new(10, 20, 30) end

			-- Using the actual module's require logic, the default "Elevation multiplier" is 1
			-- (from UI/Presets.lua). The formula is: (intersection.Y + offset) * multiplier
			-- Offset is 5, intersection.Y is 20, multiplier is 1 -> (20+5)*1 = 25
			local result = Elevation.getOffsetPosition(pos, mockMap)

			expect(result).to.be.ok()
			expect(result.X).to.equal(10)
			expect(result.Y).to.equal(25)
			expect(result.Z).to.equal(30)
		end)
	end)
end
