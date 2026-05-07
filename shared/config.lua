Config = Config or {}

--[[========================================================
    CORE SETTINGS
==========================================================]]

Config.Locale = 'en' -- Language/locale key used by the script

-- Framework mode:
-- 'auto'       = detect automatically
-- 'qb'         = force QBCore
-- 'esx'        = force ESX
-- 'standalone' = no framework support
Config.Framework = 'auto'

-- Inventory mode:
-- 'auto'      = detect automatically
-- 'ox'        = force ox_inventory
-- 'framework' = use framework inventory
Config.Inventory = 'auto'

-- Target mode:
-- 'auto'      = detect automatically
-- 'ox_target' = force ox_target
-- 'qb-target' = force qb-target
-- 'none'      = no target system, manual interaction only
Config.Target = 'auto'

-- Enables debug prints/logging
Config.Debug = false



--[[========================================================
    UI SETTINGS
==========================================================]]
Config.UI = {
    ItemImages = {
        enabled = true,         -- If true, the UI will try to show real item images instead of only icons
        mode = 'auto',          -- 'auto' | 'ox' | 'qb' | 'qs' | 'custom' | 'none'
        customPath = '',        -- Used when mode = 'custom'. Use %s where the item name should be inserted
        fallbackToIcon = true,  -- If the image is missing, fall back to the category icon
    }
}

--[[========================================================
    MONEY SETTINGS
==========================================================]]

Config.Money = {
    -- QBCore money type used when paying the player
    -- Valid QB values: 'cash' or 'bank'
    -- ESX will just use cash unless black money is enabled below
    type = 'cash',

    -- ESX only:
    -- If true, payouts go to black_money instead of normal money
    useBlackMoney = false,
}

--[[========================================================
    PERSISTENCE SETTINGS
    Controls what data is saved between restarts
==========================================================]]
Config.Persistence = {
    enabled = true,               -- Master switch for persistence
    saveReputation = true,        -- Save player reputation
    saveHeat = true,              -- Save player heat
    saveNegotiationStreak = true, -- Save negotiation streaks/related state
    saveContracts = true,         -- Save active contract data
}

--[[========================================================
    SECURITY / ANTI-SPAM SETTINGS
==========================================================]]

Config.Security = {
    maxUseDistance = 3.5,    -- Max distance allowed for secure server-side use
    cooldownMs = 350,        -- General callback/use cooldown in milliseconds
    callbackTimeoutMs = 8000 -- Timeout for UI/server callbacks in milliseconds
}

--[[========================================================
    INTERACTION SETTINGS
==========================================================]]

Config.Interaction = {
    openDistance = 2.0,                  -- Distance required to open the shop
    drawDistance = 15.0,                 -- Distance to show markers/prompts/ped interaction
    keyMappingCommand = 'openpawnshop', -- Command name used for keymapping
    keyMappingDefault = 'E',             -- Default interaction key
}

--[[========================================================
    DEMAND / PRICING SETTINGS
==========================================================]]

Config.Demand = {
    blockWhenEmpty = true,     -- If true, item cannot be sold when demand hits zero
    priceMinMultiplier = 0.55, -- Lowest possible market multiplier
    priceMaxMultiplier = 1.35, -- Highest possible market multiplier
}

--[[========================================================
    REPUTATION SYSTEM
==========================================================]]

Config.Reputation = {
    enabled = true,               -- Enables reputation system
    max = 100,                    -- Max reputation value
    gainSoldAmount = 45,          -- Amount sold required to gain reputation (see gainPer1000Sold)
    gainPerSoldValue = 0.45,      -- Reputation gained per $1000 sold
    gainContract = 4,             -- Reputation gained for completing a contract
    negotiationBonusAtMax = 0.08, -- At max rep, adds +8% baseline negotiation advantage
    decayIntervalMinutes = 90,    -- How often reputation decays
    decayAmount = 1,              -- Amount of rep lost each decay interval
}

--[[========================================================
    HEAT SYSTEM
==========================================================]]

