local Module = require('core/support/Module')
local Cron = require('core/services/Cron')
local GameLocale = require('core/services/GameLocale')
local PlayerDevData = require('game/systems/PlayerDevData')

---@class CharacterPerksMenu : Module
---@field upgradePerkAction CName
---@field revokePerkAction CName
local CharacterPerksMenu = Module.extend()

---@protected
function CharacterPerksMenu:Initialize()
	self.upgradePerkAction = CName.new('upgrade_perk')
	self.revokePerkAction = CName.new('disassemble_item')
end

---@public
function CharacterPerksMenu:OnBootstrap()
	---@param controller PerksMainGameController
	---@param perkData BasePerkDisplayData
  	Override('PerksMainGameController', 'SetPerksButtonHintHoverOver', function(controller, perkData)
		if perkData then
			self:SetPerkButtonHints(controller, perkData)
		end
	end)

	---@param controller PerksMainGameController
	Observe('PerksMainGameController', 'SetPerksButtonHintHoverOut', function(controller)
		self:ResetPerkButtonHints(controller)
	end)

	---@param perkController PerkDisplayController
	---@param event inkPointerEvent
	Observe('PerkDisplayController', 'OnPerkDisplayHold', function(perkController, event)
		local playerData = PlayerDevData.resolve()
		local perkData = perkController.displayData

		if event:IsAction(self.revokePerkAction) and playerData:CanRevokePerk(perkData.level) then
			local progress = event:GetHoldProgress()

			if not perkController.holdStarted and progress >= 0 then
				perkController.holdStarted = true
			elseif perkController.holdStarted and progress >= 1 then
				if perkController.isTrait then
					playerData:RevokeTrait(perkData.type)
				else
					playerData:RevokePerk(perkData.type)
				end

				perkController.recentlyPurchased = true
				self:UpdateDisplayData(perkController)

				perkController:PlaySound('Item', 'OnCraftFailed')
				perkController:PlayLibraryAnimation('buy_perk')
			end
		end
	end)

	---@param perkController PerkDisplayController
	---@param perkData BasePerkDisplayData
	Observe('PerkDisplayController', 'Setup', function(perkController, perkData)
		if perkController.recentlyPurchased then
			if perkData then
				-- Nested RTTI call workaround
				Cron.NextTick(function()
					self:SetPerkButtonHints(perkController.dataManager.parentGameCtrl, perkData)
				end)
			end

			perkController.recentlyPurchased = false
		end
	end)
end

---@protected
---@param mainController PerksMainGameController
---@param perkData BasePerkDisplayData
function CharacterPerksMenu:SetPerkButtonHints(mainController, perkData)
	local playerData = PlayerDevData.resolve()

	if playerData:CanRevokePerk(perkData.level) then
		mainController.buttonHintsController:AddButtonHint(self.revokePerkAction, GameLocale.ActionHold('LocKey#17848'))
	else
		mainController.buttonHintsController:RemoveButtonHint(self.revokePerkAction)
	end

	if mainController.dataManager:IsPerkUpgradeable(perkData) then
		mainController.buttonHintsController:AddButtonHint(self.upgradePerkAction, GameLocale.ActionHold('UI-ScriptExports-Buy0'))
	else
		mainController.buttonHintsController:RemoveButtonHint(self.upgradePerkAction)
	end

	local cursorData = MenuCursorUserData.new()
	cursorData:AddAction(self.upgradePerkAction)
	cursorData:AddAction(self.revokePerkAction)
	cursorData:SetAnimationOverride('hoverOnHoldToComplete')

	mainController:SetCursorContext('Hover', cursorData)
end

---@protected
---@param mainController PerksMainGameController
function CharacterPerksMenu:ResetPerkButtonHints(mainController)
	mainController.buttonHintsController:RemoveButtonHint(self.revokePerkAction)
end

---@protected
---@param perkController PerkDisplayController
function CharacterPerksMenu:UpdateDisplayData(perkController)
	---@type PerksMainGameController
	local mainController = perkController.dataManager.parentGameCtrl
	local perkData = perkController.displayData

	if perkController.isTrait then
		mainController.perksScreenController:OnTraitBoughtEvent(
			TraitBoughtEvent.new({ traitType = perkData.type })
		)
	else
		mainController.perksScreenController:OnPerkBoughtEvent(
			PerkBoughtEvent.new({ perkType = perkData.type })
		)
	end

	perkController.dataManager:UpdateData()
end

return CharacterPerksMenu