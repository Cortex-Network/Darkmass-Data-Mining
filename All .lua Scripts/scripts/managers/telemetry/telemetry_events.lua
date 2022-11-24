local TelemetryEvent = require("scripts/managers/telemetry/telemetry_event")
local TelemetrySettings = require("scripts/managers/telemetry/telemetry_settings")
local TelemetryHelper = require("scripts/managers/telemetry/telemetry_helper")
local MatchmakingConstants = require("scripts/settings/network/matchmaking_constants")
local HOST_TYPES = MatchmakingConstants.HOST_TYPES
local TelemetryEvents = class("TelemetryEvents")
local RPCS = {
	"rpc_sync_server_session_id"
}
local SOURCE = table.remove_empty_values(TelemetrySettings.source)

function TelemetryEvents:init(telemetry_manager, connection_manager)
	self._manager = telemetry_manager
	self._connection_manager = connection_manager
	self._subject = {}

	if GameParameters.testify then
		self._subject = {
			machine_id = Application.machine_id(),
			machine_name = string.value_or_nil(GameParameters.machine_name)
		}
	end

	self._session = {
		game = Application.guid()
	}

	if not DEDICATED_SERVER then
		self._connection_manager:network_event_delegate():register_connection_events(self, unpack(RPCS))
	end

	if Wwise.set_starvation_callback then
		Wwise.set_starvation_callback(function (event_name, object_name, error_code)
			self:on_wwise_starvation(event_name, object_name, error_code)
		end)
	end

	self._context = {}

	self:game_startup()
end

function TelemetryEvents:destroy()
	if not DEDICATED_SERVER then
		self._connection_manager:network_event_delegate():unregister_events(unpack(RPCS))
	end

	self:game_shutdown()
end

function TelemetryEvents:on_wwise_starvation(event_name, object_name, error_code)
	local event = self:_create_event("wwise_source_starvation")

	event:set_data({
		event_name = event_name,
		object_name = object_name,
		error_code = error_code
	})
	self._manager:register_event(event)
end

function TelemetryEvents:rpc_sync_server_session_id(channel_id, session_id)
	if self._connection_manager:host_type() == HOST_TYPES.mission_server then
		self._session.gameplay = session_id
	end

	for _, player in pairs(Managers.player:players_at_peer(Network.peer_id())) do
		self:client_connected(player)
	end
end

function TelemetryEvents:client_connected(player)
	local event = TelemetryEvent:new(SOURCE, player:telemetry_subject(), "client_connected", {
		game = player:telemetry_game_session(),
		gameplay = self._session.gameplay
	})

	event:set_data({
		auth_platform = Managers.presence:presence_entry_myself():platform()
	})
	self._manager:register_event(event)

	if self._connection_manager:host_type() == HOST_TYPES.mission_server then
		self:player_inventory(player)
	end
end

function TelemetryEvents:player_inventory(player)
	local profile = player:profile()
	local item_data = profile and profile.loadout_item_data or {}
	local event = TelemetryEvent:new(SOURCE, player:telemetry_subject(), "player_inventory", {
		game = player:telemetry_game_session(),
		gameplay = self._session.gameplay
	})

	event:set_data(item_data)
	self._manager:register_event(event)
end

function TelemetryEvents:client_disconnected(player, info)
	local event = TelemetryEvent:new(SOURCE, player:telemetry_subject(), "client_disconnected", {
		game = player:telemetry_game_session(),
		gameplay = self._session.gameplay
	})

	event:set_data({
		info = info
	})
	self._manager:register_event(event)
end

function TelemetryEvents:game_startup()
	local event = self:_create_event("game_startup")

	self._manager:register_event(event)
end

function TelemetryEvents:game_shutdown()
	local event = self:_create_event("game_shutdown")

	event:set_data({
		time_in_game = Application.time_since_launch()
	})
	self._manager:register_event(event)
end

function TelemetryEvents:_create_event(type)
	return TelemetryEvent:new(SOURCE, self._subject, type, self._session)
end