Config.Heat = {
    enabled = true,             -- Enables heat system
    max = 100,                  -- Max heat value
    decayIntervalSeconds = 300, -- How often heat decays
    decayAmount = 1,            -- Amount of heat lost each decay tick
    refusalAt = 85,             -- Pawnshop starts refusing service at this heat level
    dispatchAt = 90,            -- Pawnshop triggers dispatch/police attention at this heat level
}

--[[========================================================
    BUYBACK SYSTEM
==========================================================]]

Config.Buyback = {
    enabled = true,       -- Allows players to buy back recently sold items
    windowMinutes = 25,   -- How long sold items remain available for buyback
    feeMultiplier = 1.15, -- Buyback price multiplier (15% markup)
    maxEntries = 12,      -- Max buyback entries stored per player/shop/session depending on your logic
}

--[[========================================================
    NEGOTIATION SYSTEM
==========================================================]]

Config.Negotiation = {
    enabled = true,                 -- Enables negotiate option
    baseFailChance = 0.22,          -- Base chance negotiation fails
    failChanceReductionAtMaxRep = 0.12, -- At max rep, reduce fail chance by this amount
    failPayoutMultiplier = 0.88,    -- If negotiation fails but still sells, payout becomes 88%
    refuseChance = 0.04,            -- Chance the pawnshop outright refuses the negotiation
    maxBonus = 0.18,                -- Max positive negotiation bonus (+18%)
    minBonus = -0.06,               -- Worst negative negotiation outcome (-6%)
    heatOnAggro = 2,                -- Heat added on aggressive/bad negotiation outcome
}

--[[========================================================
    APPRAISAL SYSTEM
==========================================================]]

Config.Appraisal = {
    enabled = true,            -- Enables appraise option
    durationMs = 6500,         -- Appraisal duration in milliseconds
    baseBonus = 0.03,          -- Minimum appraisal bonus
    maxBonus = 0.22,           -- Maximum appraisal bonus
    backfireChance = 0.08,     -- Chance appraisal backfires
    backfireMultiplier = 0.80, -- If appraisal backfires, payout becomes 80%
    heatOnBackfire = 3,        -- Heat added when appraisal backfires
}

--[[========================================================
    ITEM CATEGORIES
    Used for grouping items in shops, UI, and market events
==========================================================]]

Config.Categories = {
    electronics     = { label = 'Electronics' },
    jewelry         = { label = 'Jewelry' },
    tools           = { label = 'Tools' },
    antiques        = { label = 'Antiques' },
    vehicles        = { label = 'Vehicle Parts' },
    contraband      = { label = 'Contraband' },
    diving          = { label = 'Diving Finds' },
    precious_metals = { label = 'Precious Metals' },
    appliances      = { label = 'Appliances' },
    luxury          = { label = 'Luxury Goods' },
    scrap           = { label = 'Scrap' },
    junk            = { label = 'Junk' },
    materials       = { label = 'Materials' },
}

--[[========================================================
    SHOP LOCATIONS
==========================================================]]

