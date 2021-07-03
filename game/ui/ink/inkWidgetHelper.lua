local inkWidgetHelper = {}

---@param path string|string[]
---@return inkWidgetPath
function inkWidgetHelper.MakePath(path)
	if type(path) == 'string' then
		local result = {}

		path:gsub('[^/]+', function(match)
			table.insert(result, match)
		end)

		path = result
	end

	local widgetPath = inkWidgetPath.new()
	widgetPath.names = path

	return widgetPath
end

---@param parentWidget inkCompoundWidget
---@param widgetName CName|String
---@return number
function inkWidgetHelper.GetChildIndex(parentWidget, widgetName)
	local maxIndex = parentWidget:GetNumChildren() - 1

	if type(widgetName) == 'string' then
		widgetName = CName.new(widgetName)
	end

	for i = 0, maxIndex do
		if parentWidget:GetWidgetByIndex(i).name == widgetName then
			return i
		end
	end

	return -1
end

---@param parentWidget inkCompoundWidget
---@param targetWidget inkWidget
---@param siblingName CName
function inkWidgetHelper.PlaceAfter(parentWidget, targetWidget, siblingName)
	if type(siblingName) == 'string' then
		siblingName = CName.new(siblingName)
	end

	local siblingPosition = inkWidgetHelper.GetChildIndex(parentWidget, siblingName)

	if siblingPosition >= 0 then
		parentWidget:ReorderChild(targetWidget, siblingPosition + 1)
	end
end

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
	targetWidget:Reparent(parentWidget)

	if newWidgetName then
		targetWidget.name = newWidgetName
	end

	return targetWidget.logicController
end

return inkWidgetHelper