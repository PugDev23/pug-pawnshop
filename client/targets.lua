CreateThread(function()
    local targetMode = Config.Target
    if targetMode == 'none' then return end

    local ox = GetResourceState('ox_target') == 'started'
    local qb = GetResourceState('qb-target') == 'started'

    if targetMode == 'ox_target' and not ox then return end
    if targetMode == 'qb-target' and not qb then return end
    if targetMode == 'auto' and not (ox or qb) then return end

    local v3 = vec3 or vector3

    for _, shop in ipairs(Config.Shops) do
        if ox then
            exports.ox_target:addBoxZone({
                coords = shop.coords,
                size = v3(1.8, 1.8, 2.2),
                rotation = shop.heading or 0.0,
                debug = false,
                options = {
                    {
                        name = ('pug-pawnshop_%s'):format(shop.id),
                        icon = 'fa-solid fa-hand-holding-dollar',
                        label = shop.label or _L('ui_title'),
                        onSelect = function()
                            CreateCameraNPC(peds[shop.id], {-0.1, 1.1, 0.5})
                            ExecuteCommand('togglehud')
                            TriggerEvent('pug-pawnshop:client:open', shop.id)
                        end,
                        distance = Config.Interaction.openDistance + 0.5
                    }
                }
            })
        elseif qb then
            exports['qb-target']:AddBoxZone(('pug-pawnshop_%s'):format(shop.id), shop.coords, 1.8, 1.8, {
                name = ('pug-pawnshop_%s'):format(shop.id),
                heading = shop.heading or 0.0,
                debugPoly = false,
                minZ = shop.coords.z - 1.0,
                maxZ = shop.coords.z + 1.2
            }, {
                options = {
                    {
                        type = 'client',
                        event = 'pug-pawnshop:client:open',
                        icon = 'fas fa-hand-holding-dollar',
                        label = shop.label or _L('ui_title'),
                        shopId = shop.id
                    }
                },
                distance = Config.Interaction.openDistance + 0.5
            })
        end
    end
end)
