local inkWidgetHelper = require('game/ui/ink/inkWidgetHelper')

local inkTooltipHelper = {}

---@param tooltipsManager gameuiTooltipsManager
---@param tooltipController AGenericTooltipController
---@param actionName CName
---@param actionLabel String
---@param placeAfter CName
---@return inkWidget
function inkTooltipHelper.AppendAction(tooltipsManager, tooltipController, actionName, actionLabel, placeAfter)
	---@type inkCompoundWidget
	local tooltipWidget = tooltipController:GetRootCompoundWidget()

	---@type inkCompoundWidget
	local containerWidget = tooltipWidget:GetWidgetByPath(
		inkWidgetHelper.MakePath({ 'wrapper', 'contentWrapper', 'contentFlexWrapper', 'categoriesWrapper' })
	)

	---@type inkFlexWidget
	local actionWidget = containerWidget:GetWidget(actionName)

	if actionWidget and actionWidget.name == actionName then
		return actionWidget
	end

	---@type inkCompoundWidget
	local tooltipsContainer = inkWidgetReference.Get(tooltipsManager:GetTooltipsContainerRef())

	---@type inkCompoundWidget
	local donorTooltipWidget = tooltipsManager:SpawnFromExternal(
		tooltipsContainer,
		tooltipsManager.TooltipsLibrary,
		tooltipsManager.GenericTooltipsNames[1]
	)

	actionWidget = donorTooltipWidget:GetWidgetByPath(
		inkWidgetHelper.MakePath({ 'wrapper', 'contentWrapper', 'contentFlexWrapper', 'categoriesWrapper', 'holdToUpgrade' })
	)

	inkWidgetHelper.ReuseWidget(actionWidget, containerWidget, actionName)

	tooltipsContainer:RemoveChild(donorTooltipWidget)

	---@type inkHorizontalPanelWidget
	local inputDisplayWidget = actionWidget:GetWidget('inputDisplayController')

	---@type inkInputDisplayController
	local inputDisplayController = inputDisplayWidget:GetController()
	inputDisplayController:SetInputAction(actionName)

	---@type inkTextWidget
	local inputTextWidget = inputDisplayWidget:GetWidget('action')
	inputTextWidget:SetText(actionLabel)

	if placeAfter then
		local siblingPosition = inkWidgetHelper.GetChildIndex(containerWidget, placeAfter)

		if siblingPosition >= 0 then
			containerWidget:ReorderChild(actionWidget, siblingPosition + 1)
		end
	end

	return actionWidget
end

return inkTooltipHelper