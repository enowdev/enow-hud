local QBCore = exports['qb-core']:GetCoreObject()

-- Variables
local showMapOnFoot = false

-- Thread untuk check pause menu dan map
CreateThread(function()
    while true do
        Wait(0)
        local player = PlayerPedId()
        
        -- Check jika menu ESC dibuka atau map diperbesar
        if IsPauseMenuActive() or IsRadarExpanded() then
            -- Hide HUD elements
            SendNUIMessage({
                action = 'toggleHud',
                show = false
            })
        else
            -- Show HUD elements
            SendNUIMessage({
                action = 'toggleHud',
                show = true
            })
        end
    end
end)

-- Test command
RegisterCommand('testhud', function()
    print("Test command executed")
    SendNUIMessage({
        type = 'hud',
        display = false,
        debug = {
            test = true
        }
    })
end)

-- Command untuk toggle map
RegisterCommand('showmap', function()
    showMapOnFoot = not showMapOnFoot
    if not IsPedInAnyVehicle(PlayerPedId(), false) then
        DisplayRadar(showMapOnFoot)
        SendNUIMessage({
            action = 'toggleMinimapBorder',
            show = showMapOnFoot
        })
    end
    if showMapOnFoot then
        QBCore.Functions.Notify('Map ditampilkan', 'success')
    else
        QBCore.Functions.Notify('Map disembunyikan', 'error')
    end
end)

-- Seatbelt handler
RegisterCommand('+toggleseatbelt', function()
    if IsPedInAnyVehicle(PlayerPedId(), false) then
        seatbeltOn = not seatbeltOn
        TriggerEvent("seatbelt:client:ToggleSeatbelt") -- Trigger event untuk suara/animasi jika ada
        
        -- Play sound (optional)
        if seatbeltOn then
            TriggerServerEvent("InteractSound_SV:PlayOnSource", "carbuckle", 0.25)
        else
            TriggerServerEvent("InteractSound_SV:PlayOnSource", "carunbuckle", 0.25)
        end
    end
end)

RegisterKeyMapping('+toggleseatbelt', 'Toggle Seatbelt', 'keyboard', 'B')

Citizen.CreateThread(function()
    local minimap = RequestScaleformMovie("minimap")
    SetRadarBigmapEnabled(true, false)
    Wait(0)
    SetRadarBigmapEnabled(false, false)
    while true do
        Wait(0)
        BeginScaleformMovieMethod(minimap, "SETUP_HEALTH_ARMOUR")
        ScaleformMovieMethodAddParamInt(3)
        EndScaleformMovieMethod()
    end
end)

-- Thread untuk update status
CreateThread(function()
    while true do
        Wait(1000)
        if LocalPlayer.state.isLoggedIn then
            local PlayerData = QBCore.Functions.GetPlayerData()
            
            -- Update status bars
            local player = PlayerPedId()
            local health = GetEntityHealth(player)
            if health < 100 then health = 0 else health = health - 100 end
            
            local armor = GetPedArmour(player)
            
            -- Get QB-Core metadata
            local hunger = PlayerData.metadata['hunger'] or 100
            local thirst = PlayerData.metadata['thirst'] or 100
            local stress = PlayerData.metadata['stress'] or 0

            SendNUIMessage({
                action = 'updateStatus',
                health = health,
                armor = armor,
                hunger = hunger,
                thirst = thirst,
                stress = stress
            })
        end
    end
end)

-- Thread untuk vehicle HUD
CreateThread(function()
    while true do
        Wait(100)
        if LocalPlayer.state.isLoggedIn then
            local player = PlayerPedId()
            if IsPedInAnyVehicle(player, false) then
                local vehicle = GetVehiclePedIsIn(player, false)
                local speed = GetEntitySpeed(vehicle) * 3.6 -- Konversi ke km/h
                local fuel = GetVehicleFuelLevel(vehicle)
                
                -- Get engine health
                local engineHealth = GetVehicleEngineHealth(vehicle)
                local enginePercent = (engineHealth / 1000) * 100
                
                SendNUIMessage({
                    action = 'updateVehicle',
                    show = true,
                    speed = math.ceil(speed),
                    fuel = math.ceil(fuel),
                    engine = math.ceil(enginePercent),
                    seatbelt = seatbeltOn
                })
            else
                seatbeltOn = false -- Reset seatbelt saat keluar kendaraan
                SendNUIMessage({
                    action = 'updateVehicle',
                    show = false
                })
            end
        end
    end
end)

-- Voice state handlers
AddEventHandler('pma-voice:setTalkingMode', function(mode)
    voiceLevel = mode
    SendVoiceUpdate()
end)

RegisterNetEvent('pma-voice:setVoiceLevel')
AddEventHandler('pma-voice:setVoiceLevel', function(level)
    voiceLevel = level
    SendVoiceUpdate()
end)

function SendVoiceUpdate()
    local voiceData = {
        level = 33 * voiceLevel,
        talking = NetworkIsPlayerTalking(PlayerId())
    }
    
    SendNUIMessage({
        action = 'updateVoice',
        voice = voiceData
    })
end

-- Thread untuk update voice status
CreateThread(function()
    while true do
        Wait(200)
        if LocalPlayer.state.isLoggedIn then
            local talking = NetworkIsPlayerTalking(PlayerId())
            if talking ~= isTalking then
                isTalking = talking
                SendVoiceUpdate()
            end
        end
    end
end)

-- Thread untuk handle minimap dan border
CreateThread(function()
    while true do
        Wait(0)
        local player = PlayerPedId()
        
        if IsPedInAnyVehicle(player, false) then
            DisplayRadar(true)
            SendNUIMessage({
                action = 'toggleMinimapBorder',
                show = true
            })
        else
            -- Tampilkan map berdasarkan status showMapOnFoot
            DisplayRadar(showMapOnFoot)
            SendNUIMessage({
                action = 'toggleMinimapBorder',
                show = showMapOnFoot
            })
        end
    end
end)

-- Optional: Reset map status saat player spawn/respawn
RegisterNetEvent('QBCore:Client:OnPlayerLoaded')
AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    showMapOnFoot = false
    if not IsPedInAnyVehicle(PlayerPedId(), false) then
        DisplayRadar(false)
        SendNUIMessage({
            action = 'toggleMinimapBorder',
            show = false
        })
    end
end)