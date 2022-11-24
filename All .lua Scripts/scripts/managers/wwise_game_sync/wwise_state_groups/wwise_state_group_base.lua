local WwiseGameSyncSettings = require("scripts/settings/wwise_game_sync/wwise_game_sync_settings")
local WwiseStateGroupBase = class("WwiseStateGroupBase")

function WwiseStateGroupBase:init(wwise_world, wwise_state_group_name)
	self._wwise_world = wwise_world
	self._wwise_state_group_name = wwise_state_group_name
	self._current_wwise_state = WwiseGameSyncSettings.default_group_state
	self._game_state_machine = nil
	self._player_unit = nil
end

function WwiseStateGroupBase:destroy()
end

function WwiseStateGroupBase:update(dt, t)
end

function WwiseStateGroupBase:_set_wwise_state(state)
	self._current_wwise_state = state
end

function WwiseStateGroupBase:wwise_state()
	return self._current_wwise_state
end

function WwiseStateGroupBase:set_game_state_machine(game_state_machine)
	self._game_state_machine = game_state_machine
end

function WwiseStateGroupBase:get_game_state_machine()
	return self._game_state_machine
end

function WwiseStateGroupBase:on_gameplay_post_init(level)
end

function WwiseStateGroupBase:on_gameplay_shutdown()
end

function WwiseStateGroupBase:set_followed_player_unit(player_unit)
	self._player_unit = player_unit
end

return WwiseStateGroupBase
