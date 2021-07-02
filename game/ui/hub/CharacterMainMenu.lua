local Module = require('core/support/Module')
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
	---@param controller PerksMenuAttributeItemController
	---@param attributeData AttributeData
  	Override('PerksMainGameController', 'SetAttributeBuyButtonHintHoverOver', function(controller, attributeData)
		if attributeData then
			self:SetAttributeButtonHints(controller, attributeData)
		end
	end)

	---@param controller PerksMenuAttributeItemController
	Observe('PerksMainGameController', 'SetAttributeBuyButtonHintHoverOut', function(controller)
		self:ResetAttributeButtonHints(controller)
	end)

	---@param controller PerksMenuAttributeItemController
	---@param event inkPointerEvent
	Observe('PerksMenuAttributeItemController', 'OnAttributeItemHold', function(controller, event)
		local playerData = PlayerDevData.resolve()
		local attributeData = controller.attributeDisplayController.attributeData

		if event:IsAction(self.revokeAttributeAction) and attributeData and playerData:CanRevokeAttribute(attributeData.value) then
			local progress = event:GetHoldProgress()

			if controller.holdStarted and progress >= 1 then
				playerData:RevokeAttribute(attributeData.type)

				--self.recentlyPurchased = true
				controller.dataManager:UpdateData()

				local animOptions = inkanimPlaybackOptions.new()
				animOptions.playReversed = true

				local animProxy = controller.attributeDisplayController:PlayLibraryAnimation('buy_attribute', animOptions)
				animProxy:RegisterToCallback(inkanimEventType.OnFinish, self.animCallbackProxy, 'OnAnimFinished')

				table.insert(self.animCallbackTargets, controller)

				controller:PlaySound('Item', 'OnCraftFailed')
			end
		end
	end)

	---@param controller PerksMenuAttributeDisplayController
	Observe('PerksMenuAttributeDisplayController', 'Update', function(controller)
		if controller.attributeData and self:IsAttributeHovered(controller) then
			self:SetAttributeButtonHints(controller.dataManager.parentGameCtrl, controller.attributeData)
		end
	end)

	---@param controller TargetHitIndicatorGameController
	Observe('TargetHitIndicatorGameController', 'OnAnimFinished', function(controller)
		if not controller.rootWidget and #self.animCallbackTargets > 0 then
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

return CharacterMainMenu