function TelemetryEvents:mission_session_started(session_id, map)
	self._session.gameplay = session_id
	self._context.map = map
	local event = self:_create_event("mission_session_started")

	self._manager:register_event(event)
end

function TelemetryEvents:hub_session_started(session_id)
	self._session.gameplay = session_id
	local event = self:_create_event("hub_session_started")

	self._manager:register_event(event)
end

function TelemetryEvents:gameplay_started(params)
	self._context.host_type = params.host_type
	self._context.map = params.mission_name

	if params.host_type == HOST_TYPES.singleplay or params.host_type == HOST_TYPES.hub_server then
		self._session.gameplay = Application.guid()
	end

	local event = self:_create_event("gameplay_started")

	event:set_data({
		map = self._context.map,
		host_type = self._context.host_type
	})
	self._manager:register_event(event)
	Managers.telemetry_reporters:start_reporter("com_wheel")
	Managers.telemetry_reporters:start_reporter("combat_ability")
	Managers.telemetry_reporters:start_reporter("enemy_spawns")
	Managers.telemetry_reporters:start_reporter("frame_time", params)
	Managers.telemetry_reporters:start_reporter("grenade_ability")
	Managers.telemetry_reporters:start_reporter("pacing")
	Managers.telemetry_reporters:start_reporter("picked_items")
	Managers.telemetry_reporters:start_reporter("ping", params)
	Managers.telemetry_reporters:start_reporter("placed_items")
	Managers.telemetry_reporters:start_reporter("player_dealt_damage")
	Managers.telemetry_reporters:start_reporter("player_taken_damage")
	Managers.telemetry_reporters:start_reporter("shared_items")
	Managers.telemetry_reporters:start_reporter("smart_tag")
end

function TelemetryEvents:gameplay_stopped()
	Managers.telemetry_reporters:stop_reporter("smart_tag")
	Managers.telemetry_reporters:stop_reporter("shared_items")
	Managers.telemetry_reporters:stop_reporter("player_taken_damage")
	Managers.telemetry_reporters:stop_reporter("player_dealt_damage")
	Managers.telemetry_reporters:stop_reporter("placed_items")
	Managers.telemetry_reporters:stop_reporter("ping")
	Managers.telemetry_reporters:stop_reporter("picked_items")
	Managers.telemetry_reporters:stop_reporter("pacing")
	Managers.telemetry_reporters:stop_reporter("grenade_ability")
	Managers.telemetry_reporters:stop_reporter("frame_time")
	Managers.telemetry_reporters:stop_reporter("enemy_spawns")
	Managers.telemetry_reporters:stop_reporter("combat_ability")
	Managers.telemetry_reporters:stop_reporter("com_wheel")

	local event = self:_create_event("gameplay_stopped")

	event:set_data({
		map = self._context.map,
		host_type = self._context.host_type
	})
	self._manager:register_event(event)

	self._session.gameplay = nil
	self._context.map = nil
end

function TelemetryEvents:player_authenticated(account)
	self._subject.account_id = string.value_or_nil(account.sub)
	local event = self:_create_event("player_authenticated")

	self._manager:register_event(event)
end

function TelemetryEvents:local_player_spawned(player)
	self._subject.account_id = player:account_id()
	self._subject.character_id = player:character_id()
end

function TelemetryEvents:system_settings(account_id)
	local fullscreen = Application.user_setting("fullscreen")
	local borderless_fullscreen = Application.user_setting("borderless_fullscreen")
	local windowed = not fullscreen and not borderless_fullscreen
	local screen_mode = fullscreen and "fullscreen" or borderless_fullscreen and "borderless_fullscreen" or windowed and "windowed"
	local master_render_settings = Application.user_setting("master_render_settings")
	local video_settings = {
		resolution = string.format("%dx%d", Application.back_buffer_size()),
		screen_mode = screen_mode,
		adapter_index = Application.user_setting("adapter_index")
	}

	if master_render_settings then
		video_settings.master_render_settings = master_render_settings
		video_settings.render_settings = Application.user_setting("render_settings") or {}
		video_settings.performance_settings = Application.user_setting("performance_settings") or {}
		video_settings.render_api = Renderer.render_device_string()
		video_settings.vsync = Application.user_setting("vsync")
	end

	local sound_settings = Application.user_setting("sound_settings")
	local account_data = Managers.save:account_data(account_id)
	local language = Managers.localization:language()
	local event = self:_create_event("system_settings")

	event:set_data({
		system = Application.sysinfo(),
		video_settings = video_settings,
		sound_settings = sound_settings,
		interface_settings = account_data.interface_settings,
		input_settings = account_data.input_settings,
		language = language
	})
	event:set_revision(2)
	self._manager:register_event(event)
