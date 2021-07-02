local inkWidgetHelper = {}

---@param parentWidget inkCompoundWidget
---@param callback function
function inkWidgetHelper.ApplyToChildren(parentWidget, callback)
	local maxIndex = parentWidget:GetNumChildren() - 1

	for i = 0, maxIndex do
		callback(parentWidget:GetWidgetByIndex(i))
	end
end

---@param targetWidget inkWidget
---@param parentWidget inkWidget
---@param newWidgetName CName
---@return inkWidgetLogicController
function inkWidgetHelper.ReuseWidget(targetWidget, parentWidget, newWidgetName)
	if targetWidget.widget then
		targetWidget = targetWidget.widget
	end

	targetWidget:Reparent(parentWidget)

	if newWidgetName then
		targetWidget.name = newWidgetName
	end

	return targetWidget.logicController
end

---@param buttonWidget inkWidget
---@param parentWidget inkWidget
---@return MenuItemController
function inkWidgetHelper.ReuseButton(buttonWidget, parentWidget)
	local buttonController = inkWidgetHelper.ReuseWidget(buttonWidget, parentWidget, 0)
	buttonController.menuData = MenuData.new()

	return buttonController
end

---@param buttonController MenuItemController
---@param customStyle table
function inkWidgetHelper.ApplyButtonStyle(buttonController, customStyle)
	local buttonWidget = buttonController:GetRootWidget()

	if not buttonWidget then
		return
	end

	local buttonStyle = {
		width = 520,
		height = 94,
		paddingTop = 2,
		paddingLeft = 35,
		fontSize = 36,
		fontStyle = 'Medium',
	}

	if customStyle then
		for prop, value in pairs(customStyle) do
			buttonStyle[prop] = value
		end
	end

	if not buttonStyle.width then
		buttonStyle.width = buttonWidget:GetWidth()
	end

	if not buttonStyle.height then
		buttonStyle.height = buttonWidget:GetHeight()
	end

	local flexContainer = buttonWidget:GetWidget('inkFlexWidget4')

	local contentContainer = flexContainer:GetWidget('container')
	contentContainer:SetWidth(buttonStyle.width)
	contentContainer:SetHeight(buttonStyle.height)

	local labelWidget = contentContainer:GetWidget('txtValue')
	labelWidget:SetWidth(buttonStyle.width - buttonStyle.paddingLeft)
	labelWidget:SetHeight(buttonStyle.height - buttonStyle.paddingTop - 4)
	labelWidget:SetMargin(buttonStyle.paddingLeft, buttonStyle.paddingTop, 0, 0)

	if buttonStyle.fontStyle then
		labelWidget:UnbindProperty('fontStyle')
		labelWidget:SetFontStyle(buttonStyle.fontStyle)
	end

	if buttonStyle.fontSize then
		labelWidget:UnbindProperty('fontSize')
		labelWidget:SetFontSize(buttonStyle.fontSize)
	end

	local iconWidget = contentContainer:GetWidget('image')
	iconWidget:SetVisible(false)

	local fluffWidget = flexContainer:GetWidget('fluffText')
	fluffWidget:SetVisible(false)

	local minSizeWidget = flexContainer:GetWidget('minSize')
	minSizeWidget:SetHeight(buttonStyle.height)
	minSizeWidget:SetWidth(buttonStyle.width)

	inkWidgetHelper.ApplyToChildren(flexContainer:GetWidget('container_bk'), function(childWidget)
		local isLeft = childWidget.name.value:find('left')
		local isFrame = childWidget.name.value == 'frame'
		local isBackground = childWidget.name.value == 'background'

		childWidget:SetHeight(buttonStyle.height)

		if not isLeft then
			childWidget:SetWidth(buttonStyle.width)
		end

		if buttonStyle.frameColor and (isFrame or isLeft) then
			childWidget:UnbindProperty('tintColor')
			childWidget:SetTintColor(buttonStyle.frameColor)
			childWidget:SetOpacity(buttonStyle.frameColor.Alpha)
		end

		if buttonStyle.fillColor and isBackground then
			childWidget:UnbindProperty('tintColor')
			childWidget:SetTintColor(buttonStyle.fillColor)
			childWidget:SetOpacity(buttonStyle.fillColor.Alpha)
		end
	end)

	inkWidgetHelper.ApplyToChildren(flexContainer:GetWidget('hoverFrames'), function(childWidget)
		local isLeft = childWidget.name.value:find('left')
		local isFrame = childWidget.name.value == 'frameHovered'

		if buttonStyle.hoverColor and (isFrame or isLeft) then
			childWidget:UnbindProperty('tintColor')
			childWidget:SetTintColor(buttonStyle.hoverColor)
			childWidget:SetOpacity(buttonStyle.hoverColor.Alpha)
		end
	end)

	local pointsContainer = flexContainer:GetWidget('Points')
	pointsContainer:SetSize(contentContainer:GetSize())
	pointsContainer:SetMargin(contentContainer:GetMargin())

	for _, pointsWidgetName in ipairs({ 'AttrPoints', 'PerkPoints' }) do
		local pointsWidget = pointsContainer:GetWidget(pointsWidgetName)
		pointsWidget:SetScale(Vector2.new({ X = 0.75, Y = 0.75 }))
		pointsWidget:SetMargin(0, 20, 35, 0)
	end

	if buttonStyle.margin then
		buttonWidget:SetMargin(
			buttonStyle.margin.left or 0,
			buttonStyle.margin.top or 0,
			buttonStyle.margin.right or 0,
			buttonStyle.margin.bottom or 0
		)
	end

	buttonWidget:SetWidth(buttonStyle.width)
	buttonWidget:SetHeight(buttonStyle.height)
end

---@param buttonController MenuItemController
---@param buttonState table
function inkWidgetHelper.ApplyButtonState(buttonController, buttonState)
	local buttonWidget = buttonController:GetRootWidget()

	if not buttonWidget then
		return
	end

	local flexContainer = buttonWidget:GetWidget('inkFlexWidget4')

	local contentContainer = flexContainer:GetWidget('container')
	local iconWidget = contentContainer:GetWidget('image')
	local labelWidget = contentContainer:GetWidget('txtValue')

	if buttonState.label then
		labelWidget:SetText(buttonState.label)
	end

	if buttonState.attrPoints then
		local pointsWidget = flexContainer:GetWidget('Points'):GetWidget('PerkPoints')
		local pointsValueWidget = pointsWidget:GetWidget('New')
		pointsValueWidget:SetText(buttonState.attrPoints)

		if tonumber(buttonState.attrPoints) > 0 then
			pointsWidget:SetVisible(true)
			buttonState.disabled = false
		else
			pointsWidget:SetVisible(false)
			buttonState.disabled = true
		end
	end

	if buttonState.perkPoints then
		local pointsWidget = flexContainer:GetWidget('Points'):GetWidget('AttrPoints')
		local pointsValueWidget = pointsWidget:GetWidget('New')
		pointsValueWidget:SetText(buttonState.perkPoints)

		if tonumber(buttonState.perkPoints) > 0 then
			pointsWidget:SetVisible(true)
			buttonState.disabled = false
		else
			pointsWidget:SetVisible(false)
			buttonState.disabled = true
		end
	end

	buttonWidget:SetOpacity(buttonState.disabled and 0.3 or 1.0)
	labelWidget:SetOpacity(buttonState.disabled and 0.1 or 1.0)
	iconWidget:SetOpacity(buttonState.disabled and 0.1 or 1.0)

	local menuData = buttonController.menuData

	if menuData.userData and menuData.eventName then
		buttonController:UnregisterFromCallback('OnRelease', menuData.userData, menuData.eventName)
	end

	if buttonState.callback then
		menuData.userData = buttonState.callback.object
		menuData.eventName = buttonState.callback.method

		buttonController:UnregisterFromCallback('OnRelease', buttonController, 'OnMenuChangeRelease')
	end

	if buttonState.disabled ~= nil then
		menuData.disabled = buttonState.disabled
	end

	if buttonState.menuData then
		for menuProp, menuValue in pairs(buttonState.menuData) do
			menuData[menuProp] = menuValue
		end
	end

	buttonController.menuData = menuData

	if not menuData.disabled and menuData.userData and menuData.eventName then
		buttonController:RegisterToCallback('OnRelease', menuData.userData, menuData.eventName)
	end
end

---@param buttonController MenuItemController
function inkWidgetHelper.DisposeButton(buttonController)
	local menuData = buttonController.menuData

	if menuData.userData and menuData.eventName then
		buttonController:UnregisterFromCallback('OnRelease', menuData.userData, menuData.eventName)
	end

	buttonController.menuData = MenuData.new()
end

return inkWidgetHelper