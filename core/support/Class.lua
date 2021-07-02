local Class = {}

function Class.make(class, parent)
	class = class or {}
	class.__index = class

	class.instance = function(instance)
		instance = instance or {}

		if parent then
			instance = parent.new(instance)
		end

		setmetatable(instance, class)

		instance:Initialize()

		return instance
	end

	class.new = class.instance
	class.get = class.instance

	class.extend = function(child)
		return Class.make(child, class)
	end

	class.is = function(instance)
		local metatable = getmetatable(instance)

		if type(metatable) ~= 'table' then
			return false
		end

		if metatable.__index == class then
			return true
		end

		return class.is(metatable)
	end

	if parent then
		setmetatable(class, { __index = parent })
	end

	if not class.Initialize then
		class.Initialize = function() end
	end

	return class
end

return Class