local ErrorCodes = require("scripts/managers/error/error_codes")
local ErrorInterface = require("scripts/managers/error/errors/error_interface")
local ErrorManager = require("scripts/managers/error/error_manager")
local MultiplayerSessionBootError = class("MultiplayerSessionBootError")

function MultiplayerSessionBootError:init(error_source, error_reason, optional_error_details)
	self._error_reason = error_reason
	local error_details = "n/a"

	if optional_error_details then
		if type(optional_error_details) == "table" then
			error_details = table.tostring(optional_error_details, 3)
		else
			error_details = optional_error_details
		end
	end

	self._log_message = string.format("source: %s, reason: %s, error_details: %s", error_source, error_reason, error_details)
end

function MultiplayerSessionBootError:level()
	return ErrorManager.ERROR_LEVEL.warning
end

function MultiplayerSessionBootError:log_message()
	return self._log_message
end

function MultiplayerSessionBootError:loc_title()
	return "loc_failed_joining_server"
end

function MultiplayerSessionBootError:loc_description()
	local error_code_string = ErrorCodes.get_error_code_string_from_reason(self._error_reason)
	local string_format = "%s %s"

	return "loc_error_reason", {
		error_reason = error_code_string
	}, string_format
end

function MultiplayerSessionBootError:options()
end

implements(MultiplayerSessionBootError, ErrorInterface)

return MultiplayerSessionBootError
