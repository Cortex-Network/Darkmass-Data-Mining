local CircumstanceTemplates = require("scripts/settings/circumstance/circumstance_templates")
local DialogueBreedSettings = require("scripts/settings/dialogue/dialogue_breed_settings")
local DialogueCategoryConfig = require("scripts/settings/dialogue/dialogue_category_config")
local DialogueEventQueue = require("scripts/extension_systems/dialogue/dialogue_event_queue")
local DialogueExtension = require("scripts/extension_systems/dialogue/dialogue_extension")
local DialogueLookupContexts = require("scripts/settings/dialogue/dialogue_lookup_contexts")
local DialogueQueryQueue = require("scripts/extension_systems/dialogue/dialogue_query_queue")
local DialogueSettings = require("scripts/settings/dialogue/dialogue_settings")
local DialogueStateHandler = require("scripts/extension_systems/dialogue/dialogue_state_handler")
local DialogueSystemSubtitle = require("scripts/extension_systems/dialogue/dialogue_system_subtitle")
local DialogueSystemTestify = GameParameters.testify and require("scripts/extension_systems/dialogue/dialogue_system_testify")
local DialogueSystemWwise = require("scripts/extension_systems/dialogue/dialogue_system_wwise")
local FunctionCommandQueue = require("scripts/extension_systems/dialogue/utils/function_command_queue")
local NetworkLookup = require("scripts/network_lookup/network_lookup")
local TagQuery = require("scripts/extension_systems/dialogue/tag_query")
local TagQueryDatabase = require("scripts/extension_systems/dialogue/tag_query_database")
local TagQueryLoader = require("scripts/extension_systems/dialogue/tag_query_loader")
local Vo = require("scripts/utilities/vo")
local WwiseRouting = require("scripts/settings/dialogue/wwise_vo_routing_settings")
local RPCS = {
	"rpc_interrupt_dialogue_event",
	"rpc_trigger_dialogue_event",
	"rpc_play_dialogue_event",
	"rpc_dialogue_system_joined",
	"rpc_player_select_voice_server",
	"rpc_player_select_voice",
	"rpc_set_dynamic_smart_tag"
}
local extensions = {
	"DialogueActorExtension"
}
local DialogueSystem = class("DialogueSystem", "ExtensionSystemBase")

function DialogueSystem:init(extension_system_creation_context, system_init_data, system_name)
	local extension_manager = extension_system_creation_context.extension_manager

	extension_manager:register_system(self, system_name, extensions)

	self._dialogue_system_enabled = true
	self._extension_manager = extension_manager
	self._unit_extension_data = {}
	self._circumstance_name = extension_system_creation_context.circumstance_name
	self._is_server = extension_system_creation_context.is_server
	self._debug_state = nil
	self._t = nil
	self._current_mission = system_init_data.mission
	self._vo_sources_cache = system_init_data.vo_sources_cache
	self._is_rule_db_enabled = system_init_data.is_rule_db_enabled
	self._markers = {}
	self._original_dialogue_settings = {}
	self._in_game_voice_profiles = {}
	self._dialogues = {}

	if self._is_rule_db_enabled then
		self._tagquery_database = TagQueryDatabase:new(self)
		self._tagquery_loader = TagQueryLoader:new(self._tagquery_database, self._dialogues)
	end

	self.global_context = {
		player_voice_profiles = nil,
		team_lowest_player_level = nil
	}
	local network_event_delegate = extension_system_creation_context.network_event_delegate

	if network_event_delegate and self._is_rule_db_enabled then
		self._network_event_delegate = network_event_delegate

		network_event_delegate:register_session_events(self, unpack(RPCS))
	end

	local max_num_args = 2
	self._function_command_queue = FunctionCommandQueue:new(max_num_args)
	local auto_load_files = DialogueSettings.auto_load_files

	if self._current_mission then
		local mission_name = self._current_mission.name
		self.global_context.current_mission = mission_name
		local dialogue_settings_override = self._current_mission.dialogue_settings

		if dialogue_settings_override then
			for setting_name, value in pairs(dialogue_settings_override) do
				self._original_dialogue_settings[setting_name] = DialogueSettings[setting_name]
				DialogueSettings[setting_name] = value
			end
		end

		local game_mode_name = self._current_mission.game_mode_name
		local dialogue_filename = DialogueSettings.default_rule_path .. game_mode_name

		self:load_dialogue_resource(dialogue_filename)

		self.global_context.circumstance_vo_id = "default"
		local circumstance_template = CircumstanceTemplates[self._circumstance_name]
		local dialogue_id = circumstance_template.dialogue_id

		if dialogue_id then
			local circumstance_vo_rule_file_name = DialogueSettings.default_rule_path .. dialogue_id

			self:load_dialogue_resource(circumstance_vo_rule_file_name)

			self.global_context.circumstance_vo_id = dialogue_id
		end

		local blocked_auto_load = DialogueSettings.blocked_auto_load_files[self._current_mission.name]

		if not blocked_auto_load then
			self:load_dialogue_resources(auto_load_files)
		end

		local level_specific_load_files = DialogueSettings.level_specific_load_files[mission_name]

		if level_specific_load_files then
			self:load_dialogue_resources(level_specific_load_files)
		end
	else
		self:load_dialogue_resources(auto_load_files)

		local menu_vo_files = DialogueSettings.menu_vo_files

		self:load_dialogue_resources(menu_vo_files)
	end

	if self._is_rule_db_enabled then
		self._tagquery_database:finalize_rules()
		self._tagquery_database:set_global_context(self.global_context)
	end

	self._world = extension_system_creation_context.world
	self._wwise_world = Managers.world:wwise_world(self._world)
	self._dialogue_state_handler = DialogueStateHandler:new(self._world, self._wwise_world)
	self._dialogue_system_subtitle = DialogueSystemSubtitle:new(self._world, self._wwise_world)
	self._dialogue_system_wwise = DialogueSystemWwise:new(self._world)
	self._faction_memories = {
		player = {},
		enemy = {},
		npc = {},
		none = {}
	}
	self._extension_per_breed_wwise_voice_index = {}
	self.global_context.level_time = 0
	self._next_story_line_update_t = DialogueSettings.story_start_delay
	self._next_short_story_line_update_t = DialogueSettings.short_story_start_delay
	self._next_npc_story_line_update_t = DialogueSettings.npc_story_ticker_start_delay
	self._LOCAL_GAMETIME = 0
	self.dialogueLookupContexts = DialogueLookupContexts
	self.dialogueLookupConcepts = NetworkLookup.dialogues_all_concepts
	self._wwise_routes = WwiseRouting
	self._wwise_route_default = nil

	for key, value in pairs(self._wwise_routes) do
		if value.is_default then
			self._wwise_route_default = value

			break
		end
	end

	self._event_queue = nil
	self._query_queue = nil
	self._playing_dialogues = {}
	self._playing_dialogues_array = {}
	self._playing_units = {}

	if self._is_server and self._is_rule_db_enabled then
		self._event_queue = DialogueEventQueue:new(self._unit_extension_data, self._dialogues, self._tagquery_database)
		self._query_queue = DialogueQueryQueue:new()
		self._reject_queries_until = 0
		self._missions_data = {}
		self._missions = {}
		self._time_since_mission_fetch = 0
		self._missions_board_promise = nil
	end

	if not self._is_rule_db_enabled then
		self._vo_rule_queue = {}
	end

	self._dialog_sequence_events = {}
	self._next_player_level_check = 0
	self._next_local_events_queue_process = 0
	self._next_audible_check = 0

	if self._is_server then
		local event_manager = Managers.event

		event_manager:register(self, "terror_event_started", "_on_terror_event_started")
		event_manager:register(self, "terror_event_stopped", "_on_terror_event_stopped")
	end
