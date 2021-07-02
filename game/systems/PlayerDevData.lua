local Wrapper = require('core/support/Wrapper')

---@class PlayerDevData : PlayerDevelopmentData
local PlayerDevData = Wrapper.make()

---@public
---@param owner gameObject
---@return PlayerDevData
function PlayerDevData.resolve(owner)
	return PlayerDevData.wrap(PlayerDevelopmentSystem.GetData(owner or Game.GetPlayer()))
end

-- Points --

---@public
---@param pointType gamedataDevelopmentPointType
---@return number
function PlayerDevData:GetSpentPoints(pointType)
	if pointType == gamedataDevelopmentPointType.Attribute then
		local spentPoints = 0
		local attributeMin = PlayerDevData.GetMinAttributeLevel()

		for _, attributeType in ipairs(PlayerDevData.GetAllAttributeTypes()) do
			local attributeLevel = self:GetAttributeLevel(attributeType)
			local attributeDiff = attributeLevel - attributeMin

			spentPoints = spentPoints + attributeDiff
		end

		return spentPoints
	end

	return math.floor(self.devPoints[self:GetDevPointsIndex(pointType) + 1].spent)
end

---@public
---@param pointType gamedataDevelopmentPointType
---@param amount number
function PlayerDevData:AdjustDevPoints(pointType, amount)
	local devPoints = self.devPoints

	local pointData = devPoints[self:GetDevPointsIndex(pointType) + 1]
	pointData.unspent = pointData.unspent + amount
	pointData.spent = pointData.spent - amount

	self.devPoints = devPoints
end

-- Attributes --

---@public
---@return gamedataStatType[]
function PlayerDevData.GetAllAttributeTypes()
	return {
		gamedataStatType.Strength,
		gamedataStatType.Reflexes,
		gamedataStatType.TechnicalAbility,
		gamedataStatType.Intelligence,
		gamedataStatType.Cool,
	}
end

---@public
---@return number
function PlayerDevData.GetMinAttributeLevel()
	return TweakDBInterface.GetInt('UICharacterCreationGeneral.BaseValues.minAttributeValue', 3)
end

---@public
---@param attributeType gamedataStatType
---@return number
function PlayerDevData:GetAttributeLevel(attributeType)
	return Game.GetStatsSystem():GetStatValue(self.ownerID, attributeType)
end

---@public
---@param attributeType gamedataStatType
---@param attributeLevel number
---@return number
function PlayerDevData:GetAttributeLevelCost(attributeType, attributeLevel)
	local statsDataSystem = Game.GetStatsDataSystem()

	local attributeCost = statsDataSystem:GetValueFromCurve(
		'player_attributeLevelToCostIncrease',
		attributeLevel,
		attributeType.value
	)

	return math.floor(attributeCost + .5)
end

---@public
---@param attributeLevel number
---@return boolean
function PlayerDevData:CanRevokeAttribute(attributeLevel)
	return attributeLevel > self.GetMinAttributeLevel()
end

---@public
---@param attributeType gamedataStatType
function PlayerDevData:RevokeAttribute(attributeType)
	local attributeLevel = self:GetAttributeLevel(attributeType)

	if attributeLevel > PlayerDevData.GetMinAttributeLevel() then
		local attributeCost = self:GetAttributeLevelCost(attributeType, attributeLevel)

		self:ModifyAttribute(attributeType, -1.0)
		self:AdjustDevPoints(gamedataDevelopmentPointType.Attribute, attributeCost)
		self:InvalidatePerks()
	end
end

---@public
function PlayerDevData:ResetAttributes()
	local attributeMin = PlayerDevData.GetMinAttributeLevel()
	local returnedPoints = self:GetDevPoints(gamedataDevelopmentPointType.Attribute)

	for _, attributeType in ipairs(PlayerDevData.GetAllAttributeTypes()) do
		local attributeLevel = self:GetAttributeLevel(attributeType)
		local attributeDiff = attributeLevel - attributeMin

		if attributeDiff > 0 then
			self:ModifyAttribute(attributeType, -attributeDiff)
			returnedPoints = returnedPoints + attributeDiff
		end
	end

	self:ResetDevelopmentPoints(gamedataDevelopmentPointType.Attribute)

	local availablePoints = self:GetDevPoints(gamedataDevelopmentPointType.Attribute)
	if returnedPoints > availablePoints  then
		self:AddDevelopmentPoints(returnedPoints - availablePoints, gamedataDevelopmentPointType.Attribute)
	end

	self:InvalidatePerks()
end

-- Perks and Traits --

---@return number
function PlayerDevData.GetMinPerkLevel()
	return 0
end

---@public
---@param perkLevel number
---@return boolean
function PlayerDevData:CanRevokePerk(perkLevel)
	return perkLevel > self.GetMinPerkLevel()
end

---@public
---@param perkType gamedataPerkType
function PlayerDevData:RevokePerk(perkType)
	local perkLevel = self:GetPerkLevel(perkType)

	if perkLevel > PlayerDevData.GetMinPerkLevel() then
		self:RemovePerk(perkType)

		if perkLevel > 1 then
			for _ = 2, perkLevel do
				self:BuyPerk(perkType)
			end
		end

		--Game.GetUISystem():QueueEvent(PerkBoughtEvent.new({ perkType = perkType }))
	end
