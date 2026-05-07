Bridge = Bridge or {}

Bridge.name = 'standalone'
Bridge.inventory = 'standalone'
Bridge.obj = nil

Bridge._callbacks = {}

local QBCore, ESX = nil, nil

local function detectFramework()
    if Config.Framework == 'qb' or
        (Config.Framework == 'auto' and GetResourceState('qb-core') == 'started') then
        Bridge.name = 'qb'
        local ok, obj = pcall(function()
            return exports['qb-core']:GetCoreObject()
        end)
        if ok then
            QBCore = obj
            Bridge.obj = obj
        end
        return
    end

    if Config.Framework == 'esx' or
        (Config.Framework == 'auto' and GetResourceState('es_extended') ==
            'started') then
        Bridge.name = 'esx'
        local ok, obj = pcall(function()
            return exports['es_extended']:getSharedObject()
        end)
        if ok then
            ESX = obj
            Bridge.obj = obj
        end
        return
    end

    Bridge.name = 'standalone'
end

local function detectInventory()
    if Config.Inventory == 'ox' or
        (Config.Inventory == 'auto' and GetResourceState('ox_inventory') ==
            'started') then
        Bridge.inventory = 'ox'
        return
    end
    if Bridge.name == 'qb' or Bridge.name == 'esx' then
        Bridge.inventory = 'framework'
        return
    end
    Bridge.inventory = 'standalone'
end

detectFramework()
detectInventory()

function Bridge.Log(msg) print(('^3[pug-pawnshop]^0 %s'):format(msg)) end

function Bridge.Debug(msg)
    if not Config.Debug then return end
    print(('^5[pug-pawnshop:debug]^0 %s'):format(msg))
end

function Bridge.CopyTable(t)
    if type(t) ~= 'table' then return t end
    local out = {}
    for k, v in pairs(t) do out[k] = Bridge.CopyTable(v) end
    return out
end

function Bridge.GetIdentifier(src)
    if Bridge.name == 'qb' and QBCore then
        local p = QBCore.Functions.GetPlayer(src)
        if p and p.PlayerData and p.PlayerData.citizenid then
            return p.PlayerData.citizenid
        end
    end

    if Bridge.name == 'esx' and ESX then
        local x = ESX.GetPlayerFromId(src)
        if x and x.identifier then return x.identifier end
    end

    local license = GetPlayerIdentifierByType and
                        GetPlayerIdentifierByType(src, 'license') or nil
    if license then return license end
    return GetPlayerIdentifier(src, 0) or tostring(src)
end

function Bridge.GetItemCount(src, itemName)
    if Bridge.inventory == 'ox' then
        local ok, count = pcall(function()
            return exports.ox_inventory:Search(src, 'count', itemName)
        end)
        if ok and count then return tonumber(count) or 0 end
        return 0
    end

    if Bridge.name == 'qb' and QBCore then
        local p = QBCore.Functions.GetPlayer(src)
        if not p then return 0 end
        local it = p.Functions.GetItemByName(itemName)
        return it and (it.amount or 0) or 0
    end

    if Bridge.name == 'esx' and ESX then
        local x = ESX.GetPlayerFromId(src)
        if not x then return 0 end
        local it = x.getInventoryItem(itemName)
        return it and (it.count or 0) or 0
    end

    return 0
end

function Bridge.RemoveItem(src, itemName, amount)
    amount = tonumber(amount) or 0
    if amount <= 0 then return false end

    if Bridge.inventory == 'ox' then
        local ok, removed = pcall(function()
            return exports.ox_inventory:RemoveItem(src, itemName, amount)
        end)
        return ok and (removed == true or (tonumber(removed) or 0) > 0)
    end

    if Bridge.name == 'qb' and QBCore then
        local p = QBCore.Functions.GetPlayer(src)
        if not p then return false end
        return p.Functions.RemoveItem(itemName, amount)
    end

    if Bridge.name == 'esx' and ESX then
        local x = ESX.GetPlayerFromId(src)
        if not x then return false end
        x.removeInventoryItem(itemName, amount)
        return true
    end

    return false
end

function Bridge.AddItem(src, itemName, amount, metadata)
    amount = tonumber(amount) or 0
    if amount <= 0 then return false end

    if Bridge.inventory == 'ox' then
        local ok, added = pcall(function()
            return exports.ox_inventory:AddItem(src, itemName, amount, metadata)
        end)
        return ok and (added == true or (tonumber(added) or 0) > 0)
    end

    if Bridge.name == 'qb' and QBCore then
        local p = QBCore.Functions.GetPlayer(src)
        if not p then return false end
        return p.Functions.AddItem(itemName, amount, false, metadata)
    end

    if Bridge.name == 'esx' and ESX then
        local x = ESX.GetPlayerFromId(src)
        if not x then return false end
        x.addInventoryItem(itemName, amount)
        return true
    end

    return false
end

