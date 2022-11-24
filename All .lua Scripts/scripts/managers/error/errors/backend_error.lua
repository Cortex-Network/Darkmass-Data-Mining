local ErrorInterface = require("scripts/managers/error/errors/error_interface")
local ErrorManager = require("scripts/managers/error/error_manager")
local BackendError = class("BackendError")

function BackendError:init(original_error)
	if type(original_error) == "string" then
		self._log_message = original_error
	elseif type(original_error) == "table" then
		self.__traceback = original_error.__traceback
		local max_depth = 3
		self._log_message = table.tostring(original_error, max_depth, true)
	end
end

function BackendError:level()
	return ErrorManager.ERROR_LEVEL.error
end

function BackendError:log_message()
	return self._log_message
end

function BackendError:loc_title()
	return "loc_popup_header_error"
end

function BackendError:loc_description()
	return "loc_popup_description_backend_error"
end

function BackendError:options()
end

implements(BackendError, ErrorInterface)

return BackendError
