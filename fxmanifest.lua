
fx_version "cerulean"
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
games {"rdr3"}

author 'Phil and Mack'
description 'philsnpc coaches'
version '1.0.0'


client_scripts {
    'client.lua'
}
server_scripts {
    'server.lua'
}
shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

dependencies {
    'rsg-core',
    'ox_lib'
}

lua54 'yes'