end

function TelemetryEvents:heartbeat()
	local event = self:_create_event("heartbeat")

	self._manager:register_event(event)
end

function TelemetryEvents:start_terror_event(event_name)
	local event = self:_create_event("start_terror_event")

	event:set_data({
		name = event_name
	})
	self._manager:register_event(event)
end

function TelemetryEvents:stop_terror_event(event_name)
	local event = self:_create_event("stop_terror_event")

	event:set_data({
		name = event_name
	})
	self._manager:register_event(event)
end

function TelemetryEvents:player_dealt_damage_report(reports)
	for _, report in pairs(reports) do
		local entries = report.entries
		local player_data = report.player_data
		local event = TelemetryEvent:new(SOURCE, player_data.telemetry_subject, "player_dealt_damage_report", {
			game = player_data.telemetry_game_session,
			gameplay = self._session.gameplay
		})

		event:set_data(entries)
		self._manager:register_event(event)
	end
end

function TelemetryEvents:player_taken_damage_report(reports)
	for _, report in pairs(reports) do
		local entries = report.entries
		local player_data = report.player_data
		local event = TelemetryEvent:new(SOURCE, player_data.telemetry_subject, "player_taken_damage_report", {
			game = player_data.telemetry_game_session,
			gameplay = self._session.gameplay
		})

		event:set_data(entries)
		self._manager:register_event(event)
	end
end

function TelemetryEvents:player_killed_enemy(player, data)
	local event = TelemetryEvent:new(SOURCE, player:telemetry_subject(), "player_killed_enemy", {
		game = player:telemetry_game_session(),
		gameplay = self._session.gameplay
	})

	event:set_data(data)
	self._manager:register_event(event)
end

function TelemetryEvents:player_knocked_down(player, data)
	data.coherency = TelemetryHelper.unit_coherency(player.player_unit)
	data.chunk = TelemetryHelper.chunk_at_unit(player.player_unit)

	if data.reason ~= "damage" then
		data.victim_position = TelemetryHelper.unit_position(player.player_unit)
	end

	local event = TelemetryEvent:new(SOURCE, player:telemetry_subject(), "player_knocked_down", {
		game = player:telemetry_game_session(),
		gameplay = self._session.gameplay
	})

	event:set_data(data)
	self._manager:register_event(event)
end

function TelemetryEvents:player_died(player, data)
	local reason = data.reason or ""

	if reason == "player_unit_despawned" then
		Log.debug("TelemetryEvents", "Skipping 'player_died' event due to reason = '%s'", reason)

		return
	end

	local damage_profile = data.damage_profile or ""

	if damage_profile == "kill_volume_and_ofF_navmesh" then
		Log.debug("TelemetryEvents", "Skipping 'player_died' event due to damage profile = '%s'", damage_profile)

		return
	end

	data.coherency = TelemetryHelper.unit_coherency(player.player_unit)
	data.chunk = TelemetryHelper.chunk_at_unit(player.player_unit)

	if data.reason ~= "damage" then
		data.victim_position = TelemetryHelper.unit_position(player.player_unit)
	end

	local event = TelemetryEvent:new(SOURCE, player:telemetry_subject(), "player_died", {
		game = player:telemetry_game_session(),
		gameplay = self._session.gameplay
	})

	event:set_data(data)
	self._manager:register_event(event)
end

