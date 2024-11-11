local QBCore = exports['qb-core']:GetCoreObject()

local showMapOnFoot = false
local voiceLevel = 2
local isTalking = false
local isInVehicle = false
local currentVehicle = nil
local seatbeltOn = false
local fuelLevel = 0

local updateTimer = 0
local updateInterval = 5000

local lastVehicleHealth = 0
local ejectVelocity = 0.0

local lastSeatbeltState = false

CreateThread(function()
    while true do
        Wait(500)
        local ped = PlayerPedId()
        local Player = QBCore.Functions.GetPlayerData()
        
        SendNUIMessage({
            action = 'updateStatus',
            health = GetEntityHealth(ped) - 100,
            armor = GetPedArmour(ped),
            hunger = Player.metadata["hunger"],
            thirst = Player.metadata["thirst"],
            stamina = 100 - GetPlayerSprintStaminaRemaining(PlayerId()),
            oxygen = IsPedSwimmingUnderWater(ped) and GetPlayerUnderwaterTimeRemaining(PlayerId()) * 10.0 or 100
        })
        Wait(Config.UpdateInterval)
    end
end)

CreateThread(function()
    while true do
        local sleep = 200
        local ped = PlayerPedId()
        
        if IsPedInAnyVehicle(ped, false) then
            sleep = 100
            local vehicle = GetVehiclePedIsIn(ped, false)
            
            if DoesEntityExist(vehicle) and GetPedInVehicleSeat(vehicle, -1) == ped then
                if lastSeatbeltState ~= seatbeltOn then
                    lastSeatbeltState = seatbeltOn
                end
                
                SendNUIMessage({
                    action = 'updateVehicle',
                    show = true,
                    speed = math.ceil(GetEntitySpeed(vehicle) * 3.6),
                    fuel = math.ceil(GetVehicleFuelLevel(vehicle)),
                    engine = math.ceil((GetVehicleEngineHealth(vehicle) / 1000) * 100),
                    seatbelt = seatbeltOn
                })
            end
        else
            if lastSeatbeltState then
                lastSeatbeltState = false
                seatbeltOn = false
            end
            
            SendNUIMessage({
                action = 'updateVehicle',
                show = false
            })
            sleep = 1000
        end
        
        Wait(sleep)
    end
end)

CreateThread(function()
    while true do
        Wait(0)
        local player = PlayerPedId()
        
        if IsPauseMenuActive() then
            SendNUIMessage({ action = 'toggleHud', show = false })
        else
            SendNUIMessage({ action = 'toggleHud', show = true })
        end
    end
end)

RegisterCommand('testhud', function()
    print("Test command executed")
    SendNUIMessage({ type = 'hud', display = false, debug = { test = true } })
end)

RegisterCommand('showmap', function()
    local ped = PlayerPedId()
    
    if not IsPedInAnyVehicle(ped, false) then
        showMapOnFoot = not showMapOnFoot
        DisplayRadar(showMapOnFoot)
        SendNUIMessage({
            action = 'toggleMinimapBorder',
            show = showMapOnFoot
        })
        
        if showMapOnFoot then
            QBCore.Functions.Notify('Map ditampilkan', 'success')
        else
            QBCore.Functions.Notify('Map disembunyikan', 'error')
        end
    else
        QBCore.Functions.Notify('Tidak bisa mengubah tampilan map saat dalam kendaraan', 'error')
    end
end)

CreateThread(function()
    while true do
        Wait(1000)
        if LocalPlayer.state.isLoggedIn then
            local PlayerData = QBCore.Functions.GetPlayerData()
            
            local player = PlayerPedId()
            local health = GetEntityHealth(player)
            if health < 100 then health = 0 else health = health - 100 end
            
            local armor = GetPedArmour(player)
            
            local hunger = PlayerData.metadata['hunger'] or 100
            local thirst = PlayerData.metadata['thirst'] or 100

            SendNUIMessage({ action = 'updateStatus', health = health, armor = armor, hunger = hunger, thirst = thirst })
        end
    end
end)


