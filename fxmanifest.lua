fx_version 'cerulean'
game 'gta5'

name 'Pulsar Tow'
description 'Tow job'
author 'Artmines - maintained for Pulsar Framework'
url 'https://pulsarframe.work'
version 'v1.0.1'

version_check 'yes'
github 'https://github.com/PulsarFW/pulsar_tow'

client_script '@pulsar_core/components/cl_error.lua'
shared_script '@pulsar_core/core/sh_pulsar.lua'
client_script '@pulsar_pwnzor/client/check.lua'

files({
	'config/shared.lua',
})

client_scripts({
	'client/**/*.lua',
})

server_scripts({
	'server/**/*.lua',
})
