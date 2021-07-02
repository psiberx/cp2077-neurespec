local Module = require('core/support/Module')
local Cron = require('core/services/Cron')
local GameLocale = require('core/services/GameLocale')
local PlayerDevData = require('game/systems/PlayerDevData')
local inkWidgetHelper = require('game/ui/ink/inkWidgetHelper')

---@class CharacterSkillsPanel : Module
---@field adjustSkillAction CName
---@field mainController PerksMainGameController
---@field perksController PerkScreenController
---@field adjustButtonHint ButtonHintListItem
---@field cursorEventCacther DebugHubMenuGameController
local CharacterSkillsPanel = Module.extend()

---@protected
function CharacterSkillsPanel:Initialize()
	self.adjustSkillAction = CName.new('upgrade_perk')
	self.cursorEventCacther = DebugHubMenuGameController.new()
end

---@public
function CharacterSkillsPanel:OnBootstrap()
	---@param mainController PerksMainGameController
	Observe('PerksMainGameController', 'OnInitialize', function(mainController)
		self.mainController = mainController
		self.perksController = inkWidgetRef.GetController(mainController.perksScreen)
	end)

	Observe('PerksMainGameController', 'OnUninitialize', function()
		self.mainController = nil
		self.perksController = nil
		self.adjustButtonHint = nil
	end)

	---@param rewardController StatsStreetCredReward
	Observe('StatsStreetCredReward', 'SetData', function(rewardController)
		if rewardController.rewardSize == 0 then
			Cron.NextTick(function()
				self:PrepareButtonHints()
			end)
		end

		Cron.Every(0.01, function(timer)
			if self:RegisterHoldCallbacks() then
				timer:Halt()
			end
		end)
	end)

	---@param event inkPointerEvent
	Observe('StatsStreetCredReward', 'OnHoverOver', function(_, event)
		self:SetButtonHints(event:GetCurrentTarget():GetController())
	end)

	Observe('StatsStreetCredReward', 'OnHoverOut', function()
		self:ResetButtonHints()
	end)

	---@param event inkPointerEvent
	Observe('DebugHubMenuGameController', 'OnButtonRelease', function(_, event)
		if event:IsAction(self.adjustSkillAction) then
			local rewardItemController = event:GetCurrentTarget():GetController()
			local proficiencyLevel = self:GetProficiencyLevelFromRewardItem(rewardItemController)
			local proficiencyType = self:GetCurrentProficiencyType()
			local playerData = PlayerDevData.resolve()

			if playerData:CanAdjustProficienyLevel(proficiencyType, proficiencyLevel) then
				if event:GetHoldProgress() >= 1 then
					playerData:AdjustProficienyLevel(proficiencyType, proficiencyLevel)

					self:UpdateDisplayData(proficiencyType)

					self.mainController:PlaySound('Item', 'OnCrafted')
				end
			end

			event:Handle()
		end
	end)

	---@param proficiency ProficiencyDisplayData
	Observe('StatsProgressController', 'SetProfiencyLevel', function(_, proficiency)
		if proficiency.level >= proficiency.unlockedLevel then
			proficiency.maxExpPoints = -1
		end
	end)
end

---@protected
---@return boolean
function CharacterSkillsPanel:RegisterHoldCallbacks()
	local rewardsController = self.perksController.rewardsController
	local currentNumItems = inkCompoundRef.GetNumChildren(rewardsController.prevRewardsList)
		+ inkCompoundRef.GetNumChildren(rewardsController.currentRewardsList)
		+ inkCompoundRef.GetNumChildren(rewardsController.nextRewardsList)

	if currentNumItems < 19 then
		return false
	end

	---@param rewardItemWidget inkWidget
	local registerHoldCallback = function(rewardItemWidget)
		rewardItemWidget:RegisterToCallback('OnHold', self.cursorEventCacther, 'OnButtonRelease')
	end

	inkWidgetHelper.ApplyToChildren(rewardsController.prevRewardsList, registerHoldCallback)
	inkWidgetHelper.ApplyToChildren(rewardsController.currentRewardsList, registerHoldCallback)
	inkWidgetHelper.ApplyToChildren(rewardsController.nextRewardsList, registerHoldCallback)

	return true
end

---@protected
function CharacterSkillsPanel:PrepareButtonHints()
	if not self.adjustButtonHint and self.mainController then
		local adjustButtonHintWidget = self.mainController.buttonHintsController:SpawnFromLocal(
			self.perksController.rewardsController.scrollButtonHint.widget,
			'ButtonHintListItem'
		)

		adjustButtonHintWidget:SetVisible(false)
		adjustButtonHintWidget:SetMargin(20, 0, 0, 0)

		self.adjustButtonHint = adjustButtonHintWidget:GetController()
		self.adjustButtonHint:SetData(self.adjustSkillAction, GameLocale.ActionHold('UI-UserActions-Select'))
	end
end

---@protected
---@param rewardItemController StatsStreetCredRewardItem
function CharacterSkillsPanel:SetButtonHints(rewardItemController)
	if self.mainController then
		local proficiencyLevel = self:GetProficiencyLevelFromRewardItem(rewardItemController)
		local proficiencyType = self:GetCurrentProficiencyType()
		local playerData = PlayerDevData.resolve()

		if playerData:CanAdjustProficienyLevel(proficiencyType, proficiencyLevel) then
			self.adjustButtonHint:GetRootWidget():SetVisible(true)
		else
			self.adjustButtonHint:GetRootWidget():SetVisible(false)
		end

		local cursorData = MenuCursorUserData.new()
		cursorData:AddAction(self.adjustSkillAction)
		cursorData:SetAnimationOverride('hoverOnHoldToComplete')

		self.mainController:SetCursorContext('Hover', cursorData)
	end
end

---@protected
function CharacterSkillsPanel:ResetButtonHints()
	if self.mainController then
		self.mainController.buttonHintsController:RemoveButtonHint(self.adjustSkillAction)
	end
end

---@protected
---@param rewardItemController StatsStreetCredRewardItem
---@return number
function CharacterSkillsPanel:GetProficiencyLevelFromRewardItem(rewardItemController)
	return rewardItemController.data.level
end

---@protected
---@return gamedataProficiencyType
function CharacterSkillsPanel:GetCurrentProficiencyType()
	return self.perksController:GetProficiencyDisplayData().proficiency
end

---@protected
---@param proficiencyType gamedataProficiencyType
function CharacterSkillsPanel:UpdateDisplayData(proficiencyType)
	local proficiency = self.perksController.dataManager:GetProficiencyWithData(proficiencyType)

	local proficiencies = self.perksController.displayData.proficiencies
	proficiencies[self.perksController.currentIndex + 1] = proficiency
	self.perksController.displayData.proficiencies = proficiencies

	--self.perksController.rewardsController:SetData(proficiency.passiveBonusesData, self.perksController.tooltipsManager, proficiency.level, 0)
	self.perksController:RebuildPerks(self.perksController.currentIndex)
	self.perksController.dataManager:UpdateData()
end

return CharacterSkillsPanel