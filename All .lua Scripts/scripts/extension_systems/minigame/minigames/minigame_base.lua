local MinigameBase = class("MinigameBase")

function MinigameBase:init(unit, is_server, seed, context)
	self._minigame_unit = unit
	self._is_server = is_server
	self._seed = seed
	self._player_session_id = nil
end

function MinigameBase:destroy()
end

function MinigameBase:hot_join_sync(sender, channel)
end

function MinigameBase:start(player_or_nil)
	self._player_session_id = player_or_nil and player_or_nil:session_id()
end

function MinigameBase:stop()
	self._player_session_id = nil
end

function MinigameBase:is_completed()
	return false
end

function MinigameBase:setup_game()
end

function MinigameBase:on_action_pressed(t)
end

return MinigameBase