end

function DialogueSystem:playing_dialogues_array()
	return self._playing_dialogues_array
end

function DialogueSystem:is_dialogue_playing()
	return #self._playing_dialogues_array > 0
end

function DialogueSystem:destroy()
	if self._is_rule_db_enabled then
		self._tagquery_loader:unload_files()
		self._tagquery_database:destroy()
	end

	if self._network_event_delegate then
		self._network_event_delegate:unregister_events(unpack(RPCS))
	end

	if next(self._original_dialogue_settings) then
		for setting_name, value in pairs(self._original_dialogue_settings) do
			DialogueSettings[setting_name] = value
		end
	end

	if self._is_server then
		local event_manager = Managers.event

		event_manager:unregister(self, "terror_event_started")
		event_manager:unregister(self, "terror_event_stopped")
	end

	table.clear(self)
end

function DialogueSystem:on_add_extension(world, unit, extension_name, extension_init_data)
	local breed = extension_init_data.breed
	local breed_dialogue_settings = breed and DialogueBreedSettings[breed.name]

	if breed and breed_dialogue_settings.has_dialogue_extension == false then
		Log.error("DialogueSystem", "According to dialogue_breed_settings.lua unit %s should not get a dialogue extension, please contact the Audio Team")
	end

	local new_extension = DialogueExtension:new(self, self._dialogue_system_wwise, self._extension_per_breed_wwise_voice_index, self._vo_sources_cache, unit, extension_init_data, self._wwise_world)

	if self._is_rule_db_enabled then
		self._tagquery_database:add_object_context(unit, "user_memory", new_extension:get_user_memory())
		self._tagquery_database:add_object_context(unit, "user_context", new_extension:get_context())

		local faction_memory_name = nil

		if extension_init_data.faction_memory_name then
			faction_memory_name = extension_init_data.faction_memory_name
		elseif breed_dialogue_settings then
			faction_memory_name = breed_dialogue_settings.dialogue_memory_faction_name
		end

		if faction_memory_name then
			local faction_memory = self._faction_memories[faction_memory_name]

			self._tagquery_database:add_object_context(unit, "faction_memory", faction_memory)
			new_extension:set_faction_memory(faction_memory)
		end
	end

	ScriptUnit.set_extension(unit, "dialogue_system", new_extension)

	if Managers.state.extension then
		self:_update_lowest_player_level()
	end

	return new_extension
end

function DialogueSystem:_update_global_context_player_voices(in_game_player_voices)
	local unique_voice_profiles = table.unique_array_values(in_game_player_voices)

	table.sort(unique_voice_profiles, function (a, b)
		return a:upper() < b:upper()
	end)

	self.global_context.player_voice_profiles = unique_voice_profiles
end

function DialogueSystem:extensions_ready(world, unit)
	local extension = ScriptUnit.extension(unit, "dialogue_system")

	extension:on_extensions_ready()

	if extension:is_a_player() then
		local voice_profile = extension:get_voice_profile()

		table.insert(self._in_game_voice_profiles, voice_profile)
		self:_update_global_context_player_voices(self._in_game_voice_profiles)
	end
end

function DialogueSystem:on_remove_extension(unit, extension_name)
	self:_cleanup_extension(unit, extension_name)
	ScriptUnit.remove_extension(unit, self.NAME)
end

function DialogueSystem:_cleanup_extension(unit, extension_name)
	local extension = self._unit_extension_data[unit]

	if extension == nil then
		return
	end

	if extension:is_a_player() then
		local voice_profile = extension:get_voice_profile()
		local voice_profile_index = table.index_of(self._in_game_voice_profiles, voice_profile)

		table.remove(self._in_game_voice_profiles, voice_profile_index)
	end

	local context = extension:get_context()
	local player_profile = context.player_profile

	if player_profile then
		local global_context = self.global_context
		global_context[player_profile] = false
		local career_name = context.player_career

		if career_name then
			global_context[career_name] = false
		end
	end

	local currently_playing_dialogue = extension:get_currently_playing_dialogue()

	if self._playing_dialogues[currently_playing_dialogue] then
		self._dialogue_system_wwise:stop_if_playing(currently_playing_dialogue.currently_playing_event_id)
		self:_remove_stopped_dialogue(currently_playing_dialogue)
	end

	extension:cleanup()

	self._playing_units[unit] = nil
	self._unit_extension_data[unit] = nil

	if self._is_rule_db_enabled then
		self._tagquery_database:remove_object(unit)
	end

	self._function_command_queue:cleanup_destroyed_unit(unit)
end

local _function_by_op = {
	[TagQuery.OP.ADD] = function (lhs, rhs)
		return (lhs or 0) + rhs
	end,
	[TagQuery.OP.SUB] = function (lhs, rhs)
		return (lhs or 0) - rhs
	end,
	[TagQuery.OP.NUMSET] = function (lhs, rhs)
		return rhs or 0
	end,
	[TagQuery.OP.TIMESET] = function ()
		return Managers.time:time("gameplay") + 900
	end
}

