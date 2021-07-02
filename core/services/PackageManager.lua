local Package = require('core/support/Package')

---@class PackageManager
local PackageManager = {}

---@type Package[]
local packages = {}

---@public
---@param package Package
function PackageManager.Register(package)
	if type(package) ~= 'table' or not Package.is(package) then
		error('Trying to register invalid package.')
	end

	table.insert(packages, package)
end

---@public
---@param packageType table
function PackageManager.RegisterFromType(packageType)
	PackageManager.Register(packageType.new())
end

---@public
---@param packagePath string
function PackageManager.RegisterFromPath(packagePath)
	PackageManager.RegisterFromType(require(packagePath))
end

---@public
function PackageManager.Bootstrap()
	for _, package in ipairs(packages) do
		package:Register()
	end
	for _, package in ipairs(packages) do
		package:Bootstrap()
	end
end

---@public
function PackageManager.Shutdown()
	for _, package in ipairs(packages) do
		package:Shutdown()
	end
end

return PackageManager