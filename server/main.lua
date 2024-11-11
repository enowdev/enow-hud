local QBCore = exports['qb-core']:GetCoreObject()

-- Callback untuk config
QBCore.Functions.CreateCallback('qb-newhud:server:GetConfig', function(source, cb)
    cb(Config)
end)