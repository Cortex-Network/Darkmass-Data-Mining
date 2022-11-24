local RemotePlayerGameplay = class("RemotePlayerGameplay")

function RemotePlayerGameplay:init(player, game_state_context)
	self._player = player
	self._is_server = game_state_context.is_server
end

function RemotePlayerGameplay:destroy()
end

function RemotePlayerGameplay:on_reload(refreshed_resources)
end

function RemotePlayerGameplay:update(main_dt, main_t)
	if self._is_server then
		local input_handler = self._player.input_handler

		if input_handler then
			local time_manager = Managers.time
			local game_dt = time_manager:delta_time("gameplay")
			local game_t = time_manager:time("gameplay")

			input_handler:update(game_dt, game_t)
		end
	end
end

function RemotePlayerGameplay:fixed_update(game_dt, game_t, fixed_frame)
	if self._is_server then
		local input_handler = self._player.input_handler

		if input_handler then
			input_handler:fixed_update(game_dt, game_t, fixed_frame)
		end
	end
end

function RemotePlayerGameplay:post_update(main_dt, main_t)
end

function RemotePlayerGameplay:render()
end

return RemotePlayerGameplay