Config.Shops = {
    {
        id = 'city', -- Unique shop ID
        label = 'Downtown Pawn', -- Shop display name
        coords = vector4(411.37, 314.67, 103.13, 206.19), -- Shop location

        ped = {
            model = 'a_m_y_smartcaspat_01',         -- Ped model
            -- scenario = 'WORLD_HUMAN_CLIPBOARD'   -- Idle scenario
        },

        blip = {
            enabled = true, -- Show map blip
            sprite = 434,   -- Blip sprite
            scale = 1.0,    -- Blip size
            color = 28      -- Blip color
        },

        categories = { -- Categories this shop accepts/sells
            'electronics',
            'jewelry',
            'tools',
            'antiques',
            'vehicles',
            'precious_metals',
            'appliances',
            'luxury',
            'scrap',
            'junk',
            'materials'
        },
    },

    {
        id = 'diving',
        label = 'Diving Pawn',
        coords = vector4(-1459.21, -413.60, 35.74, 162.51),

        ped = {
            model = 'a_m_y_smartcaspat_01',
            -- scenario = 'WORLD_HUMAN_CLIPBOARD'
        },

        blip = {
            enabled = true,
            sprite = 434,
            scale = 1.0,
            color = 28
        },

        categories = {
            'diving'
        },
    },

    -- {
    --     id = 'sandy',
    --     label = 'Sandy Pawn & Salvage',
    --     coords = vector4(1697.88, 3756.82, 34.70, 30.0),

    --     ped = {
    --         model = 's_m_m_autoshop_02',
    --         scenario = 'WORLD_HUMAN_SMOKING'
    --     },

    --     blip = {
    --         enabled = true,
    --         sprite = 434,
    --         scale = 1.0,   -- Blip size
    --         color = 28      -- Blip color
    --     },

    --     categories = {
    --         'tools',
    --         'vehicles',
    --         'electronics',
    --         'contraband',
    --         'precious_metals',
    --         'appliances',
    --         'luxury',
    --         'scrap',
    --         'junk',
    --         'materials'
    --     },
    -- },
    -- {
    --     id = 'paleto',
    --     label = 'Paleto Curios Pawn',
    --     coords = vector4(-146.32, 6312.62, 31.56, 315.0),

    --     ped = {
    --         model = 's_m_m_strvend_01',
    --         scenario = 'WORLD_HUMAN_STAND_IMPATIENT'
    --     },

    --     blip = {
    --         enabled = true,
    --         sprite = 434,
    --         scale = 1.0,   -- Blip size
    --         color = 28      -- Blip color
    --     },

    --     categories = {
    --         'antiques',
    --         'jewelry',
    --         'electronics',
    --         'precious_metals',
    --         'luxury'
    --     },
    -- },
}

--[[========================================================
    ITEM DEFINITIONS
    Key = actual item name from your inventory/framework
    Optional per-item fields:
      requiredRep = minimum reputation required before the item can be sold
==========================================================]]