function TelemetryEvents:player_revived_ally(reviver_player, revivee_player, reviver_position, revivee_position, state_name)
	local event = TelemetryEvent:new(SOURCE, reviver_player:telemetry_subject(), "player_revived_ally", {
		game = reviver_player:telemetry_game_session(),
		gameplay = self._session.gameplay
	})

	event:set_data({
		revivee = revivee_player:telemetry_subject(),
		reviver_position = reviver_position,
		revivee_position = revivee_position,
		type = state_name
	})
	self._manager:register_event(event)
end

function TelemetryEvents:player_exits_captivity(player, rescued_by_player, state_name, time_in_captivity)
	local event = TelemetryEvent:new(SOURCE, player:telemetry_subject(), "player_exits_captivity", {
		game = player:telemetry_game_session(),
		gameplay = self._session.gameplay
	})

	event:set_data({
		rescued_by_player = rescued_by_player,
		time_in_captivity = time_in_captivity,
		type = state_name
	})
	self._manager:register_event(event)
end

function TelemetryEvents:player_combat_ability_report(reports)
	for _, report in pairs(reports) do
		local entries = report.entries
		local player_data = report.player_data
		local event = TelemetryEvent:new(SOURCE, player_data.telemetry_subject, "player_combat_ability_report", {
			game = player_data.telemetry_game_session,
			gameplay = self._session.gameplay
		})

		event:set_data(entries)
		self._manager:register_event(event)
	end
end

function TelemetryEvents:player_grenade_ability_report(reports)
	for _, report in pairs(reports) do
		local entries = report.entries
		local player_data = report.player_data
		local event = TelemetryEvent:new(SOURCE, player_data.telemetry_subject, "player_grenade_ability_report", {
			game = player_data.telemetry_game_session,
			gameplay = self._session.gameplay
		})

		event:set_data(entries)
		self._manager:register_event(event)
	end
end

function TelemetryEvents:player_hacked_terminal(player, mistakes)
	local event = TelemetryEvent:new(SOURCE, player:telemetry_subject(), "player_hacked_terminal", {
		game = player:telemetry_game_session(),
		gameplay = self._session.gameplay
	})

	event:set_data({
		mistakes = mistakes
	})
	self._manager:register_event(event)
end

function TelemetryEvents:player_scanned_objects(player, objects)
	local event = TelemetryEvent:new(SOURCE, player:telemetry_subject(), "player_scanned_objects", {
		game = player:telemetry_game_session(),
		gameplay = self._session.gameplay
	})

	event:set_data({
		objects = objects
	})
	self._manager:register_event(event)
end

function TelemetryEvents:player_started_objective(player, objective)
	local event = TelemetryEvent:new(SOURCE, player:telemetry_subject(), "player_started_objective", {
		game = player:telemetry_game_session(),
		gameplay = self._session.gameplay
	})

	event:set_data({
		objective = objective
	})
	self._manager:register_event(event)
end

function TelemetryEvents:player_completed_objective(player, objective)
	local event = TelemetryEvent:new(SOURCE, player:telemetry_subject(), "player_completed_objective", {
		game = player:telemetry_game_session(),
		gameplay = self._session.gameplay
	})

	event:set_data({
		objective = objective
	})
	self._manager:register_event(event)
end

function TelemetryEvents:boss_encounter_started(breed)
	local event = self:_create_event("boss_encounter_started")

	event:set_data({
		breed = breed
	})
	self._manager:register_event(event)
end

function TelemetryEvents:picked_items_report(reports)
	for player, report in pairs(reports) do
		local entries = report.entries
		local player_data = report.player_data
		local event = TelemetryEvent:new(SOURCE, player_data.telemetry_subject, "picked_items_report", {
			game = player_data.telemetry_game_session,
			gameplay = self._session.gameplay
		})

		event:set_data(entries)
		self._manager:register_event(event)
	end
end

function TelemetryEvents:placed_items_report(reports)
	for player, report in pairs(reports) do
		local entries = report.entries
		local player_data = report.player_data
		local event = TelemetryEvent:new(SOURCE, player_data.telemetry_subject, "placed_items_report", {
			game = player_data.telemetry_game_session,
			gameplay = self._session.gameplay
		})

		event:set_data(entries)
		self._manager:register_event(event)
	end