RegisterCommand('toggleseatbelt', function()
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then
        seatbeltOn = not seatbeltOn
        
        if seatbeltOn then
            TriggerServerEvent("InteractSound_SV:PlayOnSource", "carbuckle", 0.25)
            QBCore.Functions.Notify('Seatbelt: ON', 'success')
        else
            TriggerServerEvent("InteractSound_SV:PlayOnSource", "carunbuckle", 0.25)
            QBCore.Functions.Notify('Seatbelt: OFF', 'error')
        end

        local vehicle = GetVehiclePedIsIn(ped, false)
        if DoesEntityExist(vehicle) then
            SendNUIMessage({
                action = 'updateVehicle',
                show = true,
                speed = math.ceil(GetEntitySpeed(vehicle) * 3.6),
                fuel = math.ceil(GetVehicleFuelLevel(vehicle)),
                engine = math.ceil((GetVehicleEngineHealth(vehicle) / 1000) * 100),
                seatbelt = seatbeltOn
            })
        end
    end
end)

RegisterKeyMapping('toggleseatbelt', 'Toggle Seatbelt', 'keyboard', 'B')

CreateThread(function()
    while true do
        local sleep = 100
        local ped = PlayerPedId()
        
        if IsPedInAnyVehicle(ped, false) then
            if seatbeltOn then
                sleep = 0
                DisableControlAction(0, 75, true)  -- F
                DisableControlAction(0, 23, true)  -- F/Enter
                DisableControlAction(0, 47, true)  -- G
                DisableControlAction(0, 74, true)  -- H
                
                DisableControlAction(0, 73, true)  -- X
                
                if DoesEntityExist(GetVehiclePedIsIn(ped, false)) and IsControlJustReleased(0, 75) then
                    QBCore.Functions.Notify('Anda tidak bisa keluar saat menggunakan seatbelt', 'error')
                end
            end
        else
            sleep = 1000
        end
        
        Wait(sleep)
    end
end)

CreateThread(function()
    while true do
        Wait(0)
        local ped = PlayerPedId()
        
        if IsPedInAnyVehicle(ped, false) then
            local vehicle = GetVehiclePedIsIn(ped, false)
            if DoesEntityExist(vehicle) then
                local speed = GetEntitySpeed(vehicle) * 3.6
                
                if seatbeltOn and speed > 40 then
                    DisableControlAction(0, 75, true)
                end
                
                if not seatbeltOn and speed > 60 then
                    if HasEntityCollidedWithAnything(vehicle) then
                        local coords = GetEntityCoords(ped)
                        SetEntityCoords(ped, coords.x, coords.y, coords.z - 0.47, true, true, true)
                        SetPedToRagdoll(ped, 1000, 1000, 0, 0, 0, 0)
                        TriggerEvent('QBCore:Notify', 'You were ejected!', 'error')
                    end
                end
            end
        else
            Wait(1000)
        end
    end
end)

AddEventHandler('pma-voice:setTalkingMode', function(mode)
    voiceLevel = mode
    SendNUIMessage({
        action = 'voiceUpdate',
        isTalking = isTalking,
        voiceLevel = voiceLevel
    })
end)

AddEventHandler('pma-voice:radioActive', function(talking)
    isTalking = talking
    SendNUIMessage({
        action = 'voiceUpdate',
        isTalking = isTalking,
        voiceLevel = voiceLevel
    })
end)

AddEventHandler('pma-voice:talking', function(talking)
    isTalking = talking
    SendNUIMessage({
        action = 'voiceUpdate',
        isTalking = isTalking,
        voiceLevel = voiceLevel
    })
end)

CreateThread(function()
    Wait(1000)
    SendNUIMessage({
        action = 'voiceUpdate',
        isTalking = false,
        voiceLevel = 2
    })
end)

function CalculateMinimap()
    local safezoneSize = GetSafeZoneSize()
    local aspectRatio = GetAspectRatio(false)

    if aspectRatio > 2 then aspectRatio = 16 / 9 end

    local screenWidth, screenHeight = GetActiveScreenResolution()
    local xScale = 1.0 / screenWidth
    local yScale = 1.0 / screenHeight

    local minimap = {
        width = xScale * (screenWidth / (4 * aspectRatio)),
        height = yScale * (screenHeight / 5.674),
        leftX = xScale * (screenWidth * (1.0 / 20.0 * ((math.abs(safezoneSize - 1.0)) * 10))),
        bottomY = 1.0 - yScale * (screenHeight * (1.0 / 20.0 * ((math.abs(safezoneSize - 1.0)) * 10)))
    }
    
    if aspectRatio > 2 then
        minimap.leftX = minimap.leftX + minimap.width * 0.845
        minimap.width = minimap.width * 0.76
    elseif aspectRatio > 1.8 then
        minimap.leftX = minimap.leftX + minimap.width * 0.2225
        minimap.width = minimap.width * 0.995
    end
    
    minimap.topY = minimap.bottomY - minimap.height

    return {
        width = minimap.width * screenWidth,
        height = minimap.height * screenHeight,
        left = minimap.leftX * 100,
        top = minimap.topY * 100
    }
end

CreateThread(function()
    while true do
        Wait(1000)
        local minimapData = CalculateMinimap()
        
        SendNUIMessage({
            action = 'updateMinimapPosition',
            data = minimapData
        })
    end
end)

AddEventHandler('onClientResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then return end
    
    SendNUIMessage({
        action = 'voiceUpdate',
        isTalking = false,
        voiceLevel = 2
    })
end)

CreateThread(function()
    while true do
        Wait(200)
        local talking = NetworkIsPlayerTalking(PlayerId())
        if isTalking ~= talking then
            isTalking = talking
            SendNUIMessage({
                action = 'voiceUpdate',
                isTalking = isTalking,
                voiceLevel = voiceLevel
            })
        end
    end
end)

CreateThread(function()
    while true do
        local sleep = 1000
        local ped = PlayerPedId()
        
        if IsPedInAnyVehicle(ped, false) and not seatbeltOn then
            sleep = 100
            local vehicle = GetVehiclePedIsIn(ped, false)
            
            if DoesEntityExist(vehicle) then
                local currentHealth = GetEntityHealth(vehicle)
                local speed = GetEntitySpeed(vehicle) * 3.6
                
                local healthDelta = lastVehicleHealth - currentHealth
                local minDamageForEject = 30
                
                if speed > 120 and healthDelta > minDamageForEject then
                    local ejectChance = (healthDelta * speed) / 25000
                    
                    local driverPed = GetPedInVehicleSeat(vehicle, -1)
                    if driverPed == ped then
                        ejectChance = ejectChance * 0.7
                    end
                    
                    if ejectChance > 0.7 then
                        ejectChance = 0.7
                    end
                    
                    if math.random() < ejectChance then
                        local coords = GetEntityCoords(ped)
                        local forward = GetEntityForwardVector(vehicle)
                        
                        SetEntityCoords(ped, coords.x, coords.y, coords.z - 0.47, true, true, true)
                        SetEntityVelocity(ped, 
                            forward.x * (speed/80),
                            forward.y * (speed/80),
                            forward.z + 1.0
                        )
                        SetPedToRagdoll(ped, 4000, 4000, 0, 0, 0, 0)
                        
                        local health = GetEntityHealth(ped)
                        local damage = math.random(10, 20)
                        SetEntityHealth(ped, health - damage)
                        
                        TriggerEvent('QBCore:Notify', 'Anda terlempar karena tidak menggunakan seatbelt!', 'error')
                    end
                end
                
                lastVehicleHealth = currentHealth
            end
        else
            lastVehicleHealth = 0
        end
        
        Wait(sleep)
    end
end)

CreateThread(function()
    while true do
        local sleep = 1000
        local ped = PlayerPedId()
        
        if IsPedInAnyVehicle(ped, false) then
            DisplayRadar(true)
            SendNUIMessage({
                action = 'toggleMinimapBorder',
                show = true
            })
        else
            if not showMapOnFoot then
                DisplayRadar(false)
                SendNUIMessage({
                    action = 'toggleMinimapBorder',
                    show = false
                })
            end
        end
        
        Wait(sleep)
    end
end)