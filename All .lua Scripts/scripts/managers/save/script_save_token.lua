local TokenInterface = require("scripts/foundation/managers/token/token_interface")
local ScriptSaveToken = class("ScriptSaveToken")

function ScriptSaveToken:init(save_implementation, save_implementation_token)
	self._implementation = save_implementation
	self._token = save_implementation_token
	self._info = {}
end

function ScriptSaveToken:update()
	self._info = self._implementation.progress(self._token)
end

function ScriptSaveToken:info()
	return self._info
end

function ScriptSaveToken:done()
	return self._info.done
end

function ScriptSaveToken:close()
	self._implementation.close(self._token)
end

implements(ScriptSaveToken, TokenInterface)

return ScriptSaveToken
