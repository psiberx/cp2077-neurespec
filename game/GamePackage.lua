local Package = require('core/support/Package')
local CharacterMainMenu = require('game/ui/hub/CharacterMainMenu')
local CharacterPerksMenu = require('game/ui/hub/CharacterPerksMenu')
local CharacterResetPanel = require('game/ui/hub/CharacterResetPanel')
local CharacterSkillsPanel = require('game/ui/hub/CharacterSkillsPanel')

---@class GamePackage : Package
local GamePackage = Package.extend()

---@public
function GamePackage:Register()
	self:RegisterModule(CharacterMainMenu.new())
	self:RegisterModule(CharacterPerksMenu.new())
	self:RegisterModule(CharacterResetPanel.new())
	self:RegisterModule(CharacterSkillsPanel.new())
end

return GamePackage