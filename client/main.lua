local isOpen = false
local currentShopId = nil
local nearbyShopId = nil

local function shopById(id)
    for _, s in ipairs(Config.Shops) do if s.id == id then return s end end
    return nil
end

local function spawnShopPed(shop)
    if not shop.ped or not shop.ped.model then return end
    local model = GetHashKey(shop.ped.model)
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(0) end

    local ped = CreatePed(0, model, shop.coords.x, shop.coords.y, shop.coords.z - 1.0, shop.coords.w or 0.0, false, false)
    SetEntityInvincible(ped, true)
    FreezeEntityPosition(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    if shop.ped.scenario then
        TaskStartScenarioInPlace(ped, shop.ped.scenario, 0, true)
    end
    SetModelAsNoLongerNeeded(model)
    peds[shop.id] = ped
end

local function createBlip(shop)
    if not shop.blip or not shop.blip.enabled then return end
    local b = AddBlipForCoord(shop.coords.x, shop.coords.y, shop.coords.z)
    SetBlipSprite(b, shop.blip.sprite or 605)
    SetBlipScale(b, shop.blip.scale or 0.8)
    SetBlipColour(b, shop.blip.color or 47)
    SetBlipAsShortRange(b, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(shop.label or _L('ui_title'))
    EndTextCommandSetBlipName(b)
    SetBlipCategory(b, 10)
end

local function setBusy(state) SendNUIMessage({action = 'busy', busy = state}) end

local busyToken = 0

local function scheduleBusyFailsafe()
    local timeoutMs = (Config and Config.Security and
                          Config.Security.callbackTimeoutMs) or 8000
    local token = GetGameTimer()
    busyToken = token
    SetTimeout(timeoutMs + 1500, function()
        if busyToken ~= token then return end
        setBusy(false)
        Bridge.Notify(_L('notify_timeout'), 'error')
    end)
end

local function refreshUi()
    if not isOpen or not currentShopId then return end
    Bridge.Callback('pug-pawnshop:uiData', function(payload, err)
        if not payload then
            Bridge.Notify((err == 'timeout' and _L('notify_timeout')) or err or
                              _L('notify_invalid'), 'error')
            return
        end
        SendNUIMessage({action = 'update', data = payload})
    end, currentShopId)
end

local function openShop(shopId)
    if isOpen then return end
    Bridge.Callback('pug-pawnshop:uiData', function(payload, err)
        if not payload then
            Bridge.Notify((err == 'timeout' and _L('notify_timeout')) or err or
                              _L('notify_invalid'), 'error')
            return
        end
        isOpen = true
        currentShopId = shopId
        SetNuiFocus(true, true)
        SendNUIMessage({action = 'open', data = payload})
    end, shopId)
end

local function closeShop()
    isOpen = false
    currentShopId = nil
    SetNuiFocus(false, false)
    SendNUIMessage({action = 'close'})
end

RegisterNetEvent('pug-pawnshop:client:open', function(arg)
    local shopId = arg
    if type(arg) == 'table' then shopId = arg.shopId or arg.id end
    shopId = tostring(shopId or '')
    local shop = shopById(shopId)
    if not shop then return end
    openShop(shopId)
end)

RegisterNetEvent('pug-pawnshop:client:refresh', function() refreshUi() end)

RegisterNUICallback('close', function(_, cb)
    setBusy(false)
    closeShop()
    cb({ok = true})
end)

RegisterNUICallback('sell', function(data, cb)
    if not data or not data.shopId or not data.item then
        cb({ok = false})
        return
    end

    cb({ok = true})
    setBusy(true)
    scheduleBusyFailsafe()

    Bridge.Callback('pug-pawnshop:sell', function(res, err)
        setBusy(false)
        if not res then
            Bridge.Notify((err == 'timeout' and _L('notify_timeout')) or err or
                              _L('notify_invalid'), 'error')
            return
        end

        Bridge.Notify(res.message or _L('notify_invalid'),
                      res.ok and 'success' or 'error')
        if res.ui then
            SendNUIMessage({action = 'update', data = res.ui})
        else
            refreshUi()
        end
    end, data.shopId, data.item, tonumber(data.amount) or 0,
                    tostring(data.mode or 'quick'))
end)

RegisterNUICallback('buyback', function(data, cb)
    if not data or not data.entryId then
        cb({ok = false})
        return
    end

    cb({ok = true})
    setBusy(true)
    scheduleBusyFailsafe()

    Bridge.Callback('pug-pawnshop:buyback', function(res, err)
        setBusy(false)
        if not res then
            Bridge.Notify((err == 'timeout' and _L('notify_timeout')) or err or
                              _L('notify_invalid'), 'error')
            return
        end

        Bridge.Notify(res.message or _L('notify_invalid'),
                      res.ok and 'success' or 'error')
        if res.ui then
            SendNUIMessage({action = 'update', data = res.ui})
        else
            refreshUi()
        end
    end, data.entryId, tonumber(data.amount) or 0)
end)

RegisterNUICallback('contract', function(data, cb)
    if not data or not data.shopId then
        cb({ok = false})
        return
    end

    cb({ok = true})
    setBusy(true)
    scheduleBusyFailsafe()

    Bridge.Callback('pug-pawnshop:contract', function(res, err)
        setBusy(false)
        if not res then
            Bridge.Notify((err == 'timeout' and _L('notify_timeout')) or err or
                              _L('notify_invalid'), 'error')
            return
        end

        Bridge.Notify(res.message or _L('notify_invalid'),
                      res.ok and 'success' or 'error')
        if res.ui then
            SendNUIMessage({action = 'update', data = res.ui})
        else
            refreshUi()
        end
    end, data.shopId)
end)

RegisterNUICallback('rumor', function(data, cb)
    if not data or not data.shopId then
        cb({ok = false})
        return
    end

    cb({ok = true})

    Bridge.Callback('pug-pawnshop:rumor', function(res, err)
        if not res then
            Bridge.Notify((err == 'timeout' and _L('notify_timeout')) or err or
            _L('notify_invalid'), 'error')
            return
        end
        SendNUIMessage({action = 'rumor', data = res})
    end, data.shopId)
end)

CreateThread(function()
    for _, shop in ipairs(Config.Shops) do
        spawnShopPed(shop)
        createBlip(shop)
    end
end)

RegisterCommand(Config.Interaction.keyMappingCommand, function() if nearbyShopId then openShop(nearbyShopId) end end,false)

RegisterKeyMapping(Config.Interaction.keyMappingCommand, 'Open Pawnshop','keyboard', Config.Interaction.keyMappingDefault)
