local Module = require('core/support/Module')
local Cron = require('core/services/Cron')
local GameLocale = require('core/services/GameLocale')
local PlayerDevData = require('game/systems/PlayerDevData')
local inkButtonHelper = require('game/ui/ink/inkButtonHelper')

---@class CharacterResetPanel : Module
---@field hubMenuController MenuHubLogicController
---@field mainController PerksMainGameController
---@field resetAttrsController MenuItemController
---@field resetPerksController MenuItemController
---@field resetAttrsEventId Int32
---@field resetPerksEventId Int32
---@field characterMenuName CName
---@field dummyWidgetContainer inkCompoundWidget
local CharacterResetPanel = Module.extend()

---@protected
function CharacterResetPanel:Initialize()
	self.resetAttrsEventId = -1001
	self.resetPerksEventId = -1002
	self.characterMenuName = CName.new('perks_main')
	self.dummyWidgetContainer = inkCompoundWidget.new()
end

---@public
function CharacterResetPanel:OnBootstrap()
	---@param this MenuHubLogicController
	Observe('MenuHubLogicController', 'OnInitialize', function(this)
		self.hubMenuController = this
	end)

	---@param this PerksMainGameController
	Observe('PerksMainGameController', 'ResetData', function(this)
		local resetPanelWidget = this.pointsDisplayController.resetWidget.widget

		if self.hubMenuController then
			self.mainController = this
			self.resetAttrsController = inkButtonHelper.ReuseButton(self.hubMenuController.btnPhone.widget, resetPanelWidget)
			self.resetPerksController = inkButtonHelper.ReuseButton(self.hubMenuController.btnShard.widget, resetPanelWidget)

			inkButtonHelper.ApplyButtonState(self.resetAttrsController, {
				label = GameLocale.Text('UI-Menus-Attributes-ResetAttributes'),
				menuData = { identifier = self.resetAttrsEventId },
				callback = { object = self.mainController, method = 'OnResetPerksClick' }
			})

			inkButtonHelper.ApplyButtonState(self.resetPerksController, {
				label = GameLocale.Text('UI-Menus-Perks-ResetPerks'),
				menuData = { identifier = self.resetPerksEventId },
				callback = { object = self.mainController, method = 'OnResetPerksClick' }
			})

			inkButtonHelper.ApplyButtonStyle(self.resetAttrsController, { margin = { top = 170 } })
			inkButtonHelper.ApplyButtonStyle(self.resetPerksController, { margin = { top = 50 } })

			self.hubMenuController = nil
		elseif self.resetAttrsController then
			self.mainController = this
			self.resetAttrsController:Reparent(resetPanelWidget)
			self.resetPerksController:Reparent(resetPanelWidget)
		end
	end)

	---@param this PerksMainGameController
	Observe('PerksMainGameController', 'UpdateAvailablePoints', function(this)
		if self.resetAttrsController and this.activeScreen == CharacterScreenType.Attributes then
			local resetPanelWidget = this.pointsDisplayController.resetWidget.widget
			resetPanelWidget:GetWidget('resetPointBtn'):SetVisible(false)
			resetPanelWidget:GetWidget('spentPoints'):SetVisible(false)
			resetPanelWidget:SetVisible(true)

			local playerData = PlayerDevData.resolve()

			inkButtonHelper.ApplyButtonState(self.resetAttrsController, {
				attrPoints = playerData:GetSpentPoints(gamedataDevelopmentPointType.Attribute),
				callback = { object = self.mainController, method = 'OnResetPerksClick' }
			})

			inkButtonHelper.ApplyButtonState(self.resetPerksController, {
				perkPoints = playerData:GetSpentPoints(gamedataDevelopmentPointType.Primary),
				callback = { object = self.mainController, method = 'OnResetPerksClick' }
			})
		end
	end)

	---@param event inkPointerEvent
	Observe('PerksMainGameController', 'OnResetPerksClick', function(_, event)
		if event:IsAction('click') then
			---@type MenuItemController
			local resetButtonController = event:GetCurrentTarget():GetController()
			local resetButtonData = resetButtonController.menuData

			if not resetButtonData.disabled then
				self.resetEventId = resetButtonController.menuData.identifier
			end
		end
	end)

	---@param this GenericMessageNotification
	Observe('GenericMessageNotification', 'OnInitialize', function(this)
		if self.resetEventId then
			Cron.NextTick(function()
				this.data.identifier = self.resetEventId

				if self.resetEventId == self.resetAttrsEventId then
					inkTextRef.SetText(this.title, GameLocale.Text('UI-Menus-Attributes-ResetAttributes'))
					inkTextRef.SetText(this.message, GameLocale.Text('UI-Menus-Attributes-ResetConfirmation'))
				end

				self.resetEventId = nil
			end)
		end
	end)

	---@param this PerksMainGameController
	---@param confrmationData inkGameNotificationData
	Override('PerksMainGameController', 'OnResetConfirmed', function(this, confrmationData)
		if confrmationData.result == GenericMessageNotificationResult.Yes then
			local playerData = PlayerDevData.resolve()

			if confrmationData.identifier == self.resetAttrsEventId then
				playerData:ResetAttributes()
				this:PlaySound('Item', 'OnCrafted')
			elseif confrmationData.identifier == self.resetPerksEventId then
				playerData:ResetPerks()
				this:PlaySound('Item', 'OnCrafted')
			end

			this.dataManager:UpdateData()
		end

		this.resetConfirmationToken = inkGameNotificationToken.new()
	end)

	---@param menuItemData MenuItemData
	Observe('MenuScenario_HubMenu', 'OnSelectMenuItem', function(_, menuItemData)
		if self.resetAttrsController and menuItemData.menuData.fullscreenName ~= self.characterMenuName then
			if self.dummyWidgetContainer:GetNumChildren() == 0 then
				inkButtonHelper.ApplyButtonState(self.resetAttrsController, {
					callback = { object = self.mainController, method = 'OnResetPerksClick' },
					disabled = true
				})

				inkButtonHelper.ApplyButtonState(self.resetPerksController, {
					callback = { object = self.mainController, method = 'OnResetPerksClick' },
					disabled = true
				})

				self.resetAttrsController:Reparent(self.dummyWidgetContainer)
				self.resetPerksController:Reparent(self.dummyWidgetContainer)
			end
		end
	end)

	Observe('PerksMainGameController', 'OnUninitialize', function()
		self.mainController = nil
	end)

	Observe('MenuScenario_Idle', 'OnEnterScenario', function()
		self.hubMenuController = nil
		self.resetAttrsController = nil
		self.resetPerksController = nil
	end)
end

return CharacterResetPanel