Config.Items = {
    -- Electronics
    bluetooth_speaker = {
        label = 'Bluetooth Speaker',
        category = 'electronics',
        basePrice = 110,
        demand = { min = 25, max = 95 },
        hot = false
    },

    wireless_headphones = {
        label = 'Wireless Headphones',
        category = 'electronics',
        basePrice = 140,
        demand = { min = 20, max = 85 },
        hot = false
    },

    game_console = {
        label = 'Game Console',
        category = 'electronics',
        basePrice = 280,
        demand = { min = 12, max = 55 },
        hot = false,
        requiredRep = 4
    },

    car_stereo = {
        label = 'Car Stereo',
        category = 'vehicles',
        basePrice = 240,
        demand = { min = 16, max = 70 },
        hot = true,
        heatPerUnit = 3,
        requiredRep = 6
    },

    stolen_television = {
        label = 'Flatscreen Television',
        category = 'electronics',
        basePrice = 260,
        demand = { min = 10, max = 40 },
        hot = true,
        heatPerUnit = 4,
        requiredRep = 7
    },

    toaster = {
        label = 'Toaster',
        category = 'appliances',
        basePrice = 45,
        demand = { min = 35, max = 130 },
        hot = false
    },

    microwave = {
        label = 'Microwave',
        category = 'appliances',
        basePrice = 90,
        demand = { min = 20, max = 75 },
        hot = false
    },

    coffee_machine = {
        label = 'Coffee Machine',
        category = 'appliances',
        basePrice = 80,
        demand = { min = 22, max = 90 },
        hot = false
    },

    electric_kettle = {
        label = 'Electric Kettle',
        category = 'appliances',
        basePrice = 55,
        demand = { min = 30, max = 120 },
        hot = false
    },

    standing_fan = {
        label = 'Standing Fan',
        category = 'appliances',
        basePrice = 60,
        demand = { min = 28, max = 100 },
        hot = false
    },

    desk_lamp = {
        label = 'Desk Lamp',
        category = 'appliances',
        basePrice = 40,
        demand = { min = 35, max = 140 },
        hot = false
    },

    gaming_keyboard = {
        label = 'Gaming Keyboard',
        category = 'electronics',
        basePrice = 95,
        demand = { min = 22, max = 85 },
        hot = false
    },

    computer_monitor = {
        label = 'Computer Monitor',
        category = 'electronics',
        basePrice = 160,
        demand = { min = 16, max = 60 },
        hot = false,
        requiredRep = 3
    },

    air_fryer = {
        label = 'Air Fryer',
        category = 'appliances',
        basePrice = 85,
        demand = { min = 24, max = 85 },
        hot = false
    },

    gaming_laptop = {
        label = 'Gaming Laptop',
        category = 'electronics',
        basePrice = 520,
        demand = { min = 8, max = 28 },
        hot = true,
        heatPerUnit = 5,
        requiredRep = 10
    },

    camera_pro = {
        label = 'Professional Camera',
        category = 'electronics',
        basePrice = 380,
        demand = { min = 10, max = 35 },
        hot = false,
        requiredRep = 7
    },

    drone = {
        label = 'Drone',
        category = 'electronics',
        basePrice = 340,
        demand = { min = 9, max = 30 },
        hot = true,
        heatPerUnit = 4,
        requiredRep = 8
    },

    graphics_card = {
        label = 'Graphics Card',
        category = 'electronics',
        basePrice = 420,
        demand = { min = 10, max = 34 },
        hot = true,
        heatPerUnit = 4,
        requiredRep = 9
    },

    vr_headset = {
        label = 'VR Headset',
        category = 'electronics',
        basePrice = 240,
        demand = { min = 12, max = 45 },
        hot = false,
        requiredRep = 5
    },

    broken_tv = {
        label = 'Broken Television',
        category = 'scrap',
        basePrice = 35,
        demand = { min = 20, max = 90 },
        hot = false
    },

    cracked_stereo = {
        label = 'Cracked Stereo',
        category = 'scrap',
        basePrice = 25,
        demand = { min = 25, max = 100 },
        hot = false
    },

    broken_headphones = {
        label = 'Broken Headphones',
        category = 'scrap',
        basePrice = 18,
        demand = { min = 35, max = 120 },
        hot = false
    },

    cracked_glass_panel = {
        label = 'Cracked Glass Panel',
        category = 'scrap',
        basePrice = 20,
        demand = { min = 28, max = 110 },
        hot = false
    },

    damaged_keyboard = {
        label = 'Damaged Keyboard',
        category = 'scrap',
        basePrice = 15,
        demand = { min = 35, max = 130 },
        hot = false
    },

    -- Jewelry / Luxury
    luxury_watch = {
        label = 'Luxury Watch',
        category = 'jewelry',
        basePrice = 900,
        demand = { min = 6, max = 18 },
        hot = true,
        heatPerUnit = 7,
        requiredRep = 12
    },

    designer_handbag = {
        label = 'Designer Handbag',
        category = 'luxury',
        basePrice = 420,
        demand = { min = 8, max = 28 },
        hot = true,
        heatPerUnit = 4,
        requiredRep = 8
    },

    designer_sneakers = {
        label = 'Designer Sneakers',
        category = 'luxury',
        basePrice = 180,
        demand = { min = 16, max = 60 },
        hot = false,
        requiredRep = 4
    },

    fur_coat = {
        label = 'Luxury Fur Coat',
        category = 'luxury',
        basePrice = 340,
        demand = { min = 8, max = 26 },
        hot = true,
        heatPerUnit = 3,
        requiredRep = 7
    },

    designer_sunglasses = {
        label = 'Designer Sunglasses',
        category = 'luxury',
        basePrice = 160,
        demand = { min = 14, max = 55 },
        hot = false,
        requiredRep = 3
    },

    diamond_ring = {
        label = 'Diamond Ring',
        category = 'jewelry',
        basePrice = 650,
        demand = { min = 8, max = 30 },
        hot = true,
        heatPerUnit = 6,
        requiredRep = 10
    },

    diamond_watch = {
        label = 'Diamond Watch',
        category = 'jewelry',
        basePrice = 1050,
        demand = { min = 4, max = 14 },
        hot = true,
        heatPerUnit = 8,
        requiredRep = 14
    },

    ruby_necklace = {
        label = 'Ruby Necklace',
        category = 'jewelry',
        basePrice = 720,
        demand = { min = 6, max = 20 },
        hot = true,
        heatPerUnit = 6,
        requiredRep = 11
    },

    emerald_bracelet = {
        label = 'Emerald Bracelet',
        category = 'jewelry',
        basePrice = 680,
        demand = { min = 6, max = 22 },
        hot = true,
        heatPerUnit = 6,
        requiredRep = 11
    },

    sapphire_earrings = {
        label = 'Sapphire Earrings',
        category = 'jewelry',
        basePrice = 440,
        demand = { min = 8, max = 28 },
        hot = true,
        heatPerUnit = 5,
        requiredRep = 8
    },

    -- Precious metals / high-value goods
    platinum_bar = {
        label = 'Platinum Bar',
        category = 'precious_metals',
        basePrice = 1200,
        demand = { min = 3, max = 10 },
        hot = true,
        heatPerUnit = 9,
        requiredRep = 16
    },

    gold_bar = {
        label = 'Gold Bar',
        category = 'precious_metals',
        basePrice = 950,
        demand = { min = 4, max = 14 },
        hot = true,
        heatPerUnit = 8,
        requiredRep = 14
    },

    gold_scrap = {
        label = 'Gold Scrap',
        category = 'precious_metals',
        basePrice = 260,
        demand = { min = 12, max = 45 },
        hot = false,
        requiredRep = 5
    },

    silver_bar = {
        label = 'Silver Bar',
        category = 'precious_metals',
        basePrice = 620,
        demand = { min = 7, max = 24 },
        hot = false,
        requiredRep = 8
    },

    silver_scrap = {
        label = 'Silver Scrap',
        category = 'precious_metals',
        basePrice = 160,
        demand = { min = 16, max = 65 },
        hot = false,
        requiredRep = 2
    },

    -- Tools / suspicious tools
    stolen_toolbox = {
        label = "Frank's Toolbox",
        category = 'tools',
        basePrice = 150,
        demand = { min = 25, max = 95 },
        hot = true,
        heatPerUnit = 2,
        requiredRep = 3
    },

    -- Vehicle / mechanical junk
    dead_battery = {
        label = 'Dead Battery',
        category = 'vehicles',
        basePrice = 45,
        demand = { min = 25, max = 110 },
        hot = false
    },

    destroyed_tire = {
        label = 'Destroyed Tire',
        category = 'vehicles',
        basePrice = 20,
        demand = { min = 35, max = 130 },
        hot = false
    },

    cracked_tire_rim = {
        label = 'Cracked Tire Rim',
        category = 'vehicles',
        basePrice = 35,
        demand = { min = 28, max = 105 },
        hot = false
    },

    destroyed_tire_wheel = {
        label = 'Destroyed Tire Wheel',
        category = 'vehicles',
        basePrice = 28,
        demand = { min = 30, max = 110 },
        hot = false
    },

    damaged_motor = {
        label = 'Damaged Motor',
        category = 'vehicles',
        basePrice = 110,
        demand = { min = 16, max = 65 },
        hot = false,
        requiredRep = 3
    },

    -- Clothing / random junk
    ripped_shirt = {
        label = 'Ripped Shirt',
        category = 'junk',
        basePrice = 8,
        demand = { min = 40, max = 160 },
        hot = false
    },

    -- Scrap / crafting parts
    metal_rods = {
        label = 'Metal Rods',
        category = 'materials',
        basePrice = 18,
        demand = { min = 35, max = 140 },
        hot = false
    },

    bolts_nuts = {
        label = 'Bolts & Nuts',
        category = 'materials',
        basePrice = 12,
        demand = { min = 45, max = 170 },
        hot = false
    },

    springs = {
        label = 'Springs',
        category = 'materials',
        basePrice = 15,
        demand = { min = 40, max = 150 },
        hot = false
    },

    electronic_component = {
        label = 'Electronic Component',
        category = 'materials',
        basePrice = 45,
        demand = { min = 24, max = 90 },
        hot = false
    },

    circuit_board = {
        label = 'Circuit Board',
        category = 'materials',
        basePrice = 60,
        demand = { min = 20, max = 80 },
        hot = false
    },

    microchip = {
        label = 'Microchip',
        category = 'materials',
        basePrice = 125,
        demand = { min = 14, max = 50 },
        hot = false,
        requiredRep = 4
    },

    thread_spool = {
        label = 'Thread Spool',
        category = 'materials',
        basePrice = 10,
        demand = { min = 45, max = 180 },
        hot = false
    },

    gear = {
        label = 'Gear',
        category = 'materials',
        basePrice = 22,
        demand = { min = 30, max = 120 },
        hot = false
    },

    fan_blade = {
        label = 'Fan Blade',
        category = 'materials',
        basePrice = 18,
        demand = { min = 32, max = 125 },
        hot = false
    },

    battery_cell = {
        label = 'Battery Cell',
        category = 'materials',
        basePrice = 40,
        demand = { min = 24, max = 95 },
        hot = false
    },

    wiring_bundle = {
        label = 'Wiring Bundle',
        category = 'materials',
        basePrice = 16,
        demand = { min = 38, max = 145 },
        hot = false
    },

    -- DIVING FINDS, ANTIQUES, CONTRABAND, AND OTHER CATEGORIES WOULD GO HERE
    ls_old_boot = {
        label = 'Old Boot',
        category = 'diving',
        basePrice = 5,
        demand = { min = 40, max = 160 },
        hot = false
    },

    ls_wood_plank = {
        label = 'Wood Plank',
        category = 'diving',
        basePrice = 5,
        demand = { min = 40, max = 160 },
        hot = false
    },

    ls_rusted_padlock = {
        label = 'Rusted Padlock',
        category = 'diving',
        basePrice = 5,
        demand = { min = 38, max = 150 },
        hot = false
    },

    ls_rusted_key = {
        label = 'Rusted Key',
        category = 'diving',
        basePrice = 5,
        demand = { min = 38, max = 150 },
        hot = false
    },

    ls_rusted_gear = {
        label = 'Rusted Gear',
        category = 'diving',
        basePrice = 5,
        demand = { min = 35, max = 145 },
        hot = false
    },

    ls_seashell = {
        label = 'Seashell',
        category = 'diving',
        basePrice = 15,
        demand = { min = 30, max = 125 },
        hot = false
    },

    ls_seaweed = {
        label = 'Seaweed',
        category = 'diving',
        basePrice = 15,
        demand = { min = 32, max = 130 },
        hot = false
    },

    ls_rusted_muffler = {
        label = 'Rusted Muffler',
        category = 'diving',
        basePrice = 15,
        demand = { min = 28, max = 115 },
        hot = false
    },

    ls_broken_cd = {
        label = 'Broken CD',
        category = 'diving',
        basePrice = 15,
        demand = { min = 30, max = 120 },
        hot = false
    },

    ls_diving_goggles = {
        label = 'Diving Goggles',
        category = 'diving',
        basePrice = 15,
        demand = { min = 24, max = 90 },
        hot = false
    },

    ls_fishing_net = {
        label = 'Fishing Net',
        category = 'diving',
        basePrice = 25,
        demand = { min = 22, max = 85 },
        hot = false
    },

    ls_old_camera = {
        label = 'Old Camera',
        category = 'diving',
        basePrice = 25,
        demand = { min = 20, max = 75 },
        hot = false
    },

    ls_military_helmet = {
        label = 'Military Helmet',
        category = 'diving',
        basePrice = 25,
        demand = { min = 18, max = 65 },
        hot = false
    },

    ls_old_compass = {
        label = 'Old Compass',
        category = 'diving',
        basePrice = 50,
        demand = { min = 14, max = 55 },
        hot = false
    },

    ls_old_watch = {
        label = 'Old Watch',
        category = 'diving',
        basePrice = 50,
        demand = { min = 14, max = 50 },
        hot = false
    },

    ls_conch_shell = {
        label = 'Conch Shell',
        category = 'diving',
        basePrice = 50,
        demand = { min = 12, max = 48 },
        hot = false
    },
}