end

function TelemetryEvents:shared_items_report(reports)
	for player, report in pairs(reports) do
		local entries = report.entries
		local player_data = report.player_data
		local event = TelemetryEvent:new(SOURCE, player_data.telemetry_subject, "shared_items_report", {
			game = player_data.telemetry_game_session,
			gameplay = self._session.gameplay
		})

		event:set_data(entries)
		self._manager:register_event(event)
	end
end

function TelemetryEvents:vo_event_triggered(global_context, player_context, event_name, vo_rule, vo_profile_name, vo_category_name, resistance, challenge)
	local event = self:_create_event("vo_event_triggered")
	local data = {
		mission = {
			name = global_context.current_mission,
			time = global_context.level_time,
			challenge = challenge,
			resistance = resistance,
			pacing_tension = global_context.pacing_tension,
			active_hordes = global_context.active_hordes
		},
		vo = {
			event_name = event_name,
			rule = vo_rule,
			profile_name = vo_profile_name,
			category_name = vo_category_name
		}
	}

	if player_context.is_player == "true" then
		data.player = {
			health = player_context.health,
			friends_close = player_context.friends_close,
			enemies_close = player_context.enemies_close,
			is_knocked_down = player_context.is_knocked_down == "true",
			is_pounced_down = player_context.is_pounced_down == "true",
			is_ledge_hanging = player_context.is_ledge_hanging == "true"
		}
	end

	event:set_data(data)
	self._manager:register_event(event)
end

function TelemetryEvents:vo_bank_reshuffled(character_name, bank_name)
	local event = self:_create_event("vo_bank_reshuffled")

	event:set_data({
		mission = {
			name = self._context.map
		},
		character_name = character_name,
		bank_name = bank_name
	})
	self._manager:register_event(event)
end

function TelemetryEvents:camera_performance_measurements(map, camera, measurements)
	local event = self:_create_event("performance_static_camera_measurements")

	event:set_data({
		map = map,
		camera_id = camera.id_string,
		camera_name = camera.name,
		go_to_camera_position_link = camera.go_to_camera_position_link,
		ms_per_frame = measurements.ms_per_frame,
		batchcount = measurements.batchcount,
		primitives_count = measurements.primitives_count
	})
	self._manager:register_event(event)
end

function TelemetryEvents:performance_measurements(map, measurements)
	local event = self:_create_event("performance_measurements")

	event:set_data({
		map = map,
		ms_per_frame = measurements.ms_per_frame,
		batchcount = measurements.batchcount,
		primitives_count = measurements.primitives_count
	})
	self._manager:register_event(event)
end

local BLACKLISTED_VIEWS = TelemetrySettings.blacklisted_views

function TelemetryEvents:open_view(view_name)
	if table.array_contains(BLACKLISTED_VIEWS, view_name) then
		return
	end

	local event = self:_create_event("open_view")

	event:set_data({
		name = view_name
	})
	self._manager:register_event(event)
end

function TelemetryEvents:close_view(view_name)
	if table.array_contains(BLACKLISTED_VIEWS, view_name) then
		return
	end

	local event = self:_create_event("close_view")

	event:set_data({
		name = view_name
	})
	self._manager:register_event(event)
end

function TelemetryEvents:end_cutscene(cinematics_name, cinematic_scene_name, percent_viewed, character_level)
	local event = self:_create_event("cutscene_ended")

	event:set_data({
		cinematics_name = cinematics_name,
		cinematic_scene_name = cinematic_scene_name,
		percent_viewed = percent_viewed,
		character_level = character_level
	})
	self._manager:register_event(event)
end

function TelemetryEvents:memory_usage(map, index, memory_usage)
	local event = self:_create_event("performance_memory_usage")

	event:set_data({
		map = map,
		index = index,
		memory_usage = memory_usage
	})
	self._manager:register_event(event)
end

