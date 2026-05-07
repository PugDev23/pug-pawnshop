Lang = Lang or {}

Lang.en = {
    ui_title = 'Pawnshop',
    ui_sell = 'Sell',
    ui_buyback = 'Buyback',
    ui_contract = 'Contract',
    ui_market = 'Market',

    help_open = 'Press ~INPUT_CONTEXT~ to talk to the broker',
    notify_too_far = 'You are too far from the counter.',
    notify_invalid = 'Invalid request.',
    notify_timeout = 'Request timed out.',
    notify_no_item = 'You do not have enough of that item.',
    notify_demand_empty = 'They are not buying that right now.',
    notify_rep_locked = 'You need %s reputation to sell that item.',
    notify_heat_refuse = 'The broker refuses to deal with you right now.',
    notify_sold = 'Sold x%s for $%s.',
    notify_sold_adjusted = 'Sold x%s (limited) for $%s.',
    notify_buyback_expired = 'That buyback offer expired.',
    notify_buyback_ok = 'Bought back x%s for $%s.',
    notify_contract_done = 'Contract completed for $%s.',
    notify_contract_already = 'You already completed this contract.',
    notify_contract_missing = 'You do not have the required items.',
    notify_negotiate_refuse = 'Negotiation failed. They won’t buy it right now.',
    notify_negotiate_bad = 'Negotiation went poorly. Reduced payout.',
    notify_negotiate_good = 'Negotiation success. Increased payout.',
    notify_appraise_backfire = 'Appraisal backfired. Lower payout.',
    notify_appraise_good = 'Appraisal found value. Increased payout.',
    rumor_title = 'Market Rumor',
    on_cooldown = 'The broker is not ready to deal with you yet.',
}

function _L(key, ...)
    local locale = (Config and Config.Locale) or 'en'
    local t = (Lang[locale] and Lang[locale][key]) or (Lang.en and Lang.en[key]) or key
    if select('#', ...) > 0 then
        return string.format(t, ...)
    end
    return t
end
