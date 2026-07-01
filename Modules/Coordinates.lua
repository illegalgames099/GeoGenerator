--[[
    GeoGenerator Coordinates Module
    Version: Earth Coordinate System v2

    Features:
        • True Earth coordinates
        • Lat/Lon to Roblox conversion
        • Roblox to Lat/Lon conversion
        • Distance calculations
        • Chunk coordinates
        • Bearing calculations
        • Earth-scale support
]]

local Coordinates = {}

--------------------------------------------------
-- CONSTANTS
--------------------------------------------------

local EARTH_RADIUS = 6378137         -- meters
local STUDS_PER_METER = 3.57
local WORLD_SCALE = STUDS_PER_METER -- studs per meter; updated by newScaler for compatibility

local originLatitude = 0
local originLongitude = 0
local originLatitudeRad = 0

--------------------------------------------------
-- ORIGIN
--------------------------------------------------

function Coordinates.setOrigin(latitude, longitude)
    originLatitude = latitude
    originLongitude = longitude
    originLatitudeRad = math.rad(latitude)
end

function Coordinates.getOrigin()
    return originLatitude, originLongitude
end

--------------------------------------------------
-- LAT/LON → WORLD
--------------------------------------------------

function Coordinates.geoToWorld(latitude, longitude, altitude)

    altitude = altitude or 0

    local lat1 = math.rad(originLatitude)
    local lon1 = math.rad(originLongitude)

    local lat2 = math.rad(latitude)
    local lon2 = math.rad(longitude)

    local x =
        EARTH_RADIUS *
        (lon2 - lon1) *
        math.cos((lat1 + lat2)/2)

    local z =
        EARTH_RADIUS *
        (lat2 - lat1)

    return Vector3.new(
        x * WORLD_SCALE,
        altitude * WORLD_SCALE,
        -z * WORLD_SCALE
    )
end

--------------------------------------------------
-- WORLD → LAT/LON
--------------------------------------------------

function Coordinates.worldToGeo(position)

    local latitude =
        originLatitude +
        math.deg(
            (-position.Z / WORLD_SCALE)
            / EARTH_RADIUS
        )

    local longitude =
        originLongitude +
        math.deg(
            (position.X / WORLD_SCALE)
            /
            (
                EARTH_RADIUS *
                math.cos(
                    math.rad(originLatitude)
                )
            )
        )

    local altitude =
        position.Y / WORLD_SCALE

    return latitude, longitude, altitude
end

--------------------------------------------------
-- DISTANCE
--------------------------------------------------

function Coordinates.distance(
    lat1,
    lon1,
    lat2,
    lon2
)

    local φ1 = math.rad(lat1)
    local φ2 = math.rad(lat2)

    local Δφ = math.rad(lat2 - lat1)
    local Δλ = math.rad(lon2 - lon1)

    local a =
        math.sin(Δφ/2)^2 +
        math.cos(φ1) *
        math.cos(φ2) *
        math.sin(Δλ/2)^2

    local c =
        2 *
        math.atan2(
            math.sqrt(a),
            math.sqrt(1-a)
        )

    return EARTH_RADIUS * c
end

--------------------------------------------------
-- BEARING
--------------------------------------------------

function Coordinates.bearing(
    lat1,
    lon1,
    lat2,
    lon2
)

    local φ1 = math.rad(lat1)
    local φ2 = math.rad(lat2)

    local λ1 = math.rad(lon1)
    local λ2 = math.rad(lon2)

    local y =
        math.sin(λ2 - λ1) *
        math.cos(φ2)

    local x =
        math.cos(φ1) *
        math.sin(φ2)
        -
        math.sin(φ1) *
        math.cos(φ2) *
        math.cos(λ2 - λ1)

    return math.deg(math.atan2(y, x))
end

--------------------------------------------------
-- CHUNKS
--------------------------------------------------

local CHUNK_SIZE_METERS = 1000

function Coordinates.getChunk(
    latitude,
    longitude
)

    local pos =
        Coordinates.geoToWorld(
            latitude,
            longitude
        )

    return
        math.floor(
            pos.X /
            (CHUNK_SIZE_METERS * WORLD_SCALE)
        ),
        math.floor(
            pos.Z /
            (CHUNK_SIZE_METERS * WORLD_SCALE)
        )
end

function Coordinates.getChunkId(
    latitude,
    longitude
)

    local x,z =
        Coordinates.getChunk(
            latitude,
            longitude
        )

    return tostring(x)
        .. "_"
        .. tostring(z)
end

--------------------------------------------------
-- OFFSET
--------------------------------------------------

function Coordinates.offset(
    latitude,
    longitude,
    bearing,
    distance
)

    local δ = distance / EARTH_RADIUS
    local θ = math.rad(bearing)

    local φ1 = math.rad(latitude)
    local λ1 = math.rad(longitude)

    local φ2 =
        math.asin(
            math.sin(φ1)
            *
            math.cos(δ)
            +
            math.cos(φ1)
            *
            math.sin(δ)
            *
            math.cos(θ)
        )

    local λ2 =
        λ1
        +
        math.atan2(
            math.sin(θ)
            *
            math.sin(δ)
            *
            math.cos(φ1),
            math.cos(δ)
            -
            math.sin(φ1)
            *
            math.sin(φ2)
        )

    return
        math.deg(φ2),
        math.deg(λ2)
end

--------------------------------------------------
-- BOUNDS
--------------------------------------------------

function Coordinates.inBounds(
    latitude,
    longitude,
    south,
    west,
    north,
    east
)

    return
        latitude >= south
        and latitude <= north
        and longitude >= west
        and longitude <= east
end

--------------------------------------------------
-- COMPATIBILITY
--------------------------------------------------

function Coordinates.newScaler(scaleFactor, latitude)
    scaleFactor = tonumber(scaleFactor) or 1
    WORLD_SCALE = STUDS_PER_METER * scaleFactor

    if latitude then
        originLatitude = latitude
        originLatitudeRad = math.rad(latitude)
    else
        originLatitudeRad = math.rad(originLatitude)
    end
end

function Coordinates.scale(value)
    return value * WORLD_SCALE
end

function Coordinates.unscale(value)
    return value / WORLD_SCALE
end

function Coordinates.toRoblox(latitude, longitude)
    Coordinates.setOrigin(latitude, longitude)
    return Vector2.new(
        math.rad(longitude) * EARTH_RADIUS * math.cos(originLatitudeRad) * WORLD_SCALE,
        math.rad(latitude) * EARTH_RADIUS * WORLD_SCALE
    )
end

function Coordinates.toRobloxOffset(latitude, longitude, xOffset, yOffset)
    local world = Vector2.new(
        math.rad(longitude) * EARTH_RADIUS * math.cos(originLatitudeRad) * WORLD_SCALE,
        math.rad(latitude) * EARTH_RADIUS * WORLD_SCALE
    )

    return Vector2.new(
        world.X - (xOffset or 0),
        world.Y - (yOffset or 0)
    )
end

function Coordinates.toLatLon(x, y)
    if WORLD_SCALE == 0 then
        return originLatitude, originLongitude
    end

    local latitude = math.deg((y / WORLD_SCALE) / EARTH_RADIUS)
    local longitude = math.deg((x / WORLD_SCALE) / (EARTH_RADIUS * math.cos(originLatitudeRad)))

    return latitude, longitude
end

--------------------------------------------------

return Coordinates
