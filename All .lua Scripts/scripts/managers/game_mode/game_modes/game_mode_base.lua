local AFKChecker = require("scripts/managers/game_mode/afk_checker")
local BotSpawning = require("scripts/managers/bot/bot_spawning")
local GameModeSettings = require("scripts/settings/game_mode/game_mode_settings")
local GameModeBase = class("GameModeBase")
GameModeBase.INTERFACE = {
	"server_update",
	"complete",
	"fail",
	"evaluate_end_conditions",
	"on_player_unit_spawn",
	"on_player_unit_despawn",
	"can_spawn_player",
	"player_time_until_spawn",
	"cleanup_game_mode_units"
}
local CLIENT_RPCS = {
	"rpc_change_game_mode_state"
}

local function _log(...)
	Log.info("GameModeBase", ...)
end

function GameModeBase:init(game_mode_context, game_mode_name, network_event_delegate)
	self._name = game_mode_name
	self._world = game_mode_context.world
	self._is_server = game_mode_context.is_server
	local settings = GameModeSettings[game_mode_name]
	self._settings = settings
	local states = settings.states
	self._states = states
	self._states_lookup = table.mirror_table(states)
	self._state = states[1]

	if self._is_server then
		local bot_backfilling_allowed = settings.bot_backfilling_allowed
		self._queued_bots_n = 0

		if bot_backfilling_allowed then
			self:_register_bot_events()
			self:_validate_bot_backfill()

			while self._queued_bots_n > 0 do
				self:_handle_bot_spawning()
			end
		end
	else
		network_event_delegate:register_session_events(self, unpack(CLIENT_RPCS))

		self._network_event_delegate = network_event_delegate
	end

	if not DEDICATED_SERVER and settings.cache_local_player_profile then
		local local_player_id = 1
		local player = Managers.player:local_player(local_player_id)
		local player_profile = player:profile()
		self._cached_player_profile = table.clone_instance(player_profile)
	end

	if settings.afk_check then
		self._afk_checker = AFKChecker:new(self._is_server, settings.afk_check, network_event_delegate)
	end
end

function GameModeBase:destroy()
	if self._is_server then
		if self._settings.bot_backfilling_allowed then
			self:_unregister_bot_events()
		end
	else
		self._network_event_delegate:unregister_events(unpack(CLIENT_RPCS))
	end

	local settings = self._settings

	if not DEDICATED_SERVER and settings.cache_local_player_profile then
		local cached_profile = self._cached_player_profile
		local player = Managers.player:local_player(1)

		player:set_profile(cached_profile)
	end

	if self._afk_checker then
		self._afk_checker:delete()

		self._afk_checker = nil
	end
end

function GameModeBase:server_update(dt, t)
	self:_handle_bot_spawning()

	if self._afk_checker then
		self._afk_checker:server_update(dt, t)
	end
end

function GameModeBase:client_update(dt, t)
	if self._afk_checker then
		self._afk_checker:client_update(dt, t)
	end
end

function GameModeBase:name()
	return self._name
end

function GameModeBase:settings()
	return self._settings
end

function GameModeBase:state()
	return self._state
end

function GameModeBase:on_player_unit_spawn(player, unit, is_respawn)
end

function GameModeBase:on_player_unit_despawn(player)
end

function GameModeBase:can_spawn_player(player)
	return true
end

function GameModeBase:player_time_until_spawn(player)
	return nil
end

function GameModeBase:cleanup_game_mode_units()
	local bot_backfilling_allowed = self._settings.bot_backfilling_allowed

	if bot_backfilling_allowed then
		self:_remove_all_bots()
	end
end

function GameModeBase:_remove_all_bots()
	local bot_manager = Managers.bot
	local bot_synchronizer_host = bot_manager:synchronizer_host()

	if bot_synchronizer_host then
		local bot_ids = bot_synchronizer_host:active_bot_ids()

		for local_player_id, _ in pairs(bot_ids) do
			bot_synchronizer_host:remove_bot(local_player_id)
		end
	end
