local Wrapper = {}

local TARGET = 'target'

function Wrapper.make(class, parent)
	class = class or {}
	class.__index = Wrapper.__index
	class.__newindex = Wrapper.__newindex

	class.instance = function(target, instance)
		instance = instance or {}
		instance[TARGET] = target

		if parent then
			instance = parent.new(target, instance)
		end

		setmetatable(instance, class)

		instance:Initialize()

		return instance
	end

	class.new = class.instance
	class.get = class.instance
	class.wrap = class.instance

	class.extend = function(child)
		return Wrapper.make(child, class)
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

function Wrapper.__index(self, key)
	local value = getmetatable(self)[key]

	if value == nil then
		value = rawget(self, TARGET)[key]

		if type(value) == 'function' then
			local func = value

			value = function(this, ...)
				return func(rawget(this, TARGET), ...)
			end

			rawset(getmetatable(self), key, value)
		end
	end

	return value
end

function Wrapper.__newindex(self, key, value)
	rawget(self, TARGET)[key] = value
end

return Wrapper