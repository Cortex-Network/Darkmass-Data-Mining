local ErrorInterface = require("scripts/managers/error/errors/error_interface")
local ErrorManager = require("scripts/managers/error/error_manager")
local LoadMissionError = class("LoadMissionError")

function LoadMissionError:init(mission_name)
	self._mission_name = mission_name
end

function LoadMissionError:level()
	return ErrorManager.ERROR_LEVEL.error
end

function LoadMissionError:log_message()
	return string.format("Failed to load mission %s", self._mission_name)
end

function LoadMissionError:loc_title()
	return "loc_popup_header_error"
end

function LoadMissionError:loc_description()
	return "loc_popup_description_load_mission_error"
end

function LoadMissionError:options()
end

implements(LoadMissionError, ErrorInterface)

return LoadMissionError