function DialogueSystem:_update_currently_playing_dialogues(t, dt)
	local ALIVE = ALIVE

	for unit, extension in pairs(self._playing_units) do
		repeat
			if not ALIVE[unit] then
				self._playing_units[unit] = nil
			else
				local currently_playing_dialogue = extension:get_currently_playing_dialogue()
				local is_currently_playing = nil

				if currently_playing_dialogue.dialogue_timer then
					is_currently_playing = currently_playing_dialogue.dialogue_timer - dt > 0
				end

				if not is_currently_playing then
					local animation_event = "stop_talking"

					self:_trigger_face_animation_event(unit, animation_event)
					extension:stop_currently_playing_wwise_event(currently_playing_dialogue.concurrent_wwise_event_id)

					local used_query = currently_playing_dialogue.used_query

					extension:set_currently_playing_dialogue(nil)
					self:_remove_stopped_dialogue(currently_playing_dialogue)

					currently_playing_dialogue.currently_playing_event_id = nil
					currently_playing_dialogue.currently_playing_unit = nil
					currently_playing_dialogue.used_query = nil
					currently_playing_dialogue.concurrent_wwise_event_id = nil
					self._playing_units[unit] = nil

					if not self._is_server then
						break
					end

					extension:set_dialogue_timer(nil)

					local result = used_query ~= nil and used_query.result

					if result then
						local source = used_query.query_context.source
						local success_rule = used_query.validated_rule
						local on_done = success_rule.on_done

						if on_done then
							local user_contexts = self._unit_extension_data[source]

							for i = 1, #on_done do
								local on_done_command = on_done[i]
								local table_name = on_done_command[1]
								local argument_name = on_done_command[2]
								local op = on_done_command[3]
								local argument = on_done_command[4]

								if type(op) == "table" then
									local new_value = _function_by_op[op](user_contexts:read_from_memory(table_name, argument_name), argument)

									user_contexts:store_in_memory(table_name, argument_name, new_value)
								else
									user_contexts:store_in_memory(table_name, argument_name, op)
								end
							end
						end

						if success_rule.on_post_rule_execution and success_rule.on_post_rule_execution.reject_events then
							local reject_events_command = success_rule.on_post_rule_execution.reject_events
							self._reject_queries_until = t + reject_events_command.duration
						end

						local speaker_name = "UNKNOWN"
						local breed_data = Unit.get_data(source, "breed")

						if breed_data and not breed_data.is_player then
							speaker_name = breed_data.name
						elseif ScriptUnit.has_extension(source, "dialogue_system") then
							speaker_name = extension:vo_class_name()
						end

						local temp_event_data = {
							dialogue_name = result,
							speaker_class = speaker_name,
							sound_event = extension:get_last_query_sound_event(),
							voice_profile = extension:get_voice_profile()
						}

						if success_rule.heard_speak_routing ~= nil then
							local heard_speak_target = success_rule.heard_speak_routing.target

							if heard_speak_target ~= "disabled" then
								if heard_speak_target == "players" then
									self:append_faction_event(unit, "heard_speak", temp_event_data, nil, "imperium", true)
								elseif heard_speak_target == "all" then
									for registered_unit, registered_extension in pairs(self._unit_extension_data) do
										repeat
											if registered_unit == unit then
												break
											end

											if registered_extension:is_dialogue_disabled() then
												break
											end

											self:append_event_to_queue(registered_unit, "heard_speak", temp_event_data, nil)
										until true
									end
								elseif heard_speak_target == "self" then
									self:append_self_event(unit, "heard_speak", temp_event_data, nil)
								elseif heard_speak_target == "mission_giver_default" then
									local voice_over_spawn_manager = Managers.state.voice_over_spawn
									local default_mission_giver_voice_profile = voice_over_spawn_manager:current_voice_profile()
									local default_mission_giver_unit = voice_over_spawn_manager:voice_over_unit(default_mission_giver_voice_profile)

									self:append_targeted_source_event(default_mission_giver_unit, "heard_speak", temp_event_data, nil)
								else
									Log.warning("DialogueSystem", "heard_speak_routing.target %s is wrong or unrecognized", heard_speak_target)
								end
							end
						else
							local legacy_v2_proximity_system = self._extension_manager:system("legacy_v2_proximity_system")

							legacy_v2_proximity_system:add_distance_based_vo_query(unit, "heard_speak", temp_event_data)
						end

						extension:set_last_query_sound_event(nil)
					end
				elseif currently_playing_dialogue.dialogue_timer then
					if not DEDICATED_SERVER then
						local playing = self._dialogue_system_wwise:is_playing(currently_playing_dialogue.currently_playing_event_id)

						if not playing then
							table.remove(self._dialog_sequence_events, 1)

							if self._dialog_sequence_events[1] ~= nil and self._dialog_sequence_events[1].type == "vorbis_external" then
								self._dialogue_system_subtitle:add_playing_localized_dialogue(currently_playing_dialogue.speaker_name, currently_playing_dialogue)
							end

							if table.size(self._dialog_sequence_events) > 0 then
								currently_playing_dialogue.currently_playing_event_id = extension:play_event(self._dialog_sequence_events[1])
							end
						end

						if currently_playing_dialogue.subtitle_distance then
							currently_playing_dialogue.is_audible = self:is_dialogue_audible(unit, currently_playing_dialogue, t)
						end
					end

					currently_playing_dialogue.dialogue_timer = currently_playing_dialogue.dialogue_timer - dt
				end

				if not DEDICATED_SERVER then
					self._dialogue_system_subtitle:update()
				end
			end
		until true
	end

	if #table.keys(self._playing_units) == 0 then
		table.clear(self._playing_dialogues_array)
	end
end

local PLAYER_LEVEL_CHECK_INTERVAL = 4

function DialogueSystem:physics_async_update(context, dt, t)
	self._t = t

	self:_update_currently_playing_dialogues(t, dt)

	if not self._is_server then
		return
	end

	self._dialogue_state_handler:update(t)

	self.global_context.level_time = t
	self.global_context.pacing_tension = Managers.state.pacing:tension()
	self.global_context.team_threat_level = Managers.state.pacing:combat_state()
	local is_decaying_tension = Managers.state.pacing:is_decaying_tension()
	self.global_context.is_decaying_tension = tostring(is_decaying_tension)
	self.global_context.pacing_state = Managers.state.pacing:state()
	self._LOCAL_GAMETIME = t + 900
	self.global_context.active_hordes = Managers.state.horde:num_active_hordes()

	for _, extension in pairs(self._unit_extension_data) do
		extension:physics_async_update(context, dt, t)
	end

	if self._next_player_level_check < t then
		self:_update_lowest_player_level()

		self._next_player_level_check = t + PLAYER_LEVEL_CHECK_INTERVAL
	end

	if self._is_rule_db_enabled then
		local tagquery_database = self._tagquery_database
		local query = tagquery_database:iterate_queries(self._LOCAL_GAMETIME)

		if self._dialogue_system_enabled then
			local delayed_query = self._query_queue:get_query(t)

			if query then
				self:_process_query(query, dt, t, false)
			end

			if delayed_query then
				self:_process_query(delayed_query, dt, t, true)
			end

			self:_update_story_lines(t)
		end

		self._event_queue:update_new_events(dt, t)
	end
end

function DialogueSystem:register_extension_update(unit, extension_name, extension)
	self._unit_extension_data[unit] = extension
end

local LOCAL_VO_EVENTS_PROCESS_INTERVAL = 0.1

function DialogueSystem:update(context, dt, t)
	if GameParameters.testify then
		Testify:poll_requests_through_handler(DialogueSystemTestify, self)
	end

	if not self._is_rule_db_enabled and not DEDICATED_SERVER then
		self:_process_local_playing_dialogues(dt, t)

		if self._next_local_events_queue_process < t then
			self:_process_local_vo_event_queue()

			self._next_local_events_queue_process = t + LOCAL_VO_EVENTS_PROCESS_INTERVAL
		end
	end
