local inkWidgetHelper = require('game/ui/ink/inkWidgetHelper')

---@class LibraryReference
---@field resourcePath redResourceReferenceScriptToken
---@field libraryId CName

local inkTooltipHelper = {}

---@param tooltipsManager gameuiTooltipsManager
---@param tooltipId Int32|CName
---@return LibraryReference
function inkTooltipHelper.FindLibraryReference(tooltipsManager, tooltipId)
	if type(tooltipId) == 'number' then
		return {
			resourcePath = tooltipsManager.TooltipsLibrary,
			libraryId = tooltipsManager.GenericTooltipsNames[tooltipId + 1]
		}
	end

	if type(tooltipId) == 'string' then
		tooltipId = CName.new(tooltipId)
	end

	for _, tooltipReference in ipairs(tooltipsManager.TooltipLibrariesReferences) do
		if tooltipReference.identifier == tooltipId then
			local libraryReference = tooltipReference.widgetLibraryReference
			return {
				resourcePath = inkWidgetLibraryResourceWrapper.GetPath(libraryReference.widgetLibrary),
				libraryId = libraryReference.widgetItem
			}
		end
	end

	for _, tooltipReference in ipairs(tooltipsManager.TooltipLibrariesStyledReferences) do
		if tooltipReference.identifier == tooltipId then
			local libraryReference = tooltipReference.widgetLibraryReference
			return {
				resourcePath = inkWidgetLibraryResourceWrapper.GetPath(libraryReference.widgetLibrary),
				libraryId = libraryReference.widgetItem
			}
		end
	end

	return nil
end

---@param tooltipsManager gameuiTooltipsManager
---@param tooltipId Int32|CName
---@param containerPath table|string
---@param referenceName CName|string
---@param tooltipController AGenericTooltipController
---@param actionName CName
---@param actionLabel String
---@return inkWidget
function inkTooltipHelper.AppendAction(tooltipsManager, tooltipId, containerPath, referenceName, tooltipController, actionName, actionLabel)
	---@type inkCompoundWidget
	local tooltipWidget = tooltipController:GetRootCompoundWidget()

	---@type inkCompoundWidget
	local containerWidget = tooltipWidget:GetWidgetByPath(
		inkWidgetHelper.MakePath(containerPath)
	)

	if not containerWidget then
		return nil
	end

	---@type inkFlexWidget
	local actionWidget = containerWidget:GetWidget(actionName)

	if actionWidget and actionWidget.name == actionName then
		return actionWidget
	end

	---@type inkCompoundWidget
	local tooltipsContainer = inkWidgetReference.Get(tooltipsManager:GetTooltipsContainerRef())
	local tooltipReference = inkTooltipHelper.FindLibraryReference(tooltipsManager, tooltipId)

	---@type inkCompoundWidget
	local tooltipTemplate = tooltipsManager:SpawnFromExternal(
		tooltipsContainer,
		tooltipReference.resourcePath,
		tooltipReference.libraryId
	)

	actionWidget = tooltipTemplate:GetWidgetByPath(
		inkWidgetHelper.MakePath(containerPath .. '/' .. referenceName)
	)

	inkWidgetHelper.ReuseWidget(actionWidget, containerWidget, actionName)

	tooltipsContainer:RemoveChild(tooltipTemplate)

	---@type inkHorizontalPanelWidget
	local inputDisplayWidget = actionWidget:GetWidget('inputDisplayController')

	---@type inkInputDisplayController
	local inputDisplayController = inputDisplayWidget:GetController()
	inputDisplayController:SetInputAction(actionName)

	---@type inkTextWidget
	local inputLabelWidget = inputDisplayWidget:GetWidget('action')
	inputLabelWidget:SetText(actionLabel)

	inkWidgetHelper.PlaceAfter(containerWidget, actionWidget, referenceName)

	return actionWidget
end

return inkTooltipHelper