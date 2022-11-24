local ErrorInterface = require("scripts/managers/error/errors/error_interface")
local ErrorManager = require("scripts/managers/error/error_manager")
local TestError = class("TestError")

function TestError:init(error_level_name)
	self._error_level_name = error_level_name
end

function TestError:level()
	return ErrorManager.ERROR_LEVEL[self._error_level_name]
end

function TestError:log_message()
	return "Some log message..."
end

function TestError:loc_title()
	return "loc_popup_header_error"
end

function TestError:loc_description()
	return "loc_error_reason", {
		error_reason = string.format("I'm an error, level %q", self._error_level_name)
	}
end

implements(TestError, ErrorInterface)

return TestError