end

---@public
---@param traitType gamedataTraitType
function PlayerDevData:RevokeTrait(traitType)
	local traitLevel = self:GetTraitLevel(traitType)

	if traitLevel > PlayerDevData.GetMinPerkLevel() then
		self:RemoveTrait(traitType)

		if traitLevel > 1 then
			for _ = 2, traitLevel do
				self:IncreaseTraitLevel(traitType)
			end
		end

		--Game.GetUISystem():QueueEvent(TraitBoughtEvent.new({ traitType = traitType }))
	end
end

---@public
function PlayerDevData:ResetPerks()
	self:RemoveAllPerks()
end

---@public
function PlayerDevData:InvalidatePerks()
	for _, perkArea in ipairs(self.perkAreas) do
		if not perkArea.unlocked then
			for _, perk in ipairs(perkArea.boughtPerks) do
				self:RemovePerk(perk.type)
			end
		end
	end
end

-- Skills --

---@protected
---@param proficiencyType gamedataProficiencyType
---@return string
function PlayerDevData:getProficiencyLevelFactName(proficiencyType)
	local proficiencyIndex = self:GetProficiencyIndexByType(proficiencyType)

	return ('_psxnrs_proficiency_alltime_%d'):format(proficiencyIndex)
end

---@public
---@param proficiencyType gamedataProficiencyType
---@return number
function PlayerDevData:GetProficiencyAlltimeLevel(proficiencyType)
	local currentLevel = self:GetProficiencyLevel(proficiencyType)
	local alltimeLevel = Game.GetQuestsSystem():GetFactStr(self:getProficiencyLevelFactName(proficiencyType))

	return math.max(currentLevel, alltimeLevel)
end

---@public
---@param proficiencyType gamedataProficiencyType
---@param alltimeLevel number|nil
function PlayerDevData:SetProficiencyAlltimeLevel(proficiencyType, alltimeLevel)
	if not alltimeLevel then
		alltimeLevel = self:GetProficiencyAlltimeLevel(proficiencyType)
	end

	Game.GetQuestsSystem():SetFactStr(self:getProficiencyLevelFactName(proficiencyType), alltimeLevel)
end

---@public
---@param proficiencyType gamedataProficiencyType
---@param targetLevel number
---@return boolean
function PlayerDevData:CanAdjustProficienyLevel(proficiencyType, targetLevel)
	local alltimeLevel = self:GetProficiencyAlltimeLevel(proficiencyType)
	local currentLevel = self:GetProficiencyLevel(proficiencyType)

	return targetLevel ~= currentLevel and targetLevel <= alltimeLevel
end

---@public
---@param proficiencyType gamedataProficiencyType
---@param targetLevel number
---@return boolean
function PlayerDevData:AdjustProficienyLevel(proficiencyType, targetLevel)
	local currentLevel = self:GetProficiencyLevel(proficiencyType)

	if targetLevel ~= currentLevel then
		self:SetProficiencyAlltimeLevel(proficiencyType)

		local attributeType
		local attributeIndex
		local attributeLevelAdjusment = 0
		local maxLevel = self:GetProficiencyMaxLevel(proficiencyType)
		if targetLevel > maxLevel then
			local proficiencyRecord = RPGManager.GetProficiencyRecord(proficiencyType)
			local attributeRecord = proficiencyRecord:TiedAttribute()

			if attributeRecord then
				attributeType = Enum.new('gamedataStatType', attributeRecord:EnumName())
				attributeIndex = self:GetAttributeIndex(attributeType)

				local attributes = self.attributes
				attributeLevelAdjusment = attributes[attributeIndex + 1].value
				attributes[attributeIndex + 1].value = attributeRecord:Max()
				self.attributes = attributes
			end
		end

		local perkPointBonusAdjusment = 0
		if targetLevel < currentLevel then
			local proficiencyIndex = self:GetProficiencyIndexByType(proficiencyType)
			local proficiencyRecord = self:GetProficiencyRecordByIndex(proficiencyIndex)
			local perkPointBonusEffectorId = TweakDBID.new('Proficiencies.AddPerkPoint') -- TweakDBID.new(0xE14F1253, 26)

			for level = 1, currentLevel do
				local bonusItem = proficiencyRecord:GetPassiveBonusesItem(level - 1)

				if bonusItem then
					local bonusEffector = bonusItem:EffectorToTrigger()

					if bonusEffector and bonusEffector:GetID() == perkPointBonusEffectorId then
						perkPointBonusAdjusment = perkPointBonusAdjusment - 1
					end
				end
			end
		end

		self:SetLevel(proficiencyType, targetLevel, telemetryLevelGainReason.Ignore)

		if attributeLevelAdjusment ~= 0 then
			local attributes = self.attributes
			attributes[attributeIndex + 1].value = attributeLevelAdjusment
			self.attributes = attributes
		end

		if perkPointBonusAdjusment ~= 0 then
			self:AddDevelopmentPoints(perkPointBonusAdjusment, gamedataDevelopmentPointType.Primary)
		end
	end
end

return PlayerDevData