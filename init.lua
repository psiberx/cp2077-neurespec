--[[
NeureSpec
- Respec attributes, perks and skills
- Integrates into the Hub menu
- Multi-language support

Copyright (c) 2023 psiberx
]]--

loadfile('core/meta') {
	mod = 'NeureSpec',
	version = '1.2.0',
	framework = '1.26.0'
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
