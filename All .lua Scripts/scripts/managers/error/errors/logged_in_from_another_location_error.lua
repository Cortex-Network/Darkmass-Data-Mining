local ErrorInterface = require("scripts/managers/error/errors/error_interface")
local ErrorManager = require("scripts/managers/error/error_manager")
local LoggedInFromAnotherLocationError = class("LoggedInFromAnotherLocationError")

function LoggedInFromAnotherLocationError:init()
end

function LoggedInFromAnotherLocationError:level()
	return ErrorManager.ERROR_LEVEL.fatal
end

function LoggedInFromAnotherLocationError:log_message()
	return "Logged in from another location, need to close application."
end

function LoggedInFromAnotherLocationError:loc_title()
	return "loc_popup_header_logged_in_another_location_error"
end

function LoggedInFromAnotherLocationError:loc_description()
	return "loc_popup_description_logged_in_another_location_error"
end

function LoggedInFromAnotherLocationError:options()
end

implements(LoggedInFromAnotherLocationError, ErrorInterface)

return LoggedInFromAnotherLocationError
