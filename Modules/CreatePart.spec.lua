local CreatePart = require(script.Parent.CreatePart)

return function()
	-- We need to mock typeof and type because standard Roblox typeof handles Vector3/CFrame/Instance
	local function customTypeof(val)
		if type(val) == "table" then
			if val.isMockVector3 then return "Vector3" end
			if val.isMockCFrame then return "CFrame" end
			if val.ClassName then return "Instance" end
		end
		return type(val)
	end

	local originalEnv = getfenv(CreatePart)

	local function setupMocks()
		local vecMetatable = {
			__eq = function(a, b)
				if type(a) ~= "table" or type(b) ~= "table" then return false end
				return math.abs(a.X - b.X) < 0.001 and math.abs(a.Y - b.Y) < 0.001 and math.abs(a.Z - b.Z) < 0.001
			end
		}

		local mockEnv = {
			Instance = {
				new = function(className)
					local part = {
						ClassName = className,
						Name = className,
						Parent = nil,
						CFrame = nil,
						Size = nil,
						Color = nil,
						Material = nil,
						CanCollide = true,
						Anchored = false
					}
					return part
				end
			},
			Vector3 = {
				new = function(x, y, z)
					local v = {X = x, Y = y, Z = z, isMockVector3 = true}
					setmetatable(v, vecMetatable)
					return v
				end
			},
			CFrame = {
				new = function(pos)
					return {Position = pos, isMockCFrame = true}
				end
			},
			typeof = customTypeof,
			type = type
		}

		-- Fallback to the original environment for standard globals (print, warn, etc.)
		setmetatable(mockEnv, {
			__index = originalEnv
		})

		setfenv(CreatePart, mockEnv)
	end

	local function teardownMocks()
		setfenv(CreatePart, originalEnv)
	end

	describe("CreatePart", function()
		before_each(function()
			setupMocks()
		end)

		after_each(function()
			teardownMocks()
		end)

		it("should create a part with default properties", function()
			local mockParent = {Name = "Folder"}
			local mockEnv = getfenv(CreatePart)
			local mockPos = mockEnv.Vector3.new(0, 0, 0)

			local part = CreatePart(mockParent, mockPos)

			expect(part).to.be.ok()
			expect(part.Parent).to.equal(mockParent)
			expect(part.ClassName).to.equal("Part")
			expect(part.CanCollide).to.equal(false)
			expect(part.Anchored).to.equal(true)
			expect(part.Name).to.equal("Part")
		end)

		it("should set CFrame correctly when given a Vector3", function()
			local mockParent = {}
			local mockEnv = getfenv(CreatePart)
			local mockPos = mockEnv.Vector3.new(10, 20, 30)

			local part = CreatePart(mockParent, mockPos)

			expect(part.CFrame).to.be.ok()
			expect(part.CFrame.isMockCFrame).to.equal(true)
			expect(part.CFrame.Position).to.equal(mockPos)
		end)

		it("should set CFrame correctly when given a CFrame", function()
			local mockParent = {}
			local mockEnv = getfenv(CreatePart)
			local mockPos = mockEnv.Vector3.new(5, 5, 5)
			local mockCFrame = mockEnv.CFrame.new(mockPos)

			local part = CreatePart(mockParent, mockCFrame)

			expect(part.CFrame).to.equal(mockCFrame)
		end)

		it("should apply optional properties when provided", function()
			local mockParent = {}
			local mockEnv = getfenv(CreatePart)
			local mockPos = mockEnv.Vector3.new(0, 0, 0)
			local mockSize = mockEnv.Vector3.new(5, 5, 5)
			local mockColor = {R=1, G=0, B=0} -- Mock Color3
			local mockMaterial = "Brick" -- Mock Enum

			local part = CreatePart(mockParent, mockPos, mockSize, mockColor, mockMaterial)

			expect(part.Size).to.equal(mockSize)
			expect(part.Color).to.equal(mockColor)
			expect(part.Material).to.equal(mockMaterial)
		end)

		it("should set name to Debug when size is exactly 0.1, 0.2, 0.1", function()
			local mockParent = {}
			local mockEnv = getfenv(CreatePart)
			local mockPos = mockEnv.Vector3.new(0, 0, 0)
			local mockSize = mockEnv.Vector3.new(0.1, 0.2, 0.1)

			local part = CreatePart(mockParent, mockPos, mockSize)

			expect(part.Name).to.equal("Debug")
		end)
	end)
end
