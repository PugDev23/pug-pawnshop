Persistence = Persistence or {}

local DEFAULT_STATE = {
    rep = 0,
    heat = 0,
    streak = 0,
    contracts = {},
    buyback = {}
}

local TABLE_NAME = 'pug_pawnshop_players'
local _ready = false

local function normalizeState(data)
    if type(data) ~= 'table' then
        data = {}
    end

    return {
        rep = tonumber(data.rep) or 0,
        heat = tonumber(data.heat) or 0,
        streak = tonumber(data.streak) or 0,
        contracts = type(data.contracts) == 'table' and data.contracts or {},
        buyback = type(data.buyback) == 'table' and data.buyback or {},
    }
end

local function ensureDb()
    if _ready then return true end

    if not MySQL or not MySQL.query or not MySQL.query.await then
        print('^1[pug-pawnshop]^0 oxmysql is required for database persistence.')
        return false
    end

    local ok, err = pcall(function()
        MySQL.query.await(([[
            CREATE TABLE IF NOT EXISTS `%s` (
                `identifier` VARCHAR(64) NOT NULL,
                `state_json` LONGTEXT NULL,
                `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                PRIMARY KEY (`identifier`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        ]]):format(TABLE_NAME))
    end)

    if not ok then
        print(('^1[pug-pawnshop]^0 Failed creating persistence table: %s'):format(tostring(err)))
        return false
    end

    _ready = true
    return true
end

function Persistence.Init()
    return ensureDb()
end

function Persistence.Load(identifier)
    if not Config.Persistence.enabled then
        return normalizeState(DEFAULT_STATE)
    end

    if not identifier or identifier == '' then
        return normalizeState(DEFAULT_STATE)
    end

    if not ensureDb() then
        return normalizeState(DEFAULT_STATE)
    end

    local ok, row = pcall(function()
        return MySQL.single.await(([[
            SELECT `state_json`
            FROM `%s`
            WHERE `identifier` = ?
            LIMIT 1
        ]]):format(TABLE_NAME), { identifier })
    end)

    if not ok or not row or not row.state_json or row.state_json == '' then
        return normalizeState(DEFAULT_STATE)
    end

    local decodeOk, data = pcall(function()
        return json.decode(row.state_json)
    end)
    if not decodeOk then
        return normalizeState(DEFAULT_STATE)
    end

    return normalizeState(data)
end

function Persistence.Save(identifier, state)
    if not Config.Persistence.enabled then return true end
    if not identifier or identifier == '' then return false end
    if not ensureDb() then return false end

    local payload = {
        rep = Config.Persistence.saveReputation and (tonumber(state.rep) or 0) or 0,
        heat = Config.Persistence.saveHeat and (tonumber(state.heat) or 0) or 0,
        streak = Config.Persistence.saveNegotiationStreak and (tonumber(state.streak) or 0) or 0,
        contracts = Config.Persistence.saveContracts and (state.contracts or {}) or {},
        buyback = Config.Buyback and Config.Buyback.enabled and (state.buyback or {}) or {},
    }

    local ok, err = pcall(function()
        MySQL.insert.await(([[
            INSERT INTO `%s` (`identifier`, `state_json`)
            VALUES (?, ?)
            ON DUPLICATE KEY UPDATE `state_json` = VALUES(`state_json`)
        ]]):format(TABLE_NAME), { identifier, json.encode(payload) })
    end)

    if not ok then
        print(('^1[pug-pawnshop]^0 Failed saving persistence for %s: %s'):format(identifier, tostring(err)))
        return false
    end

    return true
end
