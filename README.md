# pug-pawnshop

Advanced pawnshop with a living market:
- Dynamic **per-restart demand** per item + shop (demand burns down as people sell).
- Per-restart **market events** that multiply category payouts.
- **Reputation** (better baseline offers) + **Heat** (hot goods pressure/refusal).
- **Quick / Negotiate / Appraise** sell modes.
- **Buyback** window (reclaim recently pawned goods for a fee).
- Per-restart **contracts** (bundle deliveries for bonus).
- **Rumors** (ask the broker what’s paying best; heat can distort truth).

## Install
1) Drop the folder as `pug-pawnshop`
2) Ensure in server.cfg:
   - `ensure pug-pawnshop`
3) Configure items/shops in `shared/config.lua`.

## Framework Support
- QBCore
- QBOX
- ESX

## Hooks
### Heat dispatch hook
You can listen for:
- `pug-pawnshop:server:heatDispatch (src, shopId, heat)`
to integrate with any dispatch/police script.