end

function DialogueSystem:post_update(entity_system_update_context, t)
end

function DialogueSystem:hot_join_sync(sender, channel)
	local breed_names = {}
	local voice_indexes = {}
	local counter_breed_wwise = 0

	for key, value in pairs(self._extension_per_breed_wwise_voice_index) do
		counter_breed_wwise = counter_breed_wwise + 1
		breed_names[counter_breed_wwise] = key
		voice_indexes[counter_breed_wwise] = value
	end

	local counter_extensions = 0
	local extension_profiles = {}
	local extension_unit_ids = {}

	for unit, extension in pairs(self._unit_extension_data) do
		repeat
			if extension:is_network_synced() == false then
				break
			end

			counter_extensions = counter_extensions + 1
			extension_profiles[counter_extensions] = extension:get_profile_name()
			local unit_id = Managers.state.unit_spawner:game_object_id(unit)
			extension_unit_ids[counter_extensions] = unit_id
		until true
	end

	RPC.rpc_dialogue_system_joined(channel, counter_breed_wwise, breed_names, voice_indexes, counter_extensions, extension_unit_ids, extension_profiles)
end

function DialogueSystem:trigger_general_unit_event(unit, event)
	local audio_system_extension = Managers.state.extension:system("audio_system")

	audio_system_extension:_play_event(event, unit, 0)
end

function DialogueSystem:trigger_attack(blackboard, player_unit, enemy_unit, should_backstab, long_attack)
	local player_unit_spawn_manager = Managers.state.player_unit_spawn
	local owner_player = player_unit_spawn_manager:owner(player_unit)
	local ALIVE = ALIVE

	if owner_player and ALIVE[player_unit] and ALIVE[enemy_unit] then
		local dialogue_extension = ScriptUnit.extension(enemy_unit, "dialogue_system")
		local switch_group = dialogue_extension.wwise_voice_switch_group
		local wwise_source, wwise_world = self._dialogue_system_wwise:make_unit_auto_source(enemy_unit, dialogue_extension.voice_node)

		if switch_group then
			local switch_value = dialogue_extension.wwise_voice_switch_value

			WwiseWorld.set_switch(wwise_world, switch_group, switch_value, wwise_source)
		end

		if not owner_player.bot_player then
			local breed = blackboard.breed
			local game_session_manager = Managers.state.game_session
			local sound_event = nil

			if should_backstab then
				sound_event = breed.backstab_player_sound_event
			elseif long_attack and breed.attack_player_sound_event_long then
				sound_event = breed.attack_player_sound_event_long
			else
				sound_event = breed.attack_player_sound_event
			end

			local general_event = nil

			if long_attack and breed.attack_general_sound_event_long then
				general_event = breed.attack_general_sound_event_long
			else
				general_event = breed.attack_general_sound_event
			end

			if owner_player.local_player and sound_event then
				local audio_system_extension = Managers.state.extension:system("audio_system")

				audio_system_extension:_play_event_with_source(wwise_world, sound_event, wwise_source)
			else
				local audio_system_extension = Managers.state.extension:system("audio_system")

				audio_system_extension:_play_event(general_event, enemy_unit, 0)
			end

			local general_event_id = NetworkLookup.sound_events[general_event]
			local enemy_game_object_unit_id = Managers.state.unit_spawner:game_object_id(enemy_unit)

			game_session_manager:send_rpc_clients_except("rpc_server_audio_unit_dialogue_event", owner_player:channel_id(), general_event_id, enemy_game_object_unit_id, 0)
		end
	end
end

function DialogueSystem:random_player()
	local side_system = Managers.state.extension:system("side_system")
	local side_name = side_system:get_default_player_side_name()
	local side = side_system:get_side_from_name(side_name)
	local players = side:added_player_units()
	local unit_list = {}
	local unit_list_n = 0

	for i = 1, #players do
		local unit = players[i]

		if HEALTH_ALIVE[unit] then
			unit_list_n = unit_list_n + 1
			unit_list[unit_list_n] = unit
		end
	end

	if unit_list_n > 0 then
		local unit = unit_list[math.random(1, unit_list_n)]

		return unit
	end

	return nil
end

function DialogueSystem:force_stop_all()
	if self._is_server then
		return
	end

	for unit, extension in pairs(self._playing_units) do
		local currently_playing_dialogue = extension:get_currently_playing_dialogue()

		if currently_playing_dialogue then
			self._playing_dialogues[currently_playing_dialogue] = nil

			extension:stop_currently_playing_vo()
			self:play_wwise_event(extension, "stop_vox_static_loop")
		end

		self._playing_units[unit] = nil
	end

	self._vo_rule_queue = {}
end

function DialogueSystem:_update_story_lines(t)
	local next_story_line_update_t = self._next_story_line_update_t
	local is_story_ticker = DialogueSettings.story_ticker_enabled

	if is_story_ticker and next_story_line_update_t < t then
		self._next_story_line_update_t = t + DialogueSettings.story_tick_time

		if self.global_context.team_threat_level == "low" and self.global_context.active_hordes == 0 then
			Vo.player_vo_event_by_concept("story_talk")
		end
	end

	local is_short_story_ticker = DialogueSettings.short_story_ticker_enabled
	local next_short_story_line_update_t = self._next_short_story_line_update_t

	if is_short_story_ticker and next_short_story_line_update_t < t then
		self._next_short_story_line_update_t = t + DialogueSettings.short_story_tick_time

		if self.global_context.team_threat_level == "low" and self.global_context.active_hordes == 0 then
			Vo.player_vo_event_by_concept("short_story_talk")
		end
	end

	local is_vox_stories = DialogueSettings.npc_story_ticker_enabled

	if is_vox_stories then
		local next_npc_story_line_update_t = self._next_npc_story_line_update_t

		if is_vox_stories and next_npc_story_line_update_t < t then
			self._next_npc_story_line_update_t = t + DialogueSettings.npc_story_tick_time
			local trigger_id = "npc_story_talk"

			Vo.play_npc_story(trigger_id)
		end
	end
end

function DialogueSystem:_update_lowest_player_level()
	local lowest_player_level = nil
	local side_system = Managers.state.extension:system("side_system")

	if not side_system then
		return
	end

	local side_name = side_system:get_default_player_side_name()
	local side = side_system:get_side_from_name(side_name)
	local human_units = side.valid_human_units
	local HEALTH_ALIVE = HEALTH_ALIVE
	local player_unit_spawn_manager = Managers.state.player_unit_spawn

	for i = 1, #human_units do
		local human_unit = human_units[i]

		if HEALTH_ALIVE[human_unit] then
			local player = player_unit_spawn_manager:owner(human_unit)
			local profile = player:profile()
			local player_level = profile.current_level

			if player_level and lowest_player_level == nil then
				lowest_player_level = player_level
			elseif player_level and player_level < lowest_player_level then
				lowest_player_level = player_level
			end
		end
	end

	self.global_context.team_lowest_player_level = lowest_player_level
