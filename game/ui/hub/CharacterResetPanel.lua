local Module = require('core/support/Module')
local Cron = require('core/services/Cron')
local GameLocale = require('core/services/GameLocale')
local PlayerDevData = require('game/systems/PlayerDevData')
local inkWidgetHelper = require('game/ui/ink/inkWidgetHelper')

---@class CharacterResetPanel : Module
---@field hubMenuController MenuHubLogicController
---@field resetAttrsController MenuItemController
---@field resetPerksController MenuItemController
---@field resetAttrsEventId Int32
---@field resetPerksEventId Int32
local CharacterResetPanel = Module.extend()

---@protected
function CharacterResetPanel:Initialize()
	self.resetAttrsEventId = -1001
	self.resetPerksEventId = -1002
end

---@public
function CharacterResetPanel:OnBootstrap()
	---@param hubMenuController MenuHubLogicController
	Observe('MenuHubLogicController', 'OnInitialize', function(hubMenuController)
		self.hubMenuController = hubMenuController
	end)

	Observe('MenuHubLogicController', 'OnUninitialize', function()
		self.hubMenuController = nil
	end)

	---@param mainController PerksMainGameController
	Observe('PerksMainGameController', 'ResetData', function(mainController)
		if self.hubMenuController then
			local resetPanelWidget = mainController.pointsDisplayController.resetWidget.widget

			self.resetAttrsController = inkWidgetHelper.ReuseButton(self.hubMenuController.btnPhone, resetPanelWidget)
			self.resetPerksController = inkWidgetHelper.ReuseButton(self.hubMenuController.btnShard, resetPanelWidget)

			inkWidgetHelper.ApplyButtonState(self.resetAttrsController, {
				label = GameLocale.Text('UI-Menus-Attributes-ResetAttributes'),
				menuData = { identifier = self.resetAttrsEventId },
				callback = { object = mainController, method = 'OnResetPerksClick' }
			})

			inkWidgetHelper.ApplyButtonState(self.resetPerksController, {
				label = GameLocale.Text('UI-Menus-Perks-ResetPerks'),
				menuData = { identifier = self.resetPerksEventId },
				callback = { object = mainController, method = 'OnResetPerksClick' }
			})

			inkWidgetHelper.ApplyButtonStyle(self.resetAttrsController, { margin = { top = 170 }	})
			inkWidgetHelper.ApplyButtonStyle(self.resetPerksController, { margin = { top = 50 } })
		end
	end)

	---@param mainController PerksMainGameController
  	Observe('PerksMainGameController', 'UpdateAvailablePoints', function(mainController)
		if self.resetAttrsController and mainController.activeScreen == CharacterScreenType.Attributes then
			local resetPanelWidget = mainController.pointsDisplayController.resetWidget.widget
			resetPanelWidget:GetWidget('resetPointBtn'):SetVisible(false)
			resetPanelWidget:GetWidget('spentPoints'):SetVisible(false)
			resetPanelWidget:SetVisible(true)

			local playerData = PlayerDevData.resolve()

			inkWidgetHelper.ApplyButtonState(self.resetAttrsController, {
				attrPoints = playerData:GetSpentPoints(gamedataDevelopmentPointType.Attribute),
			})

			inkWidgetHelper.ApplyButtonState(self.resetPerksController, {
				perkPoints = playerData:GetSpentPoints(gamedataDevelopmentPointType.Primary),
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

	---@param messageController GenericMessageNotification
	Observe('GenericMessageNotification', 'OnInitialize', function(messageController)
		if self.resetEventId then
			Cron.NextTick(function()
				messageController.data.identifier = self.resetEventId

				if self.resetEventId == self.resetAttrsEventId then
					inkTextRef.SetText(messageController.title, GameLocale.Text('UI-Menus-Attributes-ResetAttributes'))
					inkTextRef.SetText(messageController.message, GameLocale.Text('UI-Menus-Attributes-ResetConfirmation'))
				end

				self.resetEventId = nil
			end)
		end
	end)

	---@param mainController PerksMainGameController
	---@param confrmationData inkGameNotificationData
	Override('PerksMainGameController', 'OnResetConfirmed', function(mainController, confrmationData)
		if confrmationData.result == GenericMessageNotificationResult.Yes then
			local playerData = PlayerDevData.resolve()

			if confrmationData.identifier == self.resetAttrsEventId then
				playerData:ResetAttributes()
				mainController:PlaySound('Item', 'OnCrafted')
			elseif confrmationData.identifier == self.resetPerksEventId then
				playerData:ResetPerks()
				mainController:PlaySound('Item', 'OnCrafted')
			end

			mainController.dataManager:UpdateData()
		end

		mainController.resetConfirmationToken = inkGameNotificationToken.new()
	end)

	Observe('MenuScenario_Idle', 'OnEnterScenario', function()
		if self.resetAttrsController then
			inkWidgetHelper.DisposeButton(self.resetAttrsController)
			self.resetAttrsController = nil
		end

		if self.resetPerksController then
			inkWidgetHelper.DisposeButton(self.resetPerksController)
			self.resetPerksController = nil
		end

		self.hubMenuController = nil
	end)
end

return CharacterResetPanel