function TelemetryEvents:performance_load_times(map, wait_for_network_time, resource_load_time, mission_intro_time, wait_for_spawn_time)
	local event = self:_create_event("performance_load_times")

	event:set_data({
		map = map,
		wait_for_network_time = wait_for_network_time,
		resource_load_time = resource_load_time,
		mission_intro_time = mission_intro_time,
		wait_for_spawn_time = wait_for_spawn_time
	})
	self._manager:register_event(event)
end

function TelemetryEvents:lua_trace_stats(map, index, lua_trace_stats)
	local event = self:_create_event("lua_trace_stats")

	event:set_data({
		map = map,
		index = index,
		total_offenders = lua_trace_stats.total_offenders,
		total_allocs = lua_trace_stats.total_allocs,
		total_bytes = lua_trace_stats.total_bytes
	})
	self._manager:register_event(event)
end

function TelemetryEvents:performance_frame_time(avg, std_dev, p99, p95, p90, p75, p50, p25, observations, map_name)
	local event = self:_create_event("performance_frame_time")

	event:set_data({
		avg = avg,
		std_dev = std_dev,
		p99 = p99,
		p95 = p95,
		p90 = p90,
		p75 = p75,
		p50 = p50,
		p25 = p25,
		observations = observations,
		map_name = map_name
	})
	self._manager:register_event(event)
end

function TelemetryEvents:performance_ping(avg, std_dev, p99, p95, p90, p75, p50, p25, observations, region, map_name)
	local event = self:_create_event("performance_ping")

	event:set_data({
		avg = avg,
		std_dev = std_dev,
		p99 = p99,
		p95 = p95,
		p90 = p90,
		p75 = p75,
		p50 = p50,
		p25 = p25,
		observations = observations,
		region = region,
		map_name = map_name
	})
	self._manager:register_event(event)
end

function TelemetryEvents:character_creation_time(character_id, time)
	self._subject.character_id = character_id
	local event = TelemetryEvent:new(SOURCE, {
		account_id = self._subject.account_id,
		character_id = character_id
	}, "character_creation_time", self._session)

	event:set_data({
		time = time
	})
	self._manager:register_event(event)
end

function TelemetryEvents:record_slow_response_time(path, response_time)
	local event = self:_create_event("slow_backend_response")

	event:set_data({
		response_time = response_time,
		path = path
	})
	self._manager:register_event(event)
end

function TelemetryEvents:pacing(tension)
	local event = self:_create_event("pacing")

	event:set_data({
		tension = tension
	})
	self._manager:register_event(event)
end

function TelemetryEvents:enemies_spawned_report(report)
	local event = self:_create_event("enemies_spawned_report")

	event:set_data(report)
	self._manager:register_event(event)
end

function TelemetryEvents:com_wheel_report(report)
	local event = self:_create_event("com_wheel_report")

	event:set_data(report)
	self._manager:register_event(event)
end

function TelemetryEvents:smart_tag_report(reports)
	for player, report in pairs(reports) do
		local entries = report.entries
		local player_data = report.player_data
		local event = TelemetryEvent:new(SOURCE, player_data.telemetry_subject, "smart_tag_report", {
			game = player_data.telemetry_game_session,
			gameplay = self._session.gameplay
		})

		event:set_data(entries)
		self._manager:register_event(event)
	end
end

function TelemetryEvents:vote_completed(name, result, votes)
	local event = self:_create_event("vote_completed")

	event:set_data({
		name = name,
		result = result,
		votes = votes
	})
	self._manager:register_event(event)
end

function TelemetryEvents:training_grounds_completed(start_type, finish_type, user_quit, is_onboarding, duration, finish_scenario, num_scenarios_started)
	local event = self:_create_event("training_grounds_completed")

	event:set_data({
		start_type = start_type,
		finish_type = finish_type,
		finish_scenario = finish_scenario,
		num_scenarios_started = num_scenarios_started,
		user_quit = user_quit,
		is_onboarding = is_onboarding,
		duration = duration
	})
	self._manager:register_event(event)
end

function TelemetryEvents:chat_message_sent(message_body)
	local event = self:_create_event("chat_message_sent")

	event:set_data({
		message_length = message_body:len()
	})
	self._manager:register_event(event)
end

return TelemetryEvents