function Bridge.AddMoney(src, amount)
    amount = tonumber(amount) or 0
    if amount <= 0 then return false end

    if Bridge.name == 'qb' and QBCore then
        local p = QBCore.Functions.GetPlayer(src)
        if not p then return false end
        p.Functions.AddMoney(Config.Money.type, amount, 'pug-pawnshop')
        return true
    end

    if Bridge.name == 'esx' and ESX then
        local x = ESX.GetPlayerFromId(src)
        if not x then return false end
        if Config.Money.useBlackMoney then
            x.addAccountMoney('black_money', amount)
        else
            x.addMoney(amount)
        end
        return true
    end

    return false
end

function Bridge.RemoveMoney(src, amount)
    amount = tonumber(amount) or 0
    if amount <= 0 then return false end

    if Bridge.name == 'qb' and QBCore then
        local p = QBCore.Functions.GetPlayer(src)
        if not p then return false end
        return p.Functions.RemoveMoney(Config.Money.type, amount, 'pug-pawnshop')
    end

    if Bridge.name == 'esx' and ESX then
        local x = ESX.GetPlayerFromId(src)
        if not x then return false end
        if Config.Money.useBlackMoney then
            local acc = x.getAccount('black_money')
            if not acc or (acc.money or 0) < amount then return false end
            x.removeAccountMoney('black_money', amount)
            return true
        end
        if (x.getMoney() or 0) < amount then return false end
        x.removeMoney(amount)
        return true
    end

    return false
end

-- Metadata-aware removal for ox_inventory.
-- Returns: ok:boolean, chunks: { { amount=number, metadata=table|nil } ... }
function Bridge.RemoveItemWithMetadata(src, itemName, amount)
    amount = tonumber(amount) or 0
    if amount <= 0 then return false, nil end

    if Bridge.inventory ~= 'ox' then
        if Bridge.RemoveItem(src, itemName, amount) then
            return true, {{amount = amount, metadata = nil}}
        end
        return false, nil
    end

    local ok, slots = pcall(function()
        return exports.ox_inventory:Search(src, 'slots', itemName)
    end)
    if not ok or type(slots) ~= 'table' then return false, nil end

    local remaining = amount
    local removed = {}

    for _, s in ipairs(slots) do
        if remaining <= 0 then break end

        local slotId = s.slot or s.slotId or s.id
        local cnt = tonumber(s.count or s.amount) or 0
        local meta = s.metadata

        if slotId and cnt > 0 then
            local take = math.min(cnt, remaining)
            local ok2, res = pcall(function()
                return exports.ox_inventory:RemoveItem(src, itemName, take,
                                                       meta, slotId)
            end)

            local success = ok2 and (res == true or (tonumber(res) or 0) > 0)
            if not success then
                if #removed > 0 then
                    Bridge.AddItemWithChunks(src, itemName, removed)
                end
                return false, nil
            end

            removed[#removed + 1] = {
                amount = take,
                metadata = Bridge.CopyTable(meta)
            }
            remaining = remaining - take
        end
    end

    if remaining > 0 then
        if #removed > 0 then
            Bridge.AddItemWithChunks(src, itemName, removed)
        end
        return false, nil
    end

    return true, removed
end

-- Adds items using chunks (metadata preserved where supported).
function Bridge.AddItemWithChunks(src, itemName, chunks)
    if type(chunks) ~= 'table' or #chunks == 0 then return false end

    if Bridge.inventory == 'ox' then
        for _, ch in ipairs(chunks) do
            local amt = tonumber(ch.amount) or 0
            if amt > 0 then
                local ok, res = pcall(function()
                    return exports.ox_inventory:AddItem(src, itemName, amt, ch.metadata)
                end)
                if not (ok and (res == true or (tonumber(res) or 0) > 0)) then
                    return false
                end
            end
        end
        return true
    end

    if Bridge.name == 'qb' then
        for _, ch in ipairs(chunks) do
            local amt = tonumber(ch.amount) or 0
            if amt > 0 then
                if not Bridge.AddItem(src, itemName, amt, ch.metadata) then
                    return false
                end
            end
        end
        return true
    end

    local total = 0
    for _, ch in ipairs(chunks) do total = total + (tonumber(ch.amount) or 0) end
    return Bridge.AddItem(src, itemName, total)
end

function Bridge.RegisterCallback(name, fn) Bridge._callbacks[name] = fn end

RegisterNetEvent('pug-pawnshop:server:callback', function(id, name, ...)
    local src = source
    local fn = Bridge._callbacks[name]
    if not fn then
        TriggerClientEvent('pug-pawnshop:client:callback', src, id, nil, ('unknown_callback:%s'):format(name))
        return
    end

    local ok, result = pcall(fn, src, ...)
    if not ok then
        Bridge.Log(('Callback error [%s]: %s'):format(name, tostring(result)))
        TriggerClientEvent('pug-pawnshop:client:callback', src, id, nil, 'server_error')
        return
    end

    TriggerClientEvent('pug-pawnshop:client:callback', src, id, result, nil)
end)