end

function DialogueSystem:disable()
	self._dialogue_system_enabled = false
end

function DialogueSystem:enable()
	self._dialogue_system_enabled = true
end

function DialogueSystem:_process_local_playing_dialogues(dt, t)
	local unit_alive = Unit.alive

	for unit, extension in pairs(self._playing_units) do
		repeat
			if not unit_alive(unit) then
				self._playing_units[unit] = nil
			else
				local currently_playing_dialogue = extension:get_currently_playing_dialogue()
				local is_still_playing = nil

				if currently_playing_dialogue.dialogue_timer then
					local wwise_playing = self._dialogue_system_wwise:is_playing(currently_playing_dialogue.currently_playing_event_id)
					is_still_playing = wwise_playing
				end

				if not is_still_playing then
					self:_remove_stopped_dialogue(currently_playing_dialogue)

					self._playing_units[unit] = nil

					extension:set_currently_playing_dialogue(nil)
					table.remove(self._vo_rule_queue, 1)
				else
					currently_playing_dialogue.dialogue_timer = currently_playing_dialogue.dialogue_timer - dt
				end

				self._dialogue_system_subtitle:update()
			end
		until true
	end
end

function DialogueSystem:_process_local_vo_event_queue()
	if self:is_dialogue_playing() then
		return
	end

	local queue = self._vo_rule_queue
	local event = queue[1]

	if not event then
		return
	end

	local extension = self._unit_extension_data[event.unit]
	local currently_playing_dialogue = extension:get_currently_playing_dialogue()
	local wwise_playing = currently_playing_dialogue and self._dialogue_system_wwise:is_playing(currently_playing_dialogue.currently_playing_event_id)

	if not wwise_playing then
		extension:play_local_vo_event(event.rule_name, event.wwise_route_key, event.on_play_callback, event.seed)
	end
end

function DialogueSystem:append_faction_event(source_unit, event_name, event_data, identifier, breed_faction_name, exclude_me)
	local num_unique_voices = #self.global_context.player_voice_profiles

	if num_unique_voices == 0 then
		return
	end

	for registered_unit, registered_extension in pairs(self._unit_extension_data) do
		repeat
			if registered_extension:is_dialogue_disabled() then
				break
			elseif registered_extension._faction_breed_name ~= breed_faction_name then
				break
			elseif registered_unit == source_unit and exclude_me then
				break
			elseif breed_faction_name == "imperium" and event_data.voice_profile == registered_extension:get_voice_profile() and num_unique_voices > 1 then
				break
			end

			self:append_event_to_queue(registered_unit, event_name, event_data, identifier)
			registered_extension:set_is_disabled_override(false)
		until true
	end
end

function DialogueSystem:append_self_event(source_unit, event_name, event_data, identifier)
	self:append_event_to_queue(source_unit, event_name, event_data, identifier)
end

function DialogueSystem:append_targeted_source_event(source_unit, event_name, event_data, identifier)
	self:append_event_to_queue(source_unit, event_name, event_data, identifier)
end

function DialogueSystem:populate_faction_contexts(nice_array, base_index, target_faction, source_unit)
	local total_faction_contexts = 0

	for registered_unit, registered_extension in pairs(self._unit_extension_data) do
		repeat
			if registered_extension._faction_breed_name ~= target_faction then
				break
			end

			if registered_unit == source_unit then
				break
			end

			if registered_extension._context then
				total_faction_contexts = total_faction_contexts + 1
				nice_array[base_index + total_faction_contexts] = registered_extension._context
			end
		until true
	end

	nice_array[base_index] = total_faction_contexts
end

function DialogueSystem:append_event_to_queue(unit, event_name, event_data, identifier)
	self._event_queue:append_event(unit, event_name, event_data, identifier)
end

function DialogueSystem:is_server()
	return self._is_server
end

function DialogueSystem:is_playable_dialogue_category(dialogue)
	local is_playable = true
	local is_cinematic_playing = Managers.state.cinematic:is_playing()

	if is_cinematic_playing then
		local playable_categories = DialogueCategoryConfig.playable_during_cinematic

		if not playable_categories[dialogue.category] then
			is_playable = false
		end
	end

	return is_playable
end

function DialogueSystem:_set_ruledatabase_debug_level()
	if self._debug_ruleDatabase_all == nil then
		Log.warning("Dialogue System", "Trying to set the ruledatabase debug level to nil.")

		return
	end

	if not self._is_rule_db_enabled then
		Log.warning("Dialogue System", "Ruledatabase is not enabled.")

		return
	end

	if BUILD == "release" then
		Log.info("Dialogue System", "Ruledatabase debugging not enabled in RELEASE builds.")

		return
	end

	if self._debug_ruleDatabase_all then
		RuleDatabase.set_debug(2)
	else
		RuleDatabase.set_debug(0)
	end
end

function DialogueSystem:rpc_dialogue_system_joined(channel_id, total_breed_wwise_voices, breed_names, voice_indexes, counter_extension_data, extension_unit_ids, extension_profiles)
	table.clear(self._extension_per_breed_wwise_voice_index)

	for index = 1, total_breed_wwise_voices do
		self._extension_per_breed_wwise_voice_index[breed_names[index]] = voice_indexes[index]
	end

	for index = 1, counter_extension_data do
		repeat
			local unit = Managers.state.unit_spawner:unit(extension_unit_ids[index], false)

			if unit == nil then
				break
			end

			local extension = ScriptUnit.extension(unit, "dialogue_system")

			if extension == nil then
				break
			end

			extension:set_vo_profile(extension_profiles[index], self._vo_sources_cache)
		until true
	end
end

