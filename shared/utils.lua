Utils = Utils or {}

function Utils.clamp(n, min, max)
    if n < min then return min end
    if n > max then return max end
    return n
end

function Utils.round(n) return math.floor(n + 0.5) end

function Utils.lerp(a, b, t) return a + (b - a) * t end

function Utils.formatMoney(n)
    n = tonumber(n) or 0
    local s = tostring(Utils.round(n))
    local formatted = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
    formatted = formatted:gsub("^,", "")
    return formatted
end

function Utils.reseed()
    local t = tostring(os.time()):reverse():sub(1, 6)
    local seed = tonumber(t) or os.time()
    math.randomseed(seed + (GetGameTimer() or 0))
    math.random();
    math.random();
    math.random()
end

function Utils.uid(prefix)
    prefix = prefix or 'id'
    local r1 = math.random(100000, 999999)
    local r2 = math.random(100000, 999999)
    return string.format('%s_%s_%s', prefix, r1, r2)
end

function Utils.weightedPick(pool, weightKey)
    weightKey = weightKey or 'weight'
    local total = 0
    for _, v in ipairs(pool) do total = total + (tonumber(v[weightKey]) or 0) end
    if total <= 0 then return nil end
    local roll = math.random() * total
    local upto = 0
    for _, v in ipairs(pool) do
        upto = upto + (tonumber(v[weightKey]) or 0)
        if upto >= roll then return v end
    end
    return pool[#pool]
end

function Utils.arrayToSet(arr)
    local set = {}
    for _, v in ipairs(arr or {}) do set[v] = true end
    return set
end
