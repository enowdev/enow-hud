local QBCore = exports['qb-core']:GetCoreObject()

-- Server-side events bisa ditambahkan di sini jika diperlukan
-- Misalnya untuk sync stress level atau status lainnya

QBCore.Functions.CreateCallback('qb-newhud:server:GetConfig', function(source, cb)
    cb(Config)
end)