function DialogueSystem:rpc_trigger_dialogue_event(channel_id, go_id, event_id, event_data_array, event_data_array_types, identifier)
	local unit = Managers.state.unit_spawner:unit(go_id, false)

	if not unit then
		return
	end

	local pairs_in_event_data = #event_data_array / 2
	local index = 1

	for i = 1, pairs_in_event_data do
		local context = self.dialogueLookupContexts.all_context_names[event_data_array[index]]
		event_data_array[index] = context
		index = index + 1

		if not event_data_array_types[index] then
			event_data_array[index] = self.dialogueLookupContexts[context][event_data_array[index]]
		end

		index = index + 1
	end

	local event_data = {}

	table.array_to_table(event_data_array, #event_data_array, event_data)

	local event_name = self.dialogueLookupConcepts[event_id]

	self:append_event_to_queue(unit, event_name, event_data, identifier)
end

function DialogueSystem:rpc_play_dialogue_event(channel_id, go_id, is_level_unit, level_name_hash, dialogue_id, dialogue_index, dialogue_rule_index)
	self:_play_dialogue_event_implementation(go_id, is_level_unit, level_name_hash, dialogue_id, dialogue_index, dialogue_rule_index)
end

function DialogueSystem:_play_dialogue_event_implementation(go_id, is_level_unit, level_name_hash, dialogue_id, dialogue_index, dialogue_rule_index)
	local dialogue_actor_unit = Managers.state.unit_spawner:unit(go_id, is_level_unit, level_name_hash)

	if not dialogue_actor_unit then
		return
	end

	local dialogue_name = NetworkLookup.dialogues[dialogue_id]
	local dialogue = self._dialogues[dialogue_name]

	if not self:is_playable_dialogue_category(dialogue) then
		return
	end

	if dialogue.currently_playing_event_id then
		return
	end

	local extension = self._unit_extension_data[dialogue_actor_unit]

	if not extension then
		return
	end

	local sound_event, subtitles_event, sound_event_duration = extension:get_dialogue_event(dialogue_name, dialogue_index)
	local rule = self._tagquery_database:get_rule(dialogue_rule_index)
	local is_sequence = nil

	if sound_event then
		extension:set_last_query_sound_event(sound_event)
	end

	local speaker_name = extension:get_context().voice_template
	dialogue.speaker_name = speaker_name

	if speaker_name == "tech_priest_a" and dialogue.wwise_route == 1 then
		dialogue.wwise_route = 21
	end

	if not DEDICATED_SERVER then
		local wwise_route = self._wwise_route_default

		if dialogue.wwise_route ~= nil then
			wwise_route = self._wwise_routes[dialogue.wwise_route]
		end

		if sound_event then
			if rule.pre_wwise_event or rule.post_wwise_event then
				self._dialog_sequence_events = self:_create_sequence_events_table(rule.pre_wwise_event, wwise_route, sound_event, rule.post_wwise_event)
				dialogue.currently_playing_event_id = extension:play_event(self._dialog_sequence_events[1])
				is_sequence = true
			else
				local vo_event = {
					type = "vorbis_external",
					sound_event = sound_event,
					wwise_route = wwise_route
				}
				dialogue.currently_playing_event_id = extension:play_event(vo_event)
				is_sequence = false
			end

			local concurrent_wwise_event = rule.concurrent_wwise_event

			if concurrent_wwise_event then
				dialogue.concurrent_wwise_event_id = self:play_wwise_event(extension, concurrent_wwise_event)
			end

			local class_name = extension._context.class_name
			local breed_dialogue_setting = DialogueBreedSettings[class_name]

			if breed_dialogue_setting then
				local subtitle_distance = breed_dialogue_setting.subtitle_distance

				if subtitle_distance then
					dialogue.subtitle_distance = subtitle_distance
					dialogue.is_audible = self:is_dialogue_audible(dialogue_actor_unit, dialogue)
				else
					dialogue.is_audible = true
				end
			else
				dialogue.is_audible = true
			end
		end

		local animation_event = "start_talking"

		self:_trigger_face_animation_event(dialogue_actor_unit, animation_event)
	end

	self._playing_units[dialogue_actor_unit] = extension
	dialogue.currently_playing_unit = dialogue_actor_unit
	dialogue.dialogue_timer = sound_event_duration
	dialogue.currently_playing_subtitle = subtitles_event

	extension:set_currently_playing_dialogue(dialogue)

	local dialogue_category = dialogue.category
	local category_setting = DialogueCategoryConfig[dialogue_category]
	self._playing_dialogues[dialogue] = category_setting

	table.insert(self._playing_dialogues_array, 1, dialogue)

	if self._dialog_sequence_events[1] ~= nil and self._dialog_sequence_events[1].type == "vorbis_external" or not is_sequence then
		self._dialogue_system_subtitle:add_playing_localized_dialogue(speaker_name, dialogue)
	end

	dialogue.wwise_route = rule.wwise_route
end

function DialogueSystem:_create_sequence_events_table(pre_wwise_event, wwise_route, sound_event, post_wwise_event)
	local sequence_events = {}

	if pre_wwise_event then
		local pre_wwise_event_table = {
			type = "resource_event",
			sound_event = pre_wwise_event
		}

		table.insert(sequence_events, pre_wwise_event_table)
	end

	local vo_event = {
		type = "vorbis_external",
		sound_event = sound_event,
		wwise_route = wwise_route
	}

	table.insert(sequence_events, vo_event)

	if post_wwise_event then
		local post_wwise_event_table = {
			type = "resource_event",
			sound_event = post_wwise_event
		}

		table.insert(sequence_events, post_wwise_event_table)
	end

	return sequence_events
end

function DialogueSystem:play_wwise_event(extension, wwise_event)
	local wwise_event_table = {
		type = "resource_event",
		sound_event = wwise_event
	}

	return extension:play_event(wwise_event_table)
end

function DialogueSystem:rpc_interrupt_dialogue_event(channel_id, go_id, is_level_unit, level_name_hash)
	local unit = Managers.state.unit_spawner:unit(go_id, is_level_unit, level_name_hash)

	if not unit then
		return
	end

	local extension = self._unit_extension_data[unit]

	if extension then
		local dialogue = extension:get_currently_playing_dialogue()

		if dialogue then
			self:_interrupt_dialogue_event_implementation(unit, dialogue)
		end
	end
end

function DialogueSystem:rpc_set_dynamic_smart_tag(channel_id, go_id, smart_tag)
	local enemy_unit = Managers.state.unit_spawner:unit(go_id)

	if not enemy_unit then
		return
	end

	local extension = self._unit_extension_data[enemy_unit]

	if extension then
		extension:set_dynamic_smart_tag(smart_tag)
	end
end

local AUDIBLE_CHECK_FREQUENCY = 0.1

function DialogueSystem:is_dialogue_audible(unit, dialogue, t)
	if not DEDICATED_SERVER then
		if t and t < self._next_audible_check then
			return dialogue.is_audible
		else
			self._next_audible_check = self._next_audible_check + AUDIBLE_CHECK_FREQUENCY
			local speaker_pos = Unit.world_position(unit, 1)
			local player = Managers.player:local_player(1)
			local player_unit = player.player_unit

			if player_unit then
				local player_pos = Unit.world_position(player_unit, 1)
				local distance = Vector3.distance(speaker_pos, player_pos)
				local max_distance = dialogue.subtitle_distance
				local re_enable_distance = max_distance - 2

				if distance < re_enable_distance then
					return true
				elseif max_distance < distance then
					return false
				else
					return dialogue.is_audible
				end
			else
				return false
			end
		end
	end
end

function DialogueSystem:_remove_stopped_dialogue(dialogue)
	local index = table.index_of(self._playing_dialogues_array, dialogue)

	table.remove(self._playing_dialogues_array, index)

	dialogue.currently_playing_event_id = nil
	self._playing_dialogues[dialogue] = nil

	self._dialogue_system_subtitle:remove_localized_dialogue(dialogue)
end

function DialogueSystem:_interrupt_dialogue_event_implementation(unit, dialogue)
	if not DEDICATED_SERVER then
		self._dialogue_system_wwise:stop_if_playing(dialogue.currently_playing_event_id)

		local animation_event = "stop_talking"

		self:_trigger_face_animation_event(unit, animation_event)
	end

	self:_remove_stopped_dialogue(dialogue)

	dialogue.currently_playing_event_id = nil
	local extension = self._unit_extension_data[unit]

	extension:set_currently_playing_dialogue(nil)

	self._playing_units[unit] = nil
end

function DialogueSystem:rpc_player_select_voice_server(channel_id, go_id, player_voice_id)
	local selected_voice = NetworkLookup.player_character_voices[player_voice_id]
	local unit = Managers.state.unit_spawner:unit(go_id)

	local function callback()
		local dialogue_extension = ScriptUnit.extension(unit, "dialogue_system")

		dialogue_extension:set_vo_profile(selected_voice)
		Managers.state.game_session:send_rpc_clients_except("rpc_player_select_voice", channel_id, go_id, player_voice_id)
	end

	local peer_id = Managers.state.game_session:channel_to_peer(channel_id)
	local player_unit_spawn_manager = Managers.state.player_unit_spawn
	local player = player_unit_spawn_manager:owner(unit)
	local local_player_id = player:local_player_id()
	local profile = player:profile()
	profile.selected_voice = selected_voice
end

function DialogueSystem:rpc_player_select_voice(channel_id, go_id, player_voice_id)
	local selected_voice = NetworkLookup.player_character_voices[player_voice_id]
	local unit = Managers.state.unit_spawner:unit(go_id)
	local dialogue_extension = ScriptUnit.has_extension(unit, "dialogue_system")

	if dialogue_extension then
		dialogue_extension:set_vo_profile(selected_voice)
	end
end

function DialogueSystem:_on_terror_event_started()
	DialogueSettings.story_ticker_enabled = false
	DialogueSettings.short_story_ticker_enabled = false
end

function DialogueSystem:_on_terror_event_stopped()
	DialogueSettings.story_ticker_enabled = true
	self._next_story_line_update_t = self._t + DialogueSettings.story_tick_time
	DialogueSettings.short_story_ticker_enabled = true
	self._next_short_story_line_update_t = self._t + DialogueSettings.short_story_tick_time
end

local interrupt_dialogue_list = {}

function DialogueSystem:_process_query(query, dt, t, is_a_delayed_query)
	local dialogue_actor_unit = query.query_context.source

	if dialogue_actor_unit == nil or not ALIVE[dialogue_actor_unit] then
		return
	end

	local extension = self._unit_extension_data[dialogue_actor_unit]

	if extension == nil then
		return
	end

	extension.last_query = query
	local result = query.result

	if result then
		local dialogue = self._dialogues[result]

		table.clear(interrupt_dialogue_list)

		local will_play = self:_can_query_play(query, dialogue_actor_unit, interrupt_dialogue_list)

		if dialogue.currently_playing_event_id then
			will_play = false
		end

		if will_play then
			if not table.is_empty(interrupt_dialogue_list) then
				if dialogue.category == "vox_prio_0" then
					local wait_time = 0

					for playing_dialogue, _ in pairs(interrupt_dialogue_list) do
						if playing_dialogue.category == "conversations_prio_1" then
							local dialogue_length = playing_dialogue.dialogue_timer

							if wait_time < dialogue_length then
								wait_time = dialogue_length + 0.3
							end
						end
					end

					if wait_time > 0 then
						self:_queue_query(t + wait_time, query)

						return
					else
						self:_execute_accepted_query(t, query, dialogue_actor_unit, extension, interrupt_dialogue_list)

						self._reject_queries_until = 0

						return
					end
				else
					self:_execute_accepted_query(t, query, dialogue_actor_unit, extension, interrupt_dialogue_list)

					self._reject_queries_until = 0

					return
				end
			end

			if t < self._reject_queries_until then
				return
			end

			if is_a_delayed_query then
				self:_execute_accepted_query(t, query, dialogue_actor_unit, extension, interrupt_dialogue_list)

				return
			end

			if dialogue.on_pre_rule_execution then
				if dialogue.on_pre_rule_execution.random_ignore_vo then
					local random_ignore_vo = dialogue.on_pre_rule_execution.random_ignore_vo

					if random_ignore_vo.ignore_until and t < random_ignore_vo.ignore_until then
						return
					end

					if random_ignore_vo.chance < math.random() then
						if random_ignore_vo.failed_tries == nil then
							random_ignore_vo.failed_tries = 1
						else
							random_ignore_vo.failed_tries = random_ignore_vo.failed_tries + 1
						end

						if random_ignore_vo.failed_tries < random_ignore_vo.max_failed_tries then
							random_ignore_vo.ignore_until = t + random_ignore_vo.hold_for

							return
						end
					end

					random_ignore_vo.failed_tries = 0
				end

				if dialogue.on_pre_rule_execution.delay_vo then
					self:_queue_query(t + dialogue.on_pre_rule_execution.delay_vo.duration, query)

					return
				end
			end

			if DialogueSettings.default_pre_vo_waiting_time and DialogueSettings.default_pre_vo_waiting_time > 0 then
				self:_queue_query(t + DialogueSettings.default_pre_vo_waiting_time, query)

				return
			end

			self:_execute_accepted_query(t, query, dialogue_actor_unit, extension, interrupt_dialogue_list)
		end
	end
end

function DialogueSystem:_get_speaker_route_settings(query)
	local success_rule = query.validated_rule

	if success_rule.speaker_routing == nil then
		return
	end

	local speaker_target = success_rule.speaker_routing.target
	local target_unit = nil

	if speaker_target then
		target_unit = query.query_context.target_unit
	end

	local is_single_target = speaker_target == "dialogist" and target_unit

	return is_single_target, speaker_target, target_unit
end

function DialogueSystem:_execute_targeted_dialogue_event(target_unit, query, dialogue_id, dialogue_index, is_level_unit, go_id, level_name_hash)
	local player_unit_spawn_manager = Managers.state.player_unit_spawn
	local targeted_player = player_unit_spawn_manager:owner(target_unit)
	local peer_id = targeted_player:peer_id()
	local is_remote_player = targeted_player.remote

	if DEDICATED_SERVER then
		Managers.state.game_session:send_rpc_client("rpc_play_dialogue_event", peer_id, go_id, is_level_unit, level_name_hash, dialogue_id, dialogue_index, query.rule_index)
		self:_play_dialogue_event_implementation(go_id, is_level_unit, level_name_hash, dialogue_id, dialogue_index, query.rule_index)
	elseif self._is_server and not is_remote_player then
		self:_play_dialogue_event_implementation(go_id, is_level_unit, level_name_hash, dialogue_id, dialogue_index, query.rule_index)
	elseif self._is_server and is_remote_player then
		Managers.state.game_session:send_rpc_client("rpc_play_dialogue_event", peer_id, go_id, is_level_unit, level_name_hash, dialogue_id, dialogue_index, query.rule_index)
	end
end

function DialogueSystem:_execute_dialogue_event(extension, query, dialogue, dialogue_actor_unit)
	local game_session_manager = Managers.state.game_session
	local event_name, event_duration, dialogue_index = extension:get_dialogue_event_index(query)
	local is_level_unit, go_id, level_name_hash = Managers.state.unit_spawner:game_object_id_or_level_index(dialogue_actor_unit)
	local dialogue_id = NetworkLookup.dialogues[query.result]
	local is_single_target, _, target_unit = self:_get_speaker_route_settings(query)

	if event_name and event_duration then
		self:_register_telemetry_events(extension, query, event_name)

		if is_single_target then
			self:_execute_targeted_dialogue_event(target_unit, query, dialogue_id, dialogue_index, is_level_unit, go_id, level_name_hash)
		else
			game_session_manager:send_rpc_clients("rpc_play_dialogue_event", go_id, is_level_unit, level_name_hash, dialogue_id, dialogue_index, query.rule_index)
			self:_play_dialogue_event_implementation(go_id, is_level_unit, level_name_hash, dialogue_id, dialogue_index, query.rule_index)
		end

		dialogue.used_query = query
	end
end

function DialogueSystem:_execute_interruptions(INTERRUPT_DIALOGUE_LIST)
	local game_session_manager = Managers.state.game_session

	for interrupt_dialogue, _ in pairs(INTERRUPT_DIALOGUE_LIST) do
		INTERRUPT_DIALOGUE_LIST[interrupt_dialogue] = nil
		local playing_unit = interrupt_dialogue.currently_playing_unit
		local is_level_unit, unit_id, level_name_hash = Managers.state.unit_spawner:game_object_id_or_level_index(playing_unit)

		game_session_manager:send_rpc_clients("rpc_interrupt_dialogue_event", unit_id, is_level_unit, level_name_hash)
		self:_interrupt_dialogue_event_implementation(playing_unit, interrupt_dialogue)
	end
end

function DialogueSystem:_execute_accepted_query(t, query, dialogue_actor_unit, extension, INTERRUPT_DIALOGUE_LIST)
	local dialogue = self._dialogues[query.result]

	self:_execute_interruptions(INTERRUPT_DIALOGUE_LIST)

	local query_context = query.query_context

	if query_context.identifier and query_context.identifier ~= "" then
		self.dialogue_state_handler:add_playing_dialogue(query_context.identifier, dialogue.currently_playing_event_id, t, dialogue.dialogue_timer)
	end

	self:_execute_dialogue_event(extension, query, dialogue, dialogue_actor_unit)
end

function DialogueSystem:_register_telemetry_events(extension, query, event_name)
	local global_context = self.global_context
	local player_context = extension:get_context()
	local vo_rule = query.validated_rule.name
	local vo_profile_name = extension:get_profile_name()
	local vo_category_name = query.validated_rule.category
	local resistance = Managers.state.difficulty:get_resistance()
	local challenge = Managers.state.difficulty:get_challenge()

	Managers.telemetry_events:vo_event_triggered(global_context, player_context, event_name, vo_rule, vo_profile_name, vo_category_name, resistance, challenge)
end

function DialogueSystem:_can_query_play(query, dialogue_actor_unit, INTERRUPT_DIALOGUE_LIST)
	local dialogue = self._dialogues[query.result]
	local dialogue_category = dialogue.category
	local category_setting = DialogueCategoryConfig[dialogue_category]
	local playable_during_category = category_setting.playable_during_category
	local interrupt_self = category_setting.interrupt_self
	local playing_dialogues = self._playing_dialogues
	local will_play = true

	for playing_dialogue, playing_dialogue_category_data in pairs(playing_dialogues) do
		local mutually_exclusive = playing_dialogue_category_data.mutually_exclusive
		local interrupted_by = playing_dialogue_category_data.interrupted_by

		if mutually_exclusive and dialogue_category == playing_dialogue.category then
			will_play = false

			break
		end

		if playing_dialogue.currently_playing_unit == dialogue_actor_unit and not interrupt_self then
			will_play = false

			break
		end

		if interrupted_by[dialogue_category] then
			INTERRUPT_DIALOGUE_LIST[playing_dialogue] = true
		elseif not playable_during_category[playing_dialogue.category] then
			will_play = false

			break
		end
	end

	return will_play, INTERRUPT_DIALOGUE_LIST
end

function DialogueSystem:_queue_query(t_target_time, query)
	self._query_queue:queue_query(t_target_time, query)
end

function DialogueSystem:_trigger_face_animation_event(unit, animation_event)
	local visual_loadout_extension = ScriptUnit.has_extension(unit, "visual_loadout_system")

	if visual_loadout_extension then
		local slot_name = "slot_body_face"
		local face_unit = visual_loadout_extension:unit_3p_from_slot(slot_name)

		if face_unit and Unit.has_animation_state_machine(face_unit) then
			local has_animation_event = Unit.has_animation_event(face_unit, animation_event)

			if has_animation_event then
				local event_index = Unit.animation_event(face_unit, animation_event)

				Unit.animation_event_by_index(face_unit, event_index)
			end
		end
	end
end

function DialogueSystem:load_dialogue_resources(file_names)
	for _, file_name in ipairs(file_names) do
		self:load_dialogue_resource(file_name)
	end
end

function DialogueSystem:load_dialogue_resource(file_name)
	local rule_file_path = DialogueSettings.default_rule_path .. file_name

	if Application.can_get_resource("lua", rule_file_path) then
		self._vo_sources_cache:add_rule_file(file_name)

		if self._is_rule_db_enabled then
			self._tagquery_loader:load_file(rule_file_path)
		end
	end
end

function DialogueSystem:dialogue_system_subtitle()
	return self._dialogue_system_subtitle
end

function DialogueSystem:mission_board()
	if self._is_server then
		if self._missions_board_promise then
			return nil, 
		end

		local t = Managers.time:time("main")

		if t - self._time_since_mission_fetch < 10 then
			return self._missions_data, self._missions
		end

		self._missions_board_promise = Managers.data_service.mission_board:fetch()

		self._missions_board_promise:next(function (data)
			self._missions_data = data
			self._missions = data.missions
			self._missions_board_promise = nil
			self._time_since_mission_fetch = t
		end)

		return self._missions_data, self._missions
	end
end

return DialogueSystem
