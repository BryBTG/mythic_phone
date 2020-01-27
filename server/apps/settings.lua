RegisterServerEvent('mythic_base:server:CharacterSpawned')
AddEventHandler('mythic_base:server:CharacterSpawned', function()
    local src = source
    local char = exports['mythic_base']:FetchComponent('Fetch'):Source(src):GetData('character')
 
    local settings = Cache:Get('phone-settings')[char:GetData('id')]
    if settings == nil then
        exports['ghmattimysql']:scalar('SELECT data FROM phone_settings WHERE charid = @charid', { ['charid'] = char:GetData('id') }, function(dbSettings)
            if dbSettings ~= nil and json.decode(dbSettings) ~= nil then
                settings = {
                    charid = char:GetData('id'),
                    settings = json.decode(dbSettings)
                }
                Cache.Add:Index('phone-settings', char:GetData('id'), settings)
    
            else
                settings = {
                    charid = char:GetData('id'),
                    settings = {
                        volume = 100,
                        wallpaper = 1,
                        ringtone = 1,
                        text = 1
                    }
                }

                Cache.Add:Index('phone-settings', char:GetData('id'), default)
            end
        end)
    end

    while settings == nil do
        Citizen.Wait(10)
    end

    TriggerClientEvent('mythic_phone:client:SetSettings', src, settings.settings)
    TriggerClientEvent('mythic_phone:client:SetupData', src, { { name = 'settings', data = settings.settings } })
end)

AddEventHandler('mythic_base:shared:ComponentsReady', function()
    Callbacks = Callbacks or exports['mythic_base']:FetchComponent('Callbacks')
    Cache = Cache or exports['mythic_base']:FetchComponent('Cache')

    Cache:Set('phone-settings', {}, function(data)
        for k, v in pairs(data) do
            if v.charid ~= nil and v.unread ~= nil then
                exports['ghmattimysql']:execute('INSERT INTO `phone_settings` (`charid`, `data`) VALUES (@charid, @data) ON DUPLICATE KEY UPDATE `data` = VALUES(`data`)', {
                    ['charid'] = v.charid,
                    ['data'] = json.encode(v.settings)
                })
            end
        end
    end)

    Callbacks:RegisterServerCallback('mythic_phone:server:SaveSettings', function(source, data, cb)
        local char = exports['mythic_base']:FetchComponent('Fetch'):Source(source):GetData('character')
        local settings = Cache:Get('phone-settings')[char:GetData('id')]
        settings.settings = data
        Cache.Update:Index('phone-settings', char:GetData('id'), settings)
        cb(true)
    end)
end)