end

function GameModeBase:_change_state(new_state)
	local old_state = self._state

	_log("[_change_state] Switching game mode state from %q to %q", old_state, new_state)
	self:_game_mode_state_changed(new_state, old_state)

	self._state = new_state

	if self._is_server then
		local new_state_id = self._states_lookup[new_state]

		Managers.state.game_session:send_rpc_clients("rpc_change_game_mode_state", new_state_id)
	end
end

function GameModeBase:_game_mode_state_changed(new_state, old_state)
end

function GameModeBase:rpc_change_game_mode_state(channel_id, new_state_id)
	local new_state = self._states_lookup[new_state_id]

	self:_change_state(new_state)
end

function GameModeBase:hot_join_sync(sender, channel)
	local state_id = self._states_lookup[self._state]

	if state_id ~= 1 then
		RPC.rpc_change_game_mode_state(channel, state_id)
	end
end

function GameModeBase:_register_bot_events()
	Managers.event:register(self, "host_game_session_manager_player_joined", "_on_client_joined")
	Managers.event:register(self, "multiplayer_session_client_disconnected", "_on_client_left")
end

function GameModeBase:_unregister_bot_events()
	Managers.event:unregister(self, "host_game_session_manager_player_joined")
	Managers.event:unregister(self, "multiplayer_session_client_disconnected")
end

function GameModeBase:_validate_bot_backfill()
	local available_slots = self:_num_available_bot_slots()

	if available_slots < 0 then
		for ii = 0, available_slots + 1, -1 do
			if self._queued_bots_n > 0 then
				self._queued_bots_n = self._queued_bots_n - 1
			else
				BotSpawning.despawn_best_bot()
			end
		end
	elseif available_slots > 0 then
		self._queued_bots_n = self._queued_bots_n + available_slots
	end
end

function GameModeBase:_on_client_joined(peer_id)
	local players_at_peer = Managers.player:players_at_peer(peer_id)
	local num_players_joining = table.size(players_at_peer)
	local available_slots = self:_num_available_bot_slots()
	local bots_to_remove = math.min(num_players_joining, -available_slots)

	for i = 1, bots_to_remove do
		if self._queued_bots_n > 0 then
			self._queued_bots_n = self._queued_bots_n - 1
		else
			BotSpawning.despawn_best_bot()
		end
	end
end

function GameModeBase:_on_client_left(removed_players_data)
	if not Managers.bot then
		return
	end

	local available_slots = self:_num_available_bot_slots()
	local num_players_leaving = #removed_players_data
	local bots_to_add = math.min(available_slots, num_players_leaving)
	self._queued_bots_n = self._queued_bots_n + bots_to_add
end

function GameModeBase:_num_available_bot_slots()
	local bot_backfilling_allowed = self._settings.bot_backfilling_allowed
	local max_players = GameParameters.max_players
	local num_players = Managers.player:num_ready_human_players()
	local bot_synchronizer_host = Managers.bot:synchronizer_host()
	local max_bots = bot_backfilling_allowed and self._settings.max_bots or 0
	local num_bots = bot_synchronizer_host:num_bots() + self._queued_bots_n
	local desired_bot_count = max_players - num_players
	desired_bot_count = math.clamp(desired_bot_count, 0, max_bots)

	return desired_bot_count - num_bots
end

function GameModeBase:_handle_bot_spawning()
	if self._queued_bots_n > 0 then
		local profile_id = math.random(1, 6)
		local profile_name = "bot_" .. profile_id

		BotSpawning.spawn_bot_character(profile_name)

		self._queued_bots_n = self._queued_bots_n - 1
	end
end

function GameModeBase:_cinematic_active()
	if Managers.state.cinematic:active() then
		return true
	end

	local cinematic_scene_system = Managers.state.extension:system("cinematic_scene_system")

	return cinematic_scene_system:is_active()
end

function GameModeBase:should_spawn_dead(player)
	return false
end

return GameModeBase
