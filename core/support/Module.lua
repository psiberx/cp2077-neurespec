local Class = require('core/support/Class')

---@class Module
local Module = Class.make()

---@public
function Module:OnBootstrap() end

---@public
function Module:OnSessionStart() end

---@public
function Module:OnSessionEnd() end

---@public
function Module:OnShutdown() end

return Module