--[[========================================================
    GLOBAL DEMAND BOOST
    Increases all item demand stock heavily
==========================================================]]

do
    local demandMultiplier = 4

    for _, item in pairs(Config.Items) do
        if item.demand then
            item.demand.min = math.max(1, math.floor((item.demand.min or 1) * demandMultiplier))
            item.demand.max = math.max(item.demand.min, math.floor((item.demand.max or 1) * demandMultiplier))
        end
    end
end

--[[========================================================
    MARKET EVENTS
    Temporary random modifiers affecting category pricing
==========================================================]]

Config.MarketEvents = {
    enabled = true, -- Enables random market events
    countRange = {
        min = 1, -- Minimum number of simultaneous events
        max = 2  -- Maximum number of simultaneous events
    },

    pool = {
        {
            id = 'tech_boom',
            label = 'Tech Boom',
            weight = 35, -- Higher weight = more likely to be chosen
            description = 'Electronics are paying out hot today.',

            categories = {
                electronics = { min = 1.10, max = 1.28 } -- Category price multiplier range
            },
        },

        {
            id = 'jewel_rush',
            label = 'Jewel Rush',
            weight = 25,
            description = 'Jewelry buyers are aggressive right now.',

            categories = {
                jewelry = { min = 1.08, max = 1.25 }
            },
        },

        {
            id = 'scrap_glut',
            label = 'Scrap Glut',
            weight = 20,
            description = 'Auto parts flooded the market; offers are down.',

            categories = {
                vehicles = { min = 0.78, max = 0.92 }
            },
        },

        {
            id = 'curio_fair',
            label = 'Curio Fair',
            weight = 20,
            description = 'Collectors are in town; antiques are up.',

            categories = {
                antiques = { min = 1.10, max = 1.30 }
            },
        },
    },
}

--[[========================================================
    CONTRACT SYSTEM
    Dynamic bundle generation.
    Requirements are generated fresh from Config.Items every restart.
==========================================================]]

Config.Contracts = {
    enabled = true, -- Enables contract system
    perShop = 1,    -- Current UI/server flow expects 1 active contract per shop

    generation = {
        attempts = 40, -- How many times the script tries to build a valid contract before giving up

        itemsPerContract = {
            min = 2, -- Minimum distinct item entries in a contract
            max = 3  -- Maximum distinct item entries in a contract
        },

        -- If true, contract templates may pull multiple categories into one bundle.
        -- If false, generated bundles stay inside a single chosen category.
        mixCategories = false,

        -- If true, items marked as hot can appear in generated contracts.
        includeHotItems = true,

        -- Prevents the same exact item from being selected twice in the same contract.
        uniqueItems = true,

        quantity = {
            -- Generated amount tries to follow the item's configured demand range.
            -- Example: if an item demand max is 100 and demandPercent rolls 0.10,
            -- the raw target amount would be 10 before tier clamps below.
            demandPercent = {
                min = 0.08,
                max = 0.18
            },

            -- Final hard clamps after all calculations.
            absolute = {
                min = 1,
                max = 10
            },

            -- Price-based quantity tuning so cheap items request more and expensive items request less.
            priceTiers = {
                {
                    maxBasePrice = 175,
                    amount = { min = 3, max = 8 }
                },
                {
                    maxBasePrice = 350,
                    amount = { min = 2, max = 6 }
                },
                {
                    maxBasePrice = 700,
                    amount = { min = 1, max = 4 }
                },
                {
                    maxBasePrice = 999999,
                    amount = { min = 1, max = 2 }
                },
            },
        },

        bonusMultiplier = {
            min = 1.10,
            max = 1.26,
            perItemBonus = 0.015,         -- Extra multiplier added per required item entry
            difficultyPriceDivisor = 25000 -- More expensive bundles scale the multiplier a bit higher
        },

        flatBonus = {
            min = 150,
            max = 500,
            perItem = 35,              -- Extra flat bonus per required item entry
            difficultyPriceDivisor = 60 -- More total bundle value increases flat bonus slightly
        },
    },

    templates = {
        {
            id = 'electronics',
            weight = 32,
            categories = { 'electronics' },
            itemCount = { min = 2, max = 3 },
            labels = {
                'Consumer Tech Lot',
                'Clean Electronics Bundle',
                'Office Tech Sweep'
            },
            descriptions = {
                'Buyer wants a stack of working electronics moved together.',
                'Bulk electronics are moving fast. Bring the full lot at once.',
                'A reseller is buying up useful tech in one clean delivery.'
            },
            bonusMultiplier = { min = 1.11, max = 1.22 },
            flatBonus = { min = 175, max = 325 },
        },
        {
            id = 'jewelry',
            weight = 24,
            categories = { 'jewelry', 'antiques' },
            itemCount = { min = 2, max = 3 },
            labels = {
                'Shine & Time Bundle',
                'Collector Value Lot',
                'Premium Pieces Pull'
            },
            descriptions = {
                'Collectors want polished valuables with resale potential.',
                'High-end pieces are moving right now. Complete the bundle for a premium.',
                'Buyer is sourcing valuables with strong shelf appeal.'
            },
            bonusMultiplier = { min = 1.14, max = 1.26 },
            flatBonus = { min = 225, max = 425 },
        },
        {
            id = 'tools',
            weight = 18,
            categories = { 'tools' },
            itemCount = { min = 2, max = 3 },
            labels = {
                'Workshop Restock',
                'Tool Crate Request',
                'Garage Utility Bundle'
            },
            descriptions = {
                'A workshop needs practical gear, not random junk.',
                'Mechanics are paying for a useful stack of tools right now.',
                'Buyer wants a clean utility bundle delivered all together.'
            },
            bonusMultiplier = { min = 1.10, max = 1.20 },
            flatBonus = { min = 150, max = 275 },
        },
        {
            id = 'salvage',
            weight = 18,
            categories = { 'vehicles' },
            itemCount = { min = 2, max = 3 },
            labels = {
                'Salvage Run',
                'Garage Parts Sweep',
                'Auto Scrap Contract'
            },
            descriptions = {
                'A chop garage wants useful parts moved in one run.',
                'Vehicle part demand is up. Bring the exact lot together.',
                'Buyer is paying for a compact but valuable salvage bundle.'
            },
            bonusMultiplier = { min = 1.11, max = 1.23 },
            flatBonus = { min = 175, max = 350 },
        },
        {
            id = 'mixed',
            weight = 8,
            categories = { 'electronics', 'jewelry', 'tools', 'antiques', 'vehicles', 'contraband' },
            itemCount = { min = 2, max = 3 },
            allowMixedCategories = true,
            labels = {
                'Runner Special',
                'Priority Pickup Lot',
                'Mixed Asset Bundle'
            },
            descriptions = {
                'A private buyer wants a mixed lot, but only if it all lands together.',
                'This order is eclectic on purpose. Fill every line item for the payout.',
                'Broker is buying a strange mix today. Complete it in one turn-in.'
            },
            bonusMultiplier = { min = 1.12, max = 1.26 },
            flatBonus = { min = 200, max = 450 },
        },
    },
}