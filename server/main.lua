local ShopsById = {}
local ShopCatSets = {}

local Players = {}
local Cooldowns = {}
local Buyback = {}

local function buildMaps()
    ShopsById = {}
    ShopCatSets = {}
    for _, s in ipairs(Config.Shops) do
        ShopsById[s.id] = s
        ShopCatSets[s.id] = Utils.arrayToSet(s.categories)
    end
end

buildMaps()
Market.Generate()

local function nowMs() return GetGameTimer() end

local function onCooldown(src)
    local now = nowMs()
    local last = Cooldowns[src] or 0
    if (now - last) < Config.Security.cooldownMs then return true end
    Cooldowns[src] = now
    return false
end

local function withinDistance(src, shop)
    local ped = GetPlayerPed(src)
    if ped == 0 then return true end
    local coords = GetEntityCoords(ped)
    return #(coords - vector3(shop.coords.x, shop.coords.y, shop.coords.z)) <= Config.Security.maxUseDistance
end

local function getState(src)
    local st = Players[src]
    if st then return st end

    local identifier = Bridge.GetIdentifier(src)
    local saved = Persistence.Load(identifier)

    st = {
        identifier = identifier,
        rep = tonumber(saved.rep) or 0,
        heat = tonumber(saved.heat) or 0,
        streak = tonumber(saved.streak) or 0,
        contracts = type(saved.contracts) == 'table' and saved.contracts or {}
    }

    Players[src] = st
    Buyback[identifier] = type(saved.buyback) == 'table' and saved.buyback or {}
    return st
end

local function saveState(src)
    local st = Players[src]
    if not st then return end

    local payload = Bridge.CopyTable(st)
    payload.buyback = Bridge.CopyTable(Buyback[st.identifier] or {})
    Persistence.Save(st.identifier, payload)
end

AddEventHandler('playerDropped', function()
    local src = source
    local st = Players[src]
    local identifier = st and st.identifier or nil

    saveState(src)
    Players[src] = nil
    Cooldowns[src] = nil
    if identifier then Buyback[identifier] = nil end
end)

local function sanitizeAmount(n)
    n = tonumber(n) or 0
    n = math.floor(n)
    if n < 0 then n = 0 end
    return n
end

local function copyMeta(meta)
    if type(meta) ~= 'table' then return nil end
    return Bridge.CopyTable(meta)
end

local function applyBuybackTag(meta, ctx)
    if type(meta) ~= 'table' then meta = {} end
    meta = Bridge.CopyTable(meta)
    meta.pug_pawnshop = {
        buyback = true,
        from = ctx.shopId,
        sold_at = ctx.soldAt,
        unit = ctx.soldUnitPrice
    }
    return meta
end

local function pushBuyback(identifier, entry)
    if not Config.Buyback.enabled then return end
    local list = Buyback[identifier]
    if not list then
        list = {}
        Buyback[identifier] = list
    end

    list[#list + 1] = entry
    while #list > Config.Buyback.maxEntries do table.remove(list, 1) end
end

local function getUiItemImageTemplate()
    local uiCfg = (Config.UI and Config.UI.ItemImages) or {}
    local mode = tostring(uiCfg.mode or 'auto'):lower()

    if mode == 'none' or uiCfg.enabled == false then
        return nil
    end

    if mode == 'custom' then
        local custom = tostring(uiCfg.customPath or '')
        if custom ~= '' and custom:find('%s', 1, true) then
            return custom
        end
        return nil
    end

    if mode == 'auto' then
        if Bridge.inventory == 'ox' then
            mode = 'ox'
        elseif Bridge.name == 'qb' then
            mode = 'qb'
        else
            mode = 'none'
        end
    end

    if mode == 'ox' then
        return 'nui://ox_inventory/web/images/%s.png'
    elseif mode == 'qb' then
        return 'nui://qb-inventory/html/images/%s.png'
    elseif mode == 'qs' then
        return 'nui://qs-inventory/html/images/%s.png'
    end

    return nil
end

local function getBuybackPayload(identifier)
    local list = Buyback[identifier] or {}
    local out = {}
    local now = os.time()
    local itemImageTemplate = getUiItemImageTemplate()

    for i = #list, 1, -1 do
        local e = list[i]
        if (e.expiresAt or 0) <= now or (e.amount or 0) <= 0 then
            table.remove(list, i)
        end
    end

    for _, e in ipairs(list) do
        local expiresIn = (e.expiresAt or 0) - now
        local unit = Utils.round((e.soldUnitPrice or 0) *
                                     Config.Buyback.feeMultiplier)
        out[#out + 1] = {
            entryId = e.entryId,
            shopId = e.shopId,
            shopLabel = (ShopsById[e.shopId] and ShopsById[e.shopId].label) or
                e.shopId,
            item = e.item,
            label = e.label,
            amount = e.amount,
            image = itemImageTemplate and itemImageTemplate:format(e.item) or nil,
            unitBuyback = unit,
            expiresIn = expiresIn
        }
    end

    return out
end

local function buildUiPayload(src, shopId)
    local shop = ShopsById[shopId]
    if not shop then return nil end
    local st = getState(src)
    local itemImageTemplate = getUiItemImageTemplate()

    local items = {}
    local catSet = ShopCatSets[shopId] or {}

    for itemName, itemCfg in pairs(Config.Items) do
        if catSet[itemCfg.category] then
            local entry = Market.GetEntry(shopId, itemName)
            local have = Bridge.GetItemCount(src, itemName)
            local quick = Market.QuoteUnit(shopId, itemName, st.rep, st.heat,
                                           1.0)

            local requiredRep = tonumber(itemCfg.requiredRep) or 0
            local repLocked = (st.rep or 0) < requiredRep

            items[#items + 1] = {
                name = itemName,
                label = itemCfg.label,
                category = itemCfg.category,
                youHave = have,
                demandRemaining = entry and entry.remaining or 0,
                demandInitial = entry and entry.initial or 0,
                requiredRep = requiredRep,
                repLocked = repLocked,
                priceQuick = quick,
                priceNegotiateMin = Utils.round(quick *
                                                    (1.0 +
                                                        Config.Negotiation
                                                            .minBonus)),
                priceNegotiateMax = Utils.round(quick *
                                                    (1.0 +
                                                        Config.Negotiation
                                                            .maxBonus)),
                priceAppraiseMin = Utils.round(quick *
                                                   (Config.Appraisal
                                                       .backfireMultiplier)),
                priceAppraiseMax = Utils.round(quick *
                                                   (1.0 +
                                                       Config.Appraisal.maxBonus)),
                hot = itemCfg.hot or false,
                heatPerUnit = itemCfg.heatPerUnit or 0,
                image = itemImageTemplate and itemImageTemplate:format(itemName) or nil
            }
        end
    end

    table.sort(items, function(a, b)
        if a.youHave == b.youHave then return a.label < b.label end
        return a.youHave > b.youHave
    end)

    local contract = Market.Contracts[shopId]
    local contractPayload = nil
    if contract then
        local reqs = {}
        for _, r in ipairs(contract.requirements or {}) do
            local cfg = Config.Items[r.item]
            reqs[#reqs + 1] = {
                item = r.item,
                label = cfg and cfg.label or r.item,
                amount = r.amount,
                youHave = Bridge.GetItemCount(src, r.item),
                image = itemImageTemplate and itemImageTemplate:format(r.item) or nil
            }
        end

        contractPayload = {
            id = contract.id,
            label = contract.label,
            description = contract.description,
            requirements = reqs,
            bonusMultiplier = contract.bonusMultiplier,
            flatBonus = contract.flatBonus,
            completed = st.contracts and st.contracts[shopId] == contract.id
        }
    end

    local cats = {}
    for k, v in pairs(Config.Categories) do cats[k] = v.label end

    return {
        shop = {id = shop.id, label = shop.label},
        ui = {
            itemImages = {
                enabled = itemImageTemplate ~= nil,
                template = itemImageTemplate,
                fallbackToIcon = not not (((Config.UI or {}).ItemImages or {}).fallbackToIcon)
            }
        },
        player = {
            rep = st.rep,
            heat = st.heat,
            streak = st.streak,
            repMax = Config.Reputation.max,
            heatMax = Config.Heat.max
        },
        market = {
            generatedAt = Market.GeneratedAt,
            events = Market.Events,
            categoryMult = Market.CategoryMult
        },
        categories = cats,
        contract = contractPayload,
        items = items,
        buyback = getBuybackPayload(st.identifier)
    }
end

local function heatDispatchHook(src, shopId, heat)
    TriggerEvent('pug-pawnshop:server:heatDispatch', src, shopId, heat)
end

local function calcNegotiationMult(st)
    if not Config.Negotiation.enabled then return 1.0, 'none' end

    local repT = Utils.clamp((st.rep or 0) / Config.Reputation.max, 0, 1)
    local failChance = Utils.clamp(Config.Negotiation.baseFailChance -
                                       (Config.Negotiation
                                           .failChanceReductionAtMaxRep * repT),
                                   0.02, 0.95)

    local refuseChance = Config.Negotiation.refuseChance
    if Config.Heat.enabled and (st.heat or 0) >= Config.Heat.refusalAt then
        failChance = Utils.clamp(failChance + 0.10, 0.02, 0.95)
        refuseChance = Utils.clamp(refuseChance + 0.06, 0.0, 0.95)
    end

    local roll = math.random()
    if roll < refuseChance then return nil, 'refuse' end

    if roll < (refuseChance + failChance) then
        st.streak = 0
        st.heat = Utils.clamp((st.heat or 0) +
                                  (Config.Negotiation.heatOnAggro or 0), 0,
                              Config.Heat.max)
        return Config.Negotiation.failPayoutMultiplier, 'bad'
    end

    st.streak = Utils.clamp((st.streak or 0) + 1, 0, 25)
    local streakBonus = Utils.clamp((st.streak or 0) * 0.007, 0, 0.06)
    local bonus = Utils.lerp(Config.Negotiation.minBonus,
                             Config.Negotiation.maxBonus, math.random())
    bonus = bonus + (repT * 0.06) + streakBonus
    bonus = Utils.clamp(bonus, Config.Negotiation.minBonus,
                        Config.Negotiation.maxBonus + 0.06)
    return (1.0 + bonus), 'good'
end

local function calcAppraiseMult(st)
    if not Config.Appraisal.enabled then return 1.0, 'none' end

    local repT = Utils.clamp((st.rep or 0) / Config.Reputation.max, 0, 1)
    local backfire = Config.Appraisal.backfireChance
    if Config.Heat.enabled and (st.heat or 0) >= Config.Heat.refusalAt then
        backfire = Utils.clamp(backfire + 0.06, 0.0, 0.95)
    end

    local roll = math.random()
    if roll < backfire then
        st.heat = Utils.clamp((st.heat or 0) +
                                  (Config.Appraisal.heatOnBackfire or 0), 0,
                              Config.Heat.max)
        return Config.Appraisal.backfireMultiplier, 'backfire'
    end

    local bonus = Config.Appraisal.baseBonus + Utils.lerp(0.0, Config.Appraisal.maxBonus, math.random())
    bonus = bonus + repT * 0.08
    bonus = Utils.clamp(bonus, 0.0, Config.Appraisal.maxBonus + 0.08)
    return (1.0 + bonus), 'good'
end

local function planTakeChunks(chunks, takeAmount)
    if type(chunks) ~= 'table' or #chunks == 0 then
        return {{amount = takeAmount, metadata = nil}}, {}
    end

    local give = {}
    local newChunks = {}
    local remaining = takeAmount

    for i, ch in ipairs(chunks) do
        local amt = tonumber(ch.amount) or 0
        local meta = ch.metadata

        if remaining > 0 then
            local take = math.min(amt, remaining)
            if take > 0 then
                give[#give + 1] = {amount = take, metadata = meta}
                amt = amt - take
                remaining = remaining - take
            end
        end

        if amt > 0 then
            newChunks[#newChunks + 1] = {amount = amt, metadata = meta}
        end

        if remaining <= 0 then
            for j = i + 1, #chunks do
                local rest = chunks[j]
                local restAmt = tonumber(rest.amount) or 0
                if restAmt > 0 then
                    newChunks[#newChunks + 1] = {
                        amount = restAmt,
                        metadata = rest.metadata
                    }
                end
            end
            break
        end
    end

    return give, newChunks
end

Bridge.RegisterCallback('pug-pawnshop:uiData', function(src, shopId)
    shopId = tostring(shopId or '')
    local shop = ShopsById[shopId]
    if not shop then return nil end
    return buildUiPayload(src, shopId)
end)

Bridge.RegisterCallback('pug-pawnshop:sell',
                        function(src, shopId, itemName, amount, mode)
    if onCooldown(src) then
        return {ok = false, message = _L('on_cooldown')}
    end

    shopId = tostring(shopId or '')
    itemName = tostring(itemName or '')
    mode = tostring(mode or 'quick')
    amount = sanitizeAmount(amount)

    local shop = ShopsById[shopId]
    if not shop then return {ok = false, message = _L('notify_invalid')} end
    if not withinDistance(src, shop) then
        return {ok = false, message = _L('notify_too_far')}
    end

    local itemCfg = Config.Items[itemName]
    if not itemCfg then return {ok = false, message = _L('notify_invalid')} end
    if not (ShopCatSets[shopId] and ShopCatSets[shopId][itemCfg.category]) then
        return {ok = false, message = _L('notify_invalid')}
    end

    local st = getState(src)

    local requiredRep = tonumber(itemCfg.requiredRep) or 0
    if (st.rep or 0) < requiredRep then
        return {
            ok = false,
            message = _L('notify_rep_locked', requiredRep),
            ui = buildUiPayload(src, shopId)
        }
    end

    if Config.Heat.enabled and (st.heat or 0) >= Config.Heat.refusalAt then
        if math.random() < 0.18 then
            return {
                ok = false,
                message = _L('notify_heat_refuse'),
                ui = buildUiPayload(src, shopId)
            }
        end
    end

    if amount <= 0 then return {ok = false, message = _L('notify_invalid')} end

    if not Market.CanSell(shopId, itemName) then
        return {
            ok = false,
            message = _L('notify_demand_empty'),
            ui = buildUiPayload(src, shopId)
        }
    end

    local have = Bridge.GetItemCount(src, itemName)
    if have <= 0 then return {ok = false, message = _L('notify_no_item')} end
    if amount > have then amount = have end

    local entry = Market.GetEntry(shopId, itemName)
    local adjusted = false
    if Config.Demand.blockWhenEmpty then
        if (entry.remaining or 0) <= 0 then
            return {
                ok = false,
                message = _L('notify_demand_empty'),
                ui = buildUiPayload(src, shopId)
            }
        end
        if amount > (entry.remaining or 0) then
            amount = entry.remaining or 0
            adjusted = true
        end
    end

    if amount <= 0 then
        return {
            ok = false,
            message = _L('notify_demand_empty'),
            ui = buildUiPayload(src, shopId)
        }
    end

    local extraMult = 1.0
    local modeMsgKey = 'notify_sold'

    if mode == 'negotiate' and Config.Negotiation.enabled then
        local mult, outcome = calcNegotiationMult(st)
        if not mult and outcome == 'refuse' then
            return {
                ok = false,
                message = _L('notify_negotiate_refuse'),
                ui = buildUiPayload(src, shopId)
            }
        end
        extraMult = mult or 1.0
        if outcome == 'bad' then modeMsgKey = 'notify_negotiate_bad' end
        if outcome == 'good' then modeMsgKey = 'notify_negotiate_good' end
    elseif mode == 'appraise' and Config.Appraisal.enabled then
        local mult, outcome = calcAppraiseMult(st)
        extraMult = mult or 1.0
        if outcome == 'backfire' then
            modeMsgKey = 'notify_appraise_backfire'
        end
        if outcome == 'good' then modeMsgKey = 'notify_appraise_good' end
    end

    local unit = Market.QuoteUnit(shopId, itemName, st.rep, st.heat, extraMult)
    local total = Utils.round(unit * amount)
    if total <= 0 then
        return {
            ok = false,
            message = _L('notify_invalid'),
            ui = buildUiPayload(src, shopId)
        }
    end

    local okRemove, removedChunks = Bridge.RemoveItemWithMetadata(src, itemName,
                                                                  amount)
    if not okRemove then
        return {
            ok = false,
            message = _L('notify_no_item'),
            ui = buildUiPayload(src, shopId)
        }
    end

    if not Bridge.AddMoney(src, total) then
        Bridge.AddItemWithChunks(src, itemName,
                                 removedChunks or {{amount = amount}})
        return {
            ok = false,
            message = _L('notify_invalid'),
            ui = buildUiPayload(src, shopId)
        }
    end

    Market.ConsumeDemand(shopId, itemName, amount)

    if Config.Reputation.enabled then
        local gain = (total / Config.Reputation.gainSoldAmount) * Config.Reputation.gainPerSoldValue
        st.rep = Utils.clamp((st.rep or 0) + gain, 0, Config.Reputation.max)
    end

    if Config.Heat.enabled and itemCfg.hot then
        local hp = tonumber(itemCfg.heatPerUnit) or 0
        st.heat =
            Utils.clamp((st.heat or 0) + (hp * amount), 0, Config.Heat.max)
    end

    if Config.Heat.enabled and (st.heat or 0) >= Config.Heat.dispatchAt then
        heatDispatchHook(src, shopId, st.heat)
    end

    if Config.Buyback.enabled then
        local chunks = {}
        if type(removedChunks) == 'table' and #removedChunks > 0 then
            for _, ch in ipairs(removedChunks) do
                chunks[#chunks + 1] = {
                    amount = tonumber(ch.amount) or 0,
                    metadata = copyMeta(ch.metadata)
                }
            end
        else
            chunks = {{amount = amount, metadata = nil}}
        end

        pushBuyback(st.identifier, {
            entryId = Utils.uid('bb'),
            shopId = shopId,
            item = itemName,
            label = itemCfg.label,
            amount = amount,
            chunks = chunks,
            soldUnitPrice = unit,
            soldAt = os.time(),
            expiresAt = os.time() + (Config.Buyback.windowMinutes * 60)
        })
    end

    saveState(src)

    local msg = _L(adjusted and 'notify_sold_adjusted' or 'notify_sold',
                   tostring(amount), Utils.formatMoney(total))
    if mode ~= 'quick' then msg = (msg .. ' ' .. _L(modeMsgKey)) end

    return {ok = true, message = msg, ui = buildUiPayload(src, shopId)}
end)

Bridge.RegisterCallback('pug-pawnshop:buyback', function(src, entryId, amount)
    if onCooldown(src) then
        return {ok = false, message = _L('notify_invalid')}
    end

    entryId = tostring(entryId or '')
    amount = sanitizeAmount(amount)
    if amount <= 0 then return {ok = false, message = _L('notify_invalid')} end

    local st = getState(src)
    local list = Buyback[st.identifier] or {}
    local now = os.time()

    local foundIdx = nil
    local found = nil
    for i, e in ipairs(list) do
        if e.entryId == entryId then
            foundIdx = i
            found = e
            break
        end
    end

    if not found then return {ok = false, message = _L('notify_invalid')} end

    if (found.expiresAt or 0) <= now then
        table.remove(list, foundIdx)
        return {
            ok = false,
            message = _L('notify_buyback_expired'),
            ui = buildUiPayload(src, found.shopId)
        }
    end

    if amount > (found.amount or 0) then amount = found.amount or 0 end
    if amount <= 0 then
        return {
            ok = false,
            message = _L('notify_invalid'),
            ui = buildUiPayload(src, found.shopId)
        }
    end

    local unit = Utils.round((found.soldUnitPrice or 0) *
                                 Config.Buyback.feeMultiplier)
    local total = Utils.round(unit * amount)

    if not Bridge.RemoveMoney(src, total) then
        return {
            ok = false,
            message = _L('notify_invalid'),
            ui = buildUiPayload(src, found.shopId)
        }
    end

    local giveChunks, newChunks = planTakeChunks(found.chunks, amount)
    local tagged = {}
    for _, ch in ipairs(giveChunks) do
        tagged[#tagged + 1] = {
            amount = ch.amount,
            metadata = applyBuybackTag(ch.metadata, {
                shopId = found.shopId,
                soldAt = found.soldAt,
                soldUnitPrice = found.soldUnitPrice
            })
        }
    end

    if not Bridge.AddItemWithChunks(src, found.item, tagged) then
        Bridge.AddMoney(src, total)
        return {
            ok = false,
            message = _L('notify_invalid'),
            ui = buildUiPayload(src, found.shopId)
        }
    end

    found.amount = (found.amount or 0) - amount
    found.chunks = newChunks

    if found.amount <= 0 then table.remove(list, foundIdx) end

    saveState(src)

    local msg = _L('notify_buyback_ok', tostring(amount),
                   Utils.formatMoney(total))
    return {ok = true, message = msg, ui = buildUiPayload(src, found.shopId)}
end)

Bridge.RegisterCallback('pug-pawnshop:contract', function(src, shopId)
    if onCooldown(src) then
        return {ok = false, message = _L('notify_invalid')}
    end

    shopId = tostring(shopId or '')
    local shop = ShopsById[shopId]
    if not shop then return {ok = false, message = _L('notify_invalid')} end
    if not withinDistance(src, shop) then
        return {ok = false, message = _L('notify_too_far')}
    end

    local st = getState(src)
    local contract = Market.Contracts[shopId]
    if not contract then
        return {
            ok = false,
            message = _L('notify_invalid'),
            ui = buildUiPayload(src, shopId)
        }
    end

    if st.contracts and st.contracts[shopId] == contract.id then
        return {
            ok = false,
            message = _L('notify_contract_already'),
            ui = buildUiPayload(src, shopId)
        }
    end

    for _, req in ipairs(contract.requirements or {}) do
        local have = Bridge.GetItemCount(src, req.item)
        if have < (req.amount or 0) then
            return {
                ok = false,
                message = _L('notify_contract_missing'),
                ui = buildUiPayload(src, shopId)
            }
        end
    end

    local subtotal = 0
    for _, req in ipairs(contract.requirements or {}) do
        local unit = Market.QuoteUnit(shopId, req.item, st.rep, st.heat, 1.0)
        subtotal = subtotal + (unit * (req.amount or 0))
    end

    local total = Utils.round((subtotal * (contract.bonusMultiplier or 1.0)) +
                                  (contract.flatBonus or 0))
    if total <= 0 then
        return {
            ok = false,
            message = _L('notify_invalid'),
            ui = buildUiPayload(src, shopId)
        }
    end

    for _, req in ipairs(contract.requirements or {}) do
        if not Bridge.RemoveItem(src, req.item, req.amount or 0) then
            return {
                ok = false,
                message = _L('notify_invalid'),
                ui = buildUiPayload(src, shopId)
            }
        end
        Market.ConsumeDemand(shopId, req.item, req.amount or 0)
    end

    if not Bridge.AddMoney(src, total) then
        return {
            ok = false,
            message = _L('notify_invalid'),
            ui = buildUiPayload(src, shopId)
        }
    end

    if Config.Reputation.enabled then
        st.rep = Utils.clamp((st.rep or 0) + Config.Reputation.gainContract, 0,
                             Config.Reputation.max)
    end

    st.contracts = st.contracts or {}
    st.contracts[shopId] = contract.id
    saveState(src)

    local msg = _L('notify_contract_done', Utils.formatMoney(total))
    return {ok = true, message = msg, ui = buildUiPayload(src, shopId)}
end)

Bridge.RegisterCallback('pug-pawnshop:rumor', function(src, shopId)
    shopId = tostring(shopId or '')
    local shop = ShopsById[shopId]
    if not shop then return nil end

    local st = getState(src)
    local catSet = ShopCatSets[shopId] or {}
    local scored = {}

    for itemName, itemCfg in pairs(Config.Items) do
        if catSet[itemCfg.category] then
            local entry = Market.GetEntry(shopId, itemName)
            if entry and entry.initial > 0 then
                local ratio = Market.GetDemandRatio(shopId, itemName)
                local mult = Market.GetEventMultiplier(itemCfg.category)
                local score = (ratio * 100) + (mult * 10)
                scored[#scored + 1] = {
                    item = itemName,
                    label = itemCfg.label,
                    score = score,
                    cat = itemCfg.category
                }
            end
        end
    end

    table.sort(scored, function(a, b) return a.score > b.score end)

    local out = {}
    for i = 1, math.min(3, #scored) do
        out[#out + 1] = {
            item = scored[i].item,
            label = scored[i].label,
            category = scored[i].cat
        }
    end

    if Config.Heat.enabled and (st.heat or 0) >= Config.Heat.refusalAt and
        #scored >= 6 then
        if math.random() < 0.25 then
            local decoy = scored[#scored]
            out[#out + 1] = {
                item = decoy.item,
                label = decoy.label,
                category = decoy.cat,
                decoy = true
            }
        end
    end

    return {title = _L('rumor_title'), items = out}
end)

CreateThread(function()
    while Config.Heat.enabled do
        Wait((Config.Heat.decayIntervalSeconds or 300) * 1000)
        for src, st in pairs(Players) do
            st.heat = Utils.clamp((st.heat or 0) -
                                      (Config.Heat.decayAmount or 1), 0,
                                  Config.Heat.max)
            saveState(src)
        end
    end
end)

CreateThread(function()
    while Config.Reputation.enabled do
        Wait((Config.Reputation.decayIntervalMinutes or 90) * 60 * 1000)
        for src, st in pairs(Players) do
            st.rep = Utils.clamp((st.rep or 0) -
                                     (Config.Reputation.decayAmount or 1), 0,
                                 Config.Reputation.max)
            saveState(src)
        end
    end
end)

AddEventHandler('onResourceStart', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    Persistence.Init()
    Market.Generate()
    Bridge.Log('Market regenerated (resource start).')
end)
