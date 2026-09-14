return function()
    local Coordinates = require(script.Parent.Parent.Modules.Coordinates)

    describe("Coordinates.worldToGeo", function()
        it("should correctly inverse geoToWorld", function()
            Coordinates.setOrigin(37.7749, -122.4194)
            local wp = Coordinates.geoToWorld(37.7800, -122.4100, 10)
            local resLat, resLon, resAlt = Coordinates.worldToGeo(wp)

            expect(math.abs(resLat - 37.7800) < 0.0001).to.equal(true)
            expect(math.abs(resLon - -122.4100) < 0.0001).to.equal(true)
            expect(math.abs(resAlt - 10) < 0.0001).to.equal(true)
        end)

        it("should correctly inverse geoToWorld when altitude is omitted", function()
            Coordinates.setOrigin(37.7749, -122.4194)
            local wp = Coordinates.geoToWorld(37.7800, -122.4100)
            local resLat, resLon, resAlt = Coordinates.worldToGeo(wp)

            expect(math.abs(resLat - 37.7800) < 0.0001).to.equal(true)
            expect(math.abs(resLon - -122.4100) < 0.0001).to.equal(true)
            expect(math.abs(resAlt - 0) < 0.0001).to.equal(true)
        end)

        it("should correctly handle origin coordinates", function()
            Coordinates.setOrigin(0, 0)
            local wp = Coordinates.geoToWorld(0, 0, 0)
            local resLat, resLon, resAlt = Coordinates.worldToGeo(wp)

            expect(math.abs(resLat - 0) < 0.0001).to.equal(true)
            expect(math.abs(resLon - 0) < 0.0001).to.equal(true)
            expect(math.abs(resAlt - 0) < 0.0001).to.equal(true)
        end)

        it("should correctly invert negative coordinates", function()
            Coordinates.setOrigin(-33.8688, 151.2093)
            local wp = Coordinates.geoToWorld(-33.8700, 151.2100, -5)
            local resLat, resLon, resAlt = Coordinates.worldToGeo(wp)

            expect(math.abs(resLat - -33.8700) < 0.0001).to.equal(true)
            expect(math.abs(resLon - 151.2100) < 0.0001).to.equal(true)
            expect(math.abs(resAlt - -5) < 0.0001).to.equal(true)
        end)
    end)
end
