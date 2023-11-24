local ZONESTATE = {}
local ZONE = nil

local function PrepareEverything()
    for zoneName, data in pairs(ZONES) do
        if data.radius then
            ZONES[zoneName].type = 'circle'
            if not data.hidden then
                local blip = AddBlipForRadius(data.center.x, data.center.y, 0.0, data.radius)
                SetBlipColour(blip, data.colour or 2)
                SetBlipAsShortRange(blip, true)
                SetBlipAlpha(blip, data.alpha or 50)
                ZONES[zoneName].blip = blip
            end
        else
            ZONES[zoneName].type = 'rectangle'
            if not data.hidden then
                local blip = AddBlipForArea(data.center.x, data.center.y, 0.0, data.width or 10.0, data.height or 10.0)
                local rotation = data.rotation or 0.0
                rotation = rotation * 1.0 -- So it's always a float
                SetBlipSquaredRotation(blip, rotation)
                SetBlipColour(blip, data.colour or 2)
                SetBlipAsShortRange(blip, true)
                SetBlipAlpha(blip, data.alpha or 50)
                ZONES[zoneName].blip = blip
            end
            RectangleSetup(zoneName)
        end
        if data.marked then
            local blip = AddBlipForCoord(data.center.x, data.center.y, 0.0)
            SetBlipSprite(blip, data.sprite or 280)
            SetBlipColour(blip, data.colour or 2)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentSubstringPlayerName(data.label or "Green Zone")
            EndTextCommandSetBlipName(blip)
            data.markBlip = blip
        end
    end
end

function UpdateZoneState(slow)
    local myLocation = GetEntityCoords(PlayerPedId())
    local lastSeenZone = nil
    for name, _ in pairs(ZONES) do
        if IsInsideZone(name, myLocation) then
            lastSeenZone = name
            if not ZONESTATE[name] then
                TriggerEvent('greenzone:enter', name)
                TriggerServerEvent('greenzone:enter', name)
                print('Entered greenzone ' .. name)
                ZONESTATE[name] = true
            end
        elseif ZONESTATE[name] then
            TriggerEvent('greenzone:exit', name)
            TriggerServerEvent('greenzone:exit', name)
            print('Left greenzone ' .. name)
            ZONESTATE[name] = nil
        end
        if slow then
            Citizen.Wait(0)
        end
    end
    return lastSeenZone
end

Citizen.CreateThread(function()
    local inSession = false
    local prepared = false
    while true do
        Citizen.Wait(0)
        if inSession then
            if not prepared then
                PrepareEverything()
                prepared = true
            end
            ZONE = UpdateZoneState(true)
        else
            Citizen.Wait(250)
            if NetworkIsSessionStarted() then
                inSession = true
            end
        end
    end
end)

function DrawGreenzoneText(zoneLabel)
    if not zoneLabel then return end
    BeginTextCommandDisplayText("STRING")
    SetTextCentre(true)
    SetTextOutline()
    SetTextColour(0, 255, 0, 100)
    SetTextScale(0.3, 0.3)
    AddTextComponentSubstringPlayerName(tostring(zoneLabel))
    EndTextCommandDisplayText(0.5, 0.9)
end

function SetZoneProtection(enable)
    local ped = PlayerPedId()
    if enable then
        SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
    end
    SetPedCanSwitchWeapon(ped, not enable)
    SetPedConfigFlag(ped, 122, enable) -- CPED_CONFIG_FLAG_DisableMelee
    SetPedConfigFlag(ped, 186, enable) -- CPED_CONFIG_FLAG_EnableWeaponBlocking
    SetEntityProofs(
        ped,
        enable, -- Bullet
        enable, -- Fire
        enable, -- Explosion
        enable, -- Collision
        enable, -- Melee
        enable, -- Steam
        enable, -- [Unknown]
        enable  -- Drowning
    )
end

function DrawOutline(zoneName)
    local z = GetEntityCoords(PlayerPedId()).z
    if not ZONES[zoneName] or not ZONES[zoneName].type == 'rectangle' then
        return
    end
    local corners = ZONES[zoneName].corners
    local previous = corners[#corners]
    for _, corner in ipairs(corners) do
        DrawLine(
            corner.x, corner.y, z,
            previous.x, previous.y, z,
            255, 0, 0, 255
        )
        previous = corner
    end
end

Citizen.CreateThread(function()
    local currentlyInZone = false
    while true do
        Citizen.Wait(0)
        if ZONE then
            -- DrawOutline(ZONE)
            DrawGreenzoneText(ZONES[ZONE].label)
            if not currentlyInZone then
                currentlyInZone = true
                if ZONES[ZONE].enforce then
                    SetZoneProtection(true)
                end
            end
        elseif currentlyInZone then
            currentlyInZone = false
            if ZONES[ZONE].enforce then
                SetZoneProtection(false)
            end
        end
    end
end)
