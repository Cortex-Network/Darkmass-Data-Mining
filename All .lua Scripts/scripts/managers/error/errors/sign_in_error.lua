local ErrorInterface = require("scripts/managers/error/errors/error_interface")
local ErrorManager = require("scripts/managers/error/error_manager")
local SignInError = class("SignInError")

function SignInError:init(original_error)
	if type(original_error) == "string" then
		self._log_message = original_error
	elseif type(original_error) == "table" then
		self._log_message = table.tostring(original_error, 3)
	end
end

function SignInError:level()
	return ErrorManager.ERROR_LEVEL.error
end

function SignInError:log_message()
	return self._log_message
end

function SignInError:loc_title()
	return "loc_popup_header_signin_error"
end

function SignInError:loc_description()
	local is_xbox_live = IS_XBS or IS_GDK

	if is_xbox_live then
		return "loc_popup_description_signin_error_console"
	else
		return "loc_popup_description_signin_error_win"
	end
end

function SignInError:options()
end

implements(SignInError, ErrorInterface)

return SignInError
