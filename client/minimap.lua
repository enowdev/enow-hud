local function SetMinimap()
    local minimap = RequestScaleformMovie("minimap")
    SetRadarBigmapEnabled(true, false)
    Wait(0)
    SetRadarBigmapEnabled(false, false)
    while not HasScaleformMovieLoaded(minimap) do
        Wait(0)
    end

    -- Mengatur posisi minimap
    SetMinimapComponentPosition('minimap', 'R', 'B', 0.025, -0.03, 0.153, 0.24)
    SetMinimapComponentPosition('minimap_mask', 'R', 'B', 0.135, 0.12, 0.093, 0.164)
    SetMinimapComponentPosition('minimap_blur', 'R', 'B', 0.012, 0.022, 0.256, 0.337)

    -- Mengatur style minimap
    SetBlipAlpha(GetNorthRadarBlip(), 0) -- Menghilangkan icon utara
    SetRadarZoom(1100)
    SetRadarBigmapEnabled(false, false)

    -- Menambahkan koordinat
    BeginScaleformMovieMethod(minimap, "SETUP_HEALTH_ARMOUR")
    ScaleformMovieMethodAddParamInt(3)
    EndScaleformMovieMethod()
end

CreateThread(function()
    Wait(100)
    SetMinimap()
end)

-- Menampilkan koordinat
CreateThread(function()
    while true do
        Wait(0)
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)
        local heading = GetEntityHeading(playerPed)
        
        -- Format koordinat
        local coordsText = string.format(
            "~w~X: ~b~%.2f ~w~Y: ~b~%.2f ~w~Z: ~b~%.2f ~w~Heading: ~b~%.0f°",
            coords.x, coords.y, coords.z, heading
        )
        
        -- Tampilkan koordinat di atas minimap
        SetTextScale(0.3, 0.3)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 255)
        SetTextEntry("STRING")
        SetTextCentre(true)
        AddTextComponentString(coordsText)
        DrawText(0.89, 0.89) -- Sesuaikan posisi teks
    end
end) 