local RSGCore = exports['rsg-core']:GetCoreObject()



RegisterServerEvent('passengerTransport:rewardPlayer')
AddEventHandler('passengerTransport:rewardPlayer', function(dropoffName)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then
        
        return
    end
    if Player.PlayerData.job.name ~= "taxi" then
       
        TriggerClientEvent('passengerTransport:notify', src, 'You must be a taxi driver to earn rewards!', 'error')
        return
    end

    
    local reward = nil
    for _, dropoff in ipairs(Config.Dropoffs) do
        if dropoff.Name == dropoffName then
            reward = dropoff.Reward
            break
        end
    end

    
    if not reward or type(reward) ~= "number" or reward <= 0 then
       
        return
    end

   
    Player.Functions.AddMoney('cash', reward / 100) 
    if Config.Debug then
        
    end
    
    TriggerClientEvent('passengerTransport:notify', src, 'Earned $' .. (reward / 100) .. ' for dropping off at ' .. dropoffName, 'success')
end)