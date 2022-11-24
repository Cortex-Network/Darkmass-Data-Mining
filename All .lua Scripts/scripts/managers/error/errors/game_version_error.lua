local ErrorInterface = require("scripts/managers/error/errors/error_interface")
local ErrorManager = require("scripts/managers/error/error_manager")
local GameVersionError = class("GameVersionError")

function GameVersionError:init(original_error)
	if type(original_error) == "string" then
		self._log_message = original_error
	elseif type(original_error) == "table" then
		self._log_message = table.tostring(original_error, 3)
	end
end

function GameVersionError:level()
	return ErrorManager.ERROR_LEVEL.fatal
end

function GameVersionError:log_message()
	return self._log_message
end

function GameVersionError:loc_title()
	return "loc_popup_header_wrong_game_version"
end

function GameVersionError:loc_description()
	if PLATFORM == "win32" then
		return "loc_popup_description_wrong_game_version_win"
	else
		return "loc_popup_description_wrong_game_version_console"
	end
end

function GameVersionError:options()
end

implements(GameVersionError, ErrorInterface)

return GameVersionError
