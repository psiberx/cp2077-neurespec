local Wrapper = require('core/support/Wrapper')

---@class PlayerDevSystem : PlayerDevelopmentSystem
local PlayerDevSystem = Wrapper.make()

---@public
---@return PlayerDevSystem
function PlayerDevSystem.resolve()
	return PlayerDevSystem.wrap(Game.GetScriptableSystemsContainer():Get('PlayerDevelopmentSystem'))
end

return PlayerDevSystem