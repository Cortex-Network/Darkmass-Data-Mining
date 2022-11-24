local ErrorInterface = require("scripts/managers/error/errors/error_interface")
local SteamOfflineError = class("SteamOfflineError")

function SteamOfflineError:init(is_booting)
	self._is_booting = is_booting
end

function SteamOfflineError:level()
	if self._is_booting then
		return Managers.error.ERROR_LEVEL.fatal
	else
		return Managers.error.ERROR_LEVEL.error
	end
end

function SteamOfflineError:log_message()
	return "No connection to the Steam Network"
end

function SteamOfflineError:loc_title()
	return "loc_popup_header_error"
end

function SteamOfflineError:loc_description()
	return "loc_popup_description_steam_offline_error"
end

function SteamOfflineError:options()
	if not self._is_booting then
		return {
			{
				text = "loc_popup_button_quit_game",
				callback = function ()
					Application.quit()
				end
			}
		}
	end
end

implements(SteamOfflineError, ErrorInterface)

return SteamOfflineError
