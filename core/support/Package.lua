local Class = require('core/support/Class')
local Module = require('core/support/Module')
local GameSession = require('core/services/GameSession')

---@class Package
---@field modules Module[]
local Package = Class.make()

---@public
function Package.new()
	return Package.instance({ modules = {} })
end

---@protected
---@param module Module
function Package:RegisterModule(module)
	if type(module) ~= 'table' or not Module.is(module) then
		error('Trying to register invalid module.')
	end

	table.insert(self.modules, module)
end

---@public
function Package:Register()
	-- Override this method to register modules and other stuff
end

---@public
function Package:Bootstrap()
	for _, module in ipairs(self.modules) do
		module:OnBootstrap()
	end

	GameSession.OnStart(function()
		for _, module in ipairs(self.modules) do
			module:OnSessionStart()
		end
	end)

	GameSession.OnEnd(function()
		for _, module in ipairs(self.modules) do
			module:OnSessionEnd()
		end
	end)
end

---@public
function Package:Shutdown()
	for _, module in ipairs(self.modules) do
		module:OnShutdown()
	end
end

return Package