local Module = require('core/support/Module')
local Cron = require('core/services/Cron')
local GameLocale = require('core/services/GameLocale')
local PlayerDevData = require('game/systems/PlayerDevData')
local inkTooltipHelper = require('game/ui/ink/inkTooltipHelper')

---@class CharacterMainMenu : Module
---@field upgradeAttributeAction CName
---@field revokeAttributeAction CName
---@field mainController PerksMainGameController
---@field animCallbackProxy TargetHitIndicatorGameController
---@field animCallbackTargets table
---@field revokeTooltipHint inkWidget
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
	---@param this PerksMainGameController
	Observe('PerksMainGameController', 'OnInitialize', function(this)
		self.mainController = this
	end)

	Observe('PerksMainGameController', 'OnUninitialize', function()
		self.mainController = nil
		self.revokeTooltipHint = nil
	end)

	---@param this PerksMainGameController
  	Override('PerksMainGameController', 'OnAttributeHoverOut', function(this)
		local isAttributeHovered = false

		for _, attributeController in ipairs(this.attributesControllersList) do
			if self:IsAttributeHovered(attributeController.attributeDisplayController) then
				isAttributeHovered = true
				break
			end
		end

		if not isAttributeHovered then
			this:PlayHoverAnimation(false)
			this:SetAttributeBuyButtonHintHoverOut()
			this:HideTooltip()
		end
	end)

	---@param attributeData AttributeData
  	Override('PerksMainGameController', 'SetAttributeBuyButtonHintHoverOver', function(_, attributeData)
		if attributeData then
			self:SetButtonHints(attributeData)
		end
	end)

	Observe('PerksMainGameController', 'SetAttributeBuyButtonHintHoverOut', function()
		-- Nested RTTI call workaround
		Cron.NextTick(function()
			self:ResetButtonHints()
		end)
	end)

	---@param this PerkMenuTooltipController
	---@param tooltipData ATooltipData
	Observe('PerkMenuTooltipController', 'SetupShared', function(this, tooltipData)
		-- Nested RTTI call workaround
		Cron.NextTick(function()
			self:SetTooltipHints(this, tooltipData)
		end)
	end)

	---@param this PerksMenuAttributeItemController
	---@param event inkPointerEvent
	Observe('PerksMenuAttributeItemController', 'OnAttributeItemHold', function(this, event)
		local playerData = PlayerDevData.resolve()
		local attributeData = this.attributeDisplayController.attributeData

		if event:IsAction(self.revokeAttributeAction) and attributeData and playerData:CanRevokeAttribute(attributeData.value) then
			local progress = event:GetHoldProgress()

			if this.holdStarted and progress >= 1 then
				playerData:RevokeAttribute(attributeData.type)

				self:UpdateDisplayData(this)

				local animOptions = inkanimPlaybackOptions.new()
				animOptions.playReversed = true

				local animProxy = this.attributeDisplayController:PlayLibraryAnimation('buy_attribute', animOptions)
				animProxy:RegisterToCallback(inkanimEventType.OnFinish, self.animCallbackProxy, 'OnAnimFinished')

				table.insert(self.animCallbackTargets, this)

				this:PlaySound('Item', 'OnCraftFailed')
			end
		end
	end)

	---@param this PerksMenuAttributeDisplayController
	Observe('PerksMenuAttributeDisplayController', 'Update', function(this)
		-- Nested RTTI call workaround
		Cron.NextTick(function()
			if this.attributeData and self:IsAttributeHovered(this) then
				self:SetButtonHints(this.attributeData)
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
---@param attributeData AttributeData
function CharacterMainMenu:SetButtonHints(attributeData)
	if self.mainController then
		local playerData = PlayerDevData.resolve()

		if playerData:CanRevokeAttribute(attributeData.value) then
			self.mainController.buttonHintsController:AddButtonHint(self.revokeAttributeAction, GameLocale.ActionHold('LocKey#17848'))
		else
			self.mainController.buttonHintsController:RemoveButtonHint(self.revokeAttributeAction)
		end

		if attributeData.availableToUpgrade and self.mainController.dataManager:HasAvailableAttributePoints() then
			self.mainController.buttonHintsController:AddButtonHint(self.upgradeAttributeAction, GameLocale.ActionHold('UI-ScriptExports-Buy0'))
		else
			self.mainController.buttonHintsController:RemoveButtonHint(self.upgradeAttributeAction)
		end

		local cursorData = MenuCursorUserData.new()
		cursorData:AddAction(self.upgradeAttributeAction)
		cursorData:AddAction(self.revokeAttributeAction)
		cursorData:SetAnimationOverride('hoverOnHoldToComplete')

		self.mainController:SetCursorContext('Hover', cursorData)
	end
end

---@protected
function CharacterMainMenu:ResetButtonHints()
	if self.mainController then
		self.mainController.buttonHintsController:RemoveButtonHint(self.revokeAttributeAction)
	end
end

---@protected
---@param tooltipController PerkMenuTooltipController
---@param tooltipData AttributeTooltipData
function CharacterMainMenu:SetTooltipHints(tooltipController, tooltipData)
	if self.mainController then
		if not self.revokeTooltipHint then
			self.revokeTooltipHint = inkTooltipHelper.AppendAction(
				self.mainController.tooltipsManager,
				tooltipController,
				self.revokeAttributeAction,
				GameLocale.Text('Hold to Return'),
				CName.new('holdToUpgrade')
			)
		end

		if tooltipData.attributeData then
			local playerData = PlayerDevData.resolve()

			if playerData:CanRevokeAttribute(tooltipData.attributeData.value) then
				self.revokeTooltipHint:SetVisible(true)
			else
				self.revokeTooltipHint:SetVisible(false)
			end
		end
	end
end

---@protected
---@param attributeController PerksMenuAttributeItemController
function CharacterMainMenu:UpdateDisplayData(attributeController)
	attributeController.dataManager:UpdateData()
	attributeController:Setup(attributeController.dataManager)
end

return CharacterMainMenu