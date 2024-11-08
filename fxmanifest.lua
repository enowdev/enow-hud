fx_version 'cerulean'
game 'gta5'

description 'Enow HUD'
version '1.0.0'

lua54 'yes'
use_fxv2_oal 'yes'

shared_script 'config.lua'
client_script 'client/main.lua'
server_script 'server/main.lua'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}