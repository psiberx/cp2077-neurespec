--[[
NeureSpec
- Respec attributes, perks and skills
- Integrates into the Hub menu
- Multi-language support

Copyright (c) 2021 psiberx
]]--

loadfile('core/meta') {
	mod = 'NeureSpec',
	version = '1.1.0',
	framework = '1.20.0'
}

local Cron = require('core/services/Cron')
local GameLocale = require('core/services/GameLocale')

local PackageManager = require('core/services/PackageManager')
PackageManager.RegisterFromType(require('game/GamePackage'))

registerForEvent('onInit', function()
	GameLocale.Initialize()
	PackageManager.Bootstrap()
end)

registerForEvent('onShutdown', function()
	PackageManager.Shutdown()
end)

registerForEvent('onUpdate', function(delta)
	Cron.Update(delta)
end)
