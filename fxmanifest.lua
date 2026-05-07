fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Pug Development'
description 'pug-pawnshop '
version '1.0.0'

ui_page 'web/index.html'

files {'web/index.html', 'web/app.js', 'web/style.css'}

shared_scripts {'shared/config.lua', 'shared/lang.lua', 'shared/utils.lua'}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/bridge.lua', 'server/persistence.lua', 'server/market.lua',
    'server/main.lua'
}

client_scripts {'client/bridge.lua', 'client/main.lua', 'client/targets.lua'}
