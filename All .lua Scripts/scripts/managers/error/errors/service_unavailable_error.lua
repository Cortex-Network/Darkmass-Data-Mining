local ErrorInterface = require("scripts/managers/error/errors/error_interface")
local ErrorManager = require("scripts/managers/error/error_manager")
local ServiceUnavailableError = class("ServiceUnavailableError")

function ServiceUnavailableError:init(original_error)
	if type(original_error) == "string" then
		self._log_message = original_error
	elseif type(original_error) == "table" then
		self._log_message = table.tostring(original_error, 3)
	end
end

function ServiceUnavailableError:level()
	return ErrorManager.ERROR_LEVEL.error
end

function ServiceUnavailableError:log_message()
	return self._log_message
end

function ServiceUnavailableError:loc_title()
	return "loc_popup_header_service_unavailable_error"
end

function ServiceUnavailableError:loc_description()
	if IS_XBS or IS_GDK then
		return "loc_popup_description_service_unavailable_console"
	else
		return "loc_popup_description_service_unavailable_win"
	end
end

function ServiceUnavailableError:options()
end

implements(ServiceUnavailableError, ErrorInterface)

return ServiceUnavailableError
