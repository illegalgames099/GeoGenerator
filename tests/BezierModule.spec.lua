local BezierModule = require(script.Parent.Parent.Modules.BezierModule)

return function()
	describe("lerp", function()
		it("should correctly interpolate between two points", function()
			local a = Vector3.new(0, 0, 0)
			local b = Vector3.new(10, 10, 10)

			local result = BezierModule.lerp(a, b, 0.5)

			expect(result.X).to.equal(5)
			expect(result.Y).to.equal(5)
			expect(result.Z).to.equal(5)
		end)

		it("should return start point when t=0", function()
			local a = Vector3.new(1, 2, 3)
			local b = Vector3.new(10, 20, 30)

			local result = BezierModule.lerp(a, b, 0)

			expect(result.X).to.equal(1)
			expect(result.Y).to.equal(2)
			expect(result.Z).to.equal(3)
		end)

		it("should return end point when t=1", function()
			local a = Vector3.new(1, 2, 3)
			local b = Vector3.new(10, 20, 30)

			local result = BezierModule.lerp(a, b, 1)

			expect(result.X).to.equal(10)
			expect(result.Y).to.equal(20)
			expect(result.Z).to.equal(30)
		end)

		it("should extrapolate backwards when t < 0", function()
			local a = Vector3.new(0, 0, 0)
			local b = Vector3.new(10, 10, 10)

			local result = BezierModule.lerp(a, b, -1)

			expect(result.X).to.equal(-10)
			expect(result.Y).to.equal(-10)
			expect(result.Z).to.equal(-10)
		end)

		it("should extrapolate forwards when t > 1", function()
			local a = Vector3.new(0, 0, 0)
			local b = Vector3.new(10, 10, 10)

			local result = BezierModule.lerp(a, b, 2)

			expect(result.X).to.equal(20)
			expect(result.Y).to.equal(20)
			expect(result.Z).to.equal(20)
		end)
	end)
end
