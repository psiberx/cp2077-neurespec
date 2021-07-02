local Module = require('core/support/Module')
local Cron = require('core/services/Cron')
local GameLocale = require('core/services/GameLocale')
local PlayerDevData = require('game/systems/PlayerDevData')
local inkButtonHelper = require('game/ui/ink/inkButtonHelper')

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
	---@param this MenuHubLogicController
	Observe('MenuHubLogicController', 'OnInitialize', function(this)
		self.hubMenuController = this
	end)

	Observe('MenuHubLogicController', 'OnUninitialize', function()
		self.hubMenuController = nil
	end)

	---@param this PerksMainGameController
	Observe('PerksMainGameController', 'ResetData', function(this)
		if self.hubMenuController then
			local resetPanelWidget = this.pointsDisplayController.resetWidget.widget

			self.resetAttrsController = inkButtonHelper.ReuseButton(self.hubMenuController.btnPhone.widget, resetPanelWidget)
			self.resetPerksController = inkButtonHelper.ReuseButton(self.hubMenuController.btnShard.widget, resetPanelWidget)

			inkButtonHelper.ApplyButtonState(self.resetAttrsController, {
				label = GameLocale.Text('UI-Menus-Attributes-ResetAttributes'),
				menuData = { identifier = self.resetAttrsEventId },
				callback = { object = this, method = 'OnResetPerksClick' }
			})

			inkButtonHelper.ApplyButtonState(self.resetPerksController, {
				label = GameLocale.Text('UI-Menus-Perks-ResetPerks'),
				menuData = { identifier = self.resetPerksEventId },
				callback = { object = this, method = 'OnResetPerksClick' }
			})

			inkButtonHelper.ApplyButtonStyle(self.resetAttrsController, { margin = { top = 170 }	})
			inkButtonHelper.ApplyButtonStyle(self.resetPerksController, { margin = { top = 50 } })
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
			})

			inkButtonHelper.ApplyButtonState(self.resetPerksController, {
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

	Observe('MenuScenario_Idle', 'OnEnterScenario', function()
		if self.resetAttrsController then
			inkButtonHelper.DisposeButton(self.resetAttrsController)
			self.resetAttrsController = nil
		end

		if self.resetPerksController then
			inkButtonHelper.DisposeButton(self.resetPerksController)
			self.resetPerksController = nil
		end

		self.hubMenuController = nil
	end)
end

return CharacterResetPanel