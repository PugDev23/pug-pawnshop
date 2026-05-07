Market = Market or {}

Market.State = {}
Market.Events = {}
Market.CategoryMult = {}
Market.Contracts = {}
Market.GeneratedAt = 0

local function shopCategorySet(shop) return Utils.arrayToSet(shop.categories) end

local function pickFromList(list, fallback)
    if type(list) ~= 'table' or #list <= 0 then return fallback end
    return list[math.random(1, #list)]
end

local function randomFloat(min, max)
    min = tonumber(min) or 0
    max = tonumber(max) or min
    if max < min then min, max = max, min end
    if min == max then return min end
    return min + ((max - min) * math.random())
end

local function randomInt(min, max)
    min = tonumber(min) or 0
    max = tonumber(max) or min
    if max < min then min, max = max, min end
    min = math.floor(min)
    max = math.floor(max)
    if min == max then return min end
    return math.random(min, max)
end

local function resolveRangeValue(range, fallbackMin, fallbackMax, asInt)
    local min = fallbackMin
    local max = fallbackMax

    if type(range) == 'table' then
        min = tonumber(range.min) or min
        max = tonumber(range.max) or max
    end

    if asInt then return randomInt(min, max) end
    return randomFloat(min, max)
end

local function getQtyTier(itemCfg)
    local tiers = Config.Contracts.generation.quantity.priceTiers or {}
    local basePrice = tonumber(itemCfg.basePrice) or 0

    for _, tier in ipairs(tiers) do
        if basePrice <= (tonumber(tier.maxBasePrice) or 0) then
            return tier.amount or {}
        end
    end

    return {min = 1, max = 1}
end

local function buildRequirementAmount(itemCfg)
    local generation = Config.Contracts.generation or {}
    local quantityCfg = generation.quantity or {}
    local tier = getQtyTier(itemCfg)

    local demandCfg = itemCfg.demand or {}
    local demandMax = tonumber(demandCfg.max) or tonumber(demandCfg.min) or 1
    local demandPct = resolveRangeValue(quantityCfg.demandPercent, 0.08, 0.18, false)
    local fromDemand = Utils.round(math.max(1, demandMax * demandPct))

    local tierMin = tonumber(tier.min) or 1
    local tierMax = tonumber(tier.max) or tierMin
    local amount = Utils.clamp(fromDemand, tierMin, tierMax)

    local absolute = quantityCfg.absolute or {}
    amount = Utils.clamp(amount, tonumber(absolute.min) or 1,
                         tonumber(absolute.max) or amount)

    return math.max(1, Utils.round(amount))
end

local function gatherContractItems(shop, template)
    local generation = Config.Contracts.generation or {}
    local shopCats = shopCategorySet(shop)
    local templateCats = Utils.arrayToSet(template.categories or {})
    local allowMixed = template.allowMixedCategories == true or
                           generation.mixCategories == true
    local includeHot = generation.includeHotItems ~= false

    local allowedCategories = {}
    for _, cat in ipairs(template.categories or {}) do
        if shopCats[cat] then allowedCategories[#allowedCategories + 1] = cat end
    end

    if #allowedCategories <= 0 then return {}, nil end

    local chosenCategory = nil
    if not allowMixed then
        chosenCategory = allowedCategories[math.random(1, #allowedCategories)]
    end

    local items = {}
    for itemName, itemCfg in pairs(Config.Items) do
        if shopCats[itemCfg.category] and templateCats[itemCfg.category] then
            if includeHot or not itemCfg.hot then
                if allowMixed or itemCfg.category == chosenCategory then
                    items[#items + 1] = {
                        name = itemName,
                        cfg = itemCfg
                    }
                end
            end
        end
    end

    return items, chosenCategory
end

local function buildContractRequirements(shop, template)
    local generation = Config.Contracts.generation or {}
    local candidates = gatherContractItems(shop, template)
    if #candidates <= 0 then return nil end

    local itemCount = resolveRangeValue(template.itemCount or generation.itemsPerContract,
                                        2, 3, true)
    itemCount = Utils.clamp(itemCount, 1, #candidates)

    local requirements = {}
    local used = {}
    local subtotalBase = 0

    for _ = 1, itemCount do
        local pool = {}
        for _, entry in ipairs(candidates) do
            if generation.uniqueItems == false or not used[entry.name] then
                pool[#pool + 1] = entry
            end
        end

        if #pool <= 0 then break end

        local picked = pool[math.random(1, #pool)]
        local amount = buildRequirementAmount(picked.cfg)
        requirements[#requirements + 1] = {
            item = picked.name,
            amount = amount
        }
        used[picked.name] = true
        subtotalBase = subtotalBase + ((tonumber(picked.cfg.basePrice) or 0) * amount)
    end

    if #requirements <= 0 then return nil end
    return requirements, subtotalBase
end

local function buildContractPayout(template, requirementCount, subtotalBase)
    local generation = Config.Contracts.generation or {}

    local multCfg = template.bonusMultiplier or generation.bonusMultiplier or {}
    local multiplier = resolveRangeValue(multCfg, 1.10, 1.20, false)
    multiplier = multiplier + ((tonumber(multCfg.perItemBonus) or tonumber(generation.bonusMultiplier and generation.bonusMultiplier.perItemBonus) or 0) * requirementCount)

    local multDivisor = tonumber(multCfg.difficultyPriceDivisor) or
                            tonumber(generation.bonusMultiplier and generation.bonusMultiplier.difficultyPriceDivisor) or 0
    if multDivisor > 0 then multiplier = multiplier + (subtotalBase / multDivisor) end
    multiplier = Utils.round(multiplier * 100) / 100

    local flatCfg = template.flatBonus or generation.flatBonus or {}
    local flatBonus = resolveRangeValue(flatCfg, 150, 300, true)
    flatBonus = flatBonus + ((tonumber(flatCfg.perItem) or tonumber(generation.flatBonus and generation.flatBonus.perItem) or 0) * requirementCount)

    local flatDivisor = tonumber(flatCfg.difficultyPriceDivisor) or
                            tonumber(generation.flatBonus and generation.flatBonus.difficultyPriceDivisor) or 0
    if flatDivisor > 0 then flatBonus = flatBonus + Utils.round(subtotalBase / flatDivisor) end

    return math.max(1.01, multiplier), math.max(0, Utils.round(flatBonus))
end

local function buildDynamicContract(shop, template)
    local requirements, subtotalBase = buildContractRequirements(shop, template)
    if not requirements or #requirements <= 0 then return nil end

    local bonusMultiplier, flatBonus = buildContractPayout(template, #requirements,
                                                           subtotalBase or 0)

    return {
        id = Utils.uid('contract_' .. (template.id or shop.id or 'shop')),
        templateId = template.id,
        label = pickFromList(template.labels, 'Special Delivery Contract'),
        description = pickFromList(template.descriptions,
                                   'Bring the requested bundle together for a bonus payout.'),
        requirements = requirements,
        bonusMultiplier = bonusMultiplier,
        flatBonus = flatBonus
    }
end

local function pickMarketEvents()
    Market.Events = {}
    Market.CategoryMult = {}
    for cat in pairs(Config.Categories) do Market.CategoryMult[cat] = 1.0 end

    if not Config.MarketEvents.enabled then return end
    local minCount = Config.MarketEvents.countRange.min or 0
    local maxCount = Config.MarketEvents.countRange.max or 0
    local count = math.random(minCount, maxCount)

    local pool = {}
    for _, e in ipairs(Config.MarketEvents.pool or {}) do pool[#pool + 1] = e end

    for _ = 1, count do
        if #pool == 0 then break end
        local picked = Utils.weightedPick(pool, 'weight')
        if not picked then break end

        local chosen = {
            id = picked.id,
            label = picked.label,
            description = picked.description,
            applied = {}
        }

        if picked.categories then
            for cat, range in pairs(picked.categories) do
                local mn = tonumber(range.min) or 1.0
                local mx = tonumber(range.max) or mn
                local mult = Utils.lerp(mn, mx, math.random())
                Market.CategoryMult[cat] =
                    (Market.CategoryMult[cat] or 1.0) * mult
                chosen.applied[cat] = mult
            end
        end

        Market.Events[#Market.Events + 1] = chosen

        for i = #pool, 1, -1 do
            if pool[i].id == picked.id then table.remove(pool, i) end
        end
    end
end

local function pickContractForShop(shop)
    if not Config.Contracts.enabled then return nil end

    local templates = Config.Contracts.templates or {}
    if #templates <= 0 then return nil end

    local attempts = tonumber(Config.Contracts.generation and
                                  Config.Contracts.generation.attempts) or 20

    for _ = 1, attempts do
        local template = Utils.weightedPick(templates, 'weight')
        if not template then return nil end

        local contract = buildDynamicContract(shop, template)
        if contract then return contract end
    end

    return nil
end

function Market.Generate()
    Utils.reseed()
    Market.State = {}
    Market.Contracts = {}
    Market.GeneratedAt = os.time()

    pickMarketEvents()

    for _, shop in ipairs(Config.Shops) do
        local catSet = shopCategorySet(shop)
        Market.State[shop.id] = {}

        for itemName, itemCfg in pairs(Config.Items) do
            if catSet[itemCfg.category] then
                local mn = tonumber(itemCfg.demand and itemCfg.demand.min) or 0
                local mx = tonumber(itemCfg.demand and itemCfg.demand.max) or mn
                local initial = math.random(mn, mx)
                Market.State[shop.id][itemName] = {
                    initial = initial,
                    remaining = initial
                }
            end
        end

        Market.Contracts[shop.id] = pickContractForShop(shop)
    end
end

function Market.GetEntry(shopId, itemName)
    return Market.State[shopId] and Market.State[shopId][itemName] or nil
end

function Market.GetDemandRatio(shopId, itemName)
    local e = Market.GetEntry(shopId, itemName)
    if not e or e.initial <= 0 then return 0 end
    return Utils.clamp(e.remaining / e.initial, 0, 1)
end

function Market.GetDemandMultiplier(shopId, itemName)
    local ratio = Market.GetDemandRatio(shopId, itemName)
    return Utils.lerp(Config.Demand.priceMinMultiplier,
                      Config.Demand.priceMaxMultiplier, ratio)
end

function Market.GetEventMultiplier(category)
    return Market.CategoryMult[category] or 1.0
end

function Market.ConsumeDemand(shopId, itemName, amount)
    local e = Market.GetEntry(shopId, itemName)
    if not e then return end
    e.remaining = math.max(0, (e.remaining or 0) - (tonumber(amount) or 0))
end

function Market.QuoteUnit(shopId, itemName, rep, heat, extraMult)
    local itemCfg = Config.Items[itemName]
    if not itemCfg then return 0 end

    local demandMult = Market.GetDemandMultiplier(shopId, itemName)
    local eventMult = Market.GetEventMultiplier(itemCfg.category)

    local repMult = 1.0
    if Config.Reputation.enabled then
        local t =
            Utils.clamp((tonumber(rep) or 0) / Config.Reputation.max, 0, 1)
        repMult = 1.0 + (Config.Reputation.negotiationBonusAtMax * t)
    end

    local heatMult = 1.0
    if Config.Heat.enabled then
        local h = Utils.clamp((tonumber(heat) or 0) / Config.Heat.max, 0, 1)
        heatMult = Utils.lerp(1.0, 0.88, h)
    end

    extraMult = tonumber(extraMult) or 1.0

    local price = (itemCfg.basePrice or 0) * demandMult * eventMult * repMult *
                      heatMult * extraMult
    return math.max(0, Utils.round(price))
end

function Market.CanSell(shopId, itemName)
    local e = Market.GetEntry(shopId, itemName)
    if not e then return false end
    if Config.Demand.blockWhenEmpty and (e.remaining or 0) <= 0 then
        return false
    end
    return true
end
