local entered = "[%i] %s entered green zone %q\n"
local fakeEnter = "[%i] %s claims to have entered green zone %q -- COULD NOT VERIFY\n"
local exited  = "[%i] %s exited green zone %q\n"
local fakeExit = "[%i] %s claims to have exited green zone %q -- COULD NOT VERIFY\n"

for zoneName, data in pairs(ZONES) do
    if data.radius then
        ZONES[zoneName].type = 'circle'
    else
        ZONES[zoneName].type = 'rectangle'
        RectangleSetup(zoneName)
    end
end

RegisterNetEvent('greenzone:enter', function(zone)
    local source = source
    local point = GetEntityCoords(GetPlayerPed(source))
    if IsInsideZone(zone, point.xy) then
        Citizen.Trace(entered:format(source, GetPlayerName(source), zone))
    else
        Citizen.Trace(fakeEnter:format(source, GetPlayerName(source), zone))
    end
end)

RegisterNetEvent('greenzone:exit', function(zone)
    local source = source
    local point = GetEntityCoords(GetPlayerPed(source))
    if not IsInsideZone(zone, point.xy) then
        Citizen.Trace(exited:format(source, GetPlayerName(source), zone))
    else
        Citizen.Trace(fakeExit:format(source, GetPlayerName(source), zone))
    end
        
end)

RegisterCommand("greenzone", function(source, args, raw)
    if source == 0 then
        print("No, the console is not in a greenzone in the game, my friend.")
        return
    end
    if not args[1] then
        print("Give a zone name")
        return
    end

    if not ZONES[args[1]] then
        print("No such zone: " .. args[1])
    end

    local point = GetEntityCoords(GetPlayerPed(source))
    if IsInsideZone(args[1], point, true) then
        print("Yep, inside that zone")
    else
        print("No, not inside that zone")
    end

end, true)