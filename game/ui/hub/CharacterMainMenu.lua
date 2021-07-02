local Module = require('core/support/Module')
local Cron = require('core/services/Cron')
local GameLocale = require('core/services/GameLocale')
local PlayerDevData = require('game/systems/PlayerDevData')

---@class CharacterMainMenu : Module
---@field upgradeAttributeAction CName
---@field revokeAttributeAction CName
---@field animCallbackProxy TargetHitIndicatorGameController
---@field animCallbackTargets table
local CharacterMainMenu = Module.extend()

---@protected
function CharacterMainMenu:Initialize()
	self.upgradeAttributeAction = CName.new('upgrade_perk')
	self.revokeAttributeAction = CName.new('disassemble_item')

	self.animCallbackProxy = TargetHitIndicatorGameController.new()
	self.animCallbackTargets = {}
end

---@public
function CharacterMainMenu:OnBootstrap()
	---@param mainController PerksMenuAttributeItemController
	---@param attributeData AttributeData
  	Override('PerksMainGameController', 'SetAttributeBuyButtonHintHoverOver', function(mainController, attributeData)
		if attributeData then
			self:SetAttributeButtonHints(mainController, attributeData)
		end
	end)

	---@param mainController PerksMenuAttributeItemController
	Observe('PerksMainGameController', 'SetAttributeBuyButtonHintHoverOut', function(mainController)
		self:ResetAttributeButtonHints(mainController)
	end)

	---@param attributeController PerksMenuAttributeItemController
	---@param event inkPointerEvent
	Observe('PerksMenuAttributeItemController', 'OnAttributeItemHold', function(attributeController, event)
		local playerData = PlayerDevData.resolve()
		local attributeData = attributeController.attributeDisplayController.attributeData

		if event:IsAction(self.revokeAttributeAction) and attributeData and playerData:CanRevokeAttribute(attributeData.value) then
			local progress = event:GetHoldProgress()

			if attributeController.holdStarted and progress >= 1 then
				playerData:RevokeAttribute(attributeData.type)

				self:UpdateDisplayData(attributeController)

				local animOptions = inkanimPlaybackOptions.new()
				animOptions.playReversed = true

				local animProxy = attributeController.attributeDisplayController:PlayLibraryAnimation('buy_attribute', animOptions)
				animProxy:RegisterToCallback(inkanimEventType.OnFinish, self.animCallbackProxy, 'OnAnimFinished')

				table.insert(self.animCallbackTargets, attributeController)

				attributeController:PlaySound('Item', 'OnCraftFailed')
			end
		end
	end)

	---@param attributeDisplayController PerksMenuAttributeDisplayController
	Observe('PerksMenuAttributeDisplayController', 'Update', function(attributeDisplayController)
		-- Nested RTTI call workaround
		Cron.NextTick(function()
			if attributeDisplayController.attributeData and self:IsAttributeHovered(attributeDisplayController) then
				self:SetAttributeButtonHints(attributeDisplayController.dataManager.parentGameCtrl, attributeDisplayController.attributeData)
			end
		end)
	end)

	---@param proxyController TargetHitIndicatorGameController
	Observe('TargetHitIndicatorGameController', 'OnAnimFinished', function(proxyController)
		if not proxyController.rootWidget and #self.animCallbackTargets > 0 then
			if self.animCallbackTargets[#self.animCallbackTargets]:IsA('PerksMenuAttributeItemController') then
				local attributeItemController = table.remove(self.animCallbackTargets)
				local attributeDisplayController = attributeItemController.attributeDisplayController

				attributeDisplayController:PlayLibraryAnimation('buy_attribute'):GotoEndAndStop(true)
				attributeDisplayController:ResetHoverOpacity()

				if self:IsAttributeHovered(attributeDisplayController) then
					attributeDisplayController:SetHovered(true)
				end
			end
		end
	end)
end

---@protected
---@param attributeDisplayController PerksMenuAttributeDisplayController
function CharacterMainMenu:IsAttributeHovered(attributeDisplayController)
	return inkWidgetRef.GetState(attributeDisplayController.widgetWrapper).value == 'Hovered'
end

---@protected
---@param mainController PerksMainGameController
---@param attributeData AttributeData
function CharacterMainMenu:SetAttributeButtonHints(mainController, attributeData)
	local playerData = PlayerDevData.resolve()

	if playerData:CanRevokeAttribute(attributeData.value) then
		mainController.buttonHintsController:AddButtonHint(self.revokeAttributeAction, GameLocale.ActionHold('LocKey#17848'))
	else
		mainController.buttonHintsController:RemoveButtonHint(self.revokeAttributeAction)
	end

	if attributeData.availableToUpgrade and mainController.dataManager:HasAvailableAttributePoints() then
		mainController.buttonHintsController:AddButtonHint(self.upgradeAttributeAction, GameLocale.ActionHold('UI-ScriptExports-Buy0'))
	else
		mainController.buttonHintsController:RemoveButtonHint(self.upgradeAttributeAction)
	end

	local cursorData = MenuCursorUserData.new()
	cursorData:AddAction(self.upgradeAttributeAction)
	cursorData:AddAction(self.revokeAttributeAction)
	cursorData:SetAnimationOverride('hoverOnHoldToComplete')

	mainController:SetCursorContext('Hover', cursorData)
end

---@protected
---@param mainController PerksMainGameController
function CharacterMainMenu:ResetAttributeButtonHints(mainController)
	mainController.buttonHintsController:RemoveButtonHint(self.revokeAttributeAction)
end

---@protected
---@param attributeController PerksMenuAttributeItemController
function CharacterMainMenu:UpdateDisplayData(attributeController)
	attributeController.dataManager:UpdateData()
	attributeController:Setup(attributeController.dataManager)
end

return CharacterMainMenu