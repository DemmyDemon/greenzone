local allowedDeviance = 3.25

local function dotProduct(A, B, C)
    local BAx = A.x - B.x
    local BAy = A.y - B.y
    local BCx = C.x - B.x
    local BCy = C.y - B.y
    return (BAx * BCx + BAy * BCy)
end

local function crossProduct(A, B, C)
    local BAx = A.x - B.x
    local BAy = A.y - B.y
    local BCx = C.x - B.x
    local BCy = C.y - B.y
    return (BAx * BCy - BAy * BCx)
end

local function angle(A, B, C)
    local dotProduct = dotProduct(A.xy, B.xy, C.xy)
    local crossProduct = crossProduct(A.xy, B.xy, C.xy)
    return math.atan(crossProduct, dotProduct)
end

function GetGreenZones(point)
    local zones = {}
    for name, _ in pairs(ZONES) do
        if IsInsideZone(name, point) then
            table.insert(zones, name)
        end
    end
    return zones
end

function IsInsideAnyZone(point)
    for name, _ in pairs(ZONES) do
        if IsInsideZone(name, point) then
            return true
        end
    end
    return false
end

function IsInsideZone(zoneName, point, detailed)
    if IsDuplicityVersion() then
        assert(point ~= nil, "CALL TO IsInsideZone WITH NO POINT! Not allowed server-side!")
    end
    if detailed then
        print("Checking if inside zone "..zoneName)
    end


    if not point then
        point = GetEntityCoords(PlayerPedId())
        print("No point given, using PlayerPed's coords")
    end
    point = point.xy
    local data = ZONES[zoneName]

    if not data then
        if detailed then
            print("No such zone")
        end
        return
    elseif detailed then
        print('Check is in ' .. data.type..' mode')
    end

    local centerDist = #(data.center.xy - point)
    if centerDist > data.radius then
        if detailed then
            print('Failed radius test')
        end
        return false
    end

    if data.type == 'circle' then
        return true
    end

    local first = data.corners[1]
    local last = data.corners[#data.corners]
    local total = angle(last, point, first)
    if detailed then
        print(string.format('Starting angle is %.3f', total))
    end
    for i, corner in ipairs(data.corners) do
        if i < #data.corners then
            total += angle(corner, point, data.corners[i+1])
            if detailed then
                print(string.format('Now %.3f at corner %i', total, i))
            end
        else
            total += angle(corner, point, first)
            if detailed then
                print(string.format('Now %.3f at last corner', total))
            end
        end
    end

    total = math.abs(total)
    local inside = total > allowedDeviance
    if detailed then
        print(string.format('%.4f > %.4f = %s', total, allowedDeviance, inside))
    end
    return inside
end

function RotatePoint(point, origin, angle)
    angle = angle * math.pi / 180.0;
    local x = math.cos(angle) * (point.x-origin.x) - math.sin(angle) * (point.y-origin.y) + origin.x
    local y = math.sin(angle) * (point.x-origin.x) + math.cos(angle) * (point.y-origin.y) + origin.y
    return vec2(x, y)
end

function RectangleSetup(zoneName)
    local center = ZONES[zoneName].center.xy
    local halfWidth = ZONES[zoneName].width/2
    local halfHeight = ZONES[zoneName].height/2
    local rotation = ZONES[zoneName].rotation * 1.0 -- for Float reasons!

    local topLeft = RotatePoint(center - vector2(halfWidth, -halfHeight), center, rotation)
    local topRight = RotatePoint(center - vector2(-halfWidth, -halfHeight), center, rotation)
    local bottomRight = RotatePoint(center - vector2(-halfWidth, halfHeight), center, rotation)
    local bottomLeft = RotatePoint(center - vector2(halfWidth, halfHeight), center, rotation)

    local corners = {topLeft, topRight, bottomRight, bottomLeft}

    local maxDist = 0

    for _, corner in ipairs(corners) do
        local dist = #(corner - center)
        if dist > maxDist then
            maxDist = dist
        end
    end

    ZONES[zoneName].radius = maxDist
    ZONES[zoneName].corners = corners

    -- Set to true to display debug/testing blips
    if false and not IsDuplicityVersion() then
        for _, corner in ipairs(corners) do
            local cornerBlip = AddBlipForCoord(corner.x, corner.y, 0.0)
            SetBlipSprite(cornerBlip, 9)
            SetBlipSquaredRotation(cornerBlip, rotation)
            SetBlipAlpha(cornerBlip, 200)
            SetBlipColour(cornerBlip, 5)
            SetBlipScale(cornerBlip, 0.05)
            SetBlipHiddenOnLegend(cornerBlip, true)
            SetBlipAsShortRange(cornerBlip, true)
        end
        local rb = AddBlipForRadius(center.x, center.y, 0.0, maxDist)
        SetBlipAlpha(rb, 200)
        SetBlipSprite(rb, 10)
        SetBlipColour(rb, 5)
        SetBlipAsShortRange(rb, true)
    end
end
