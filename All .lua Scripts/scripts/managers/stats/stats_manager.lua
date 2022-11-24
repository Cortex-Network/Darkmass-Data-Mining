local HookStats = require("scripts/managers/stats/groups/hook_stats")
local MatchmakingConstants = require("scripts/settings/network/matchmaking_constants")
local PriorityQueue = require("scripts/foundation/utilities/priority_queue")
local HOST_TYPES = MatchmakingConstants.HOST_TYPES
local StatsManager = class("StatsManager")

function StatsManager:init()
	self._counter = 0
	self._last_time = 0
	self._player_to_ids = {}
	self._listeners = {}
	self._functions = {}
	self._account_id = {}
	self._stat_group = {}
	self._stat_data = {}
	self._queues = {}
end

function StatsManager:reset()
	self._counter = 0

	table.clear(self._player_to_ids)
	table.clear(self._listeners)
	table.clear(self._functions)
	table.clear(self._account_id)
	table.clear(self._stat_group)
	table.clear(self._stat_data)
	table.clear(self._queues)
end

function StatsManager:_get_id()
	self._counter = self._counter + 1

	return self._counter
end

function StatsManager:_attach_id_to_player(player, id)
	local account_id = player:account_id()
	self._account_id[id] = account_id
	self._player_to_ids[account_id] = self._player_to_ids[account_id] or {}
	self._player_to_ids[account_id][#self._player_to_ids[account_id] + 1] = id
end

function StatsManager:_remove_id_from_player(id)
	local account_id = self._account_id[id]
	local player_to_ids = self._player_to_ids[account_id]

	if not player_to_ids then
		return false, "Player not tracked"
	end

	local index = table.index_of(player_to_ids, id)

	if index == -1 then
		return false, "ID not tracked by player"
	end

	self._account_id[id] = nil
	local size = #player_to_ids

	if size == 1 then
		self._player_to_ids[account_id] = nil

		return true
	end

	player_to_ids[index] = player_to_ids[size]
	player_to_ids[size] = nil

	return true
end

function StatsManager:_add_tracker(listener, stat_group, optional_function_to_call, optional_initial_data)
	local id = self:_get_id()
	self._listeners[id] = listener
	self._functions[id] = optional_function_to_call
	self._stat_group[id] = stat_group
	self._stat_data[id] = optional_initial_data or {}
	self._queues[id] = PriorityQueue:new()

	return id
end

function StatsManager:add_tracker(listener, player, stat_group, optional_function_to_call, optional_initial_data)
	local id = self:_add_tracker(listener, stat_group, optional_function_to_call, optional_initial_data)

	self:_attach_id_to_player(player, id)

	return id
end

function StatsManager:add_global_tracker(listener, stat_group, optional_function_to_call, optional_initial_data)
	return self:_add_tracker(listener, stat_group, optional_function_to_call, optional_initial_data)
end

function StatsManager:remove_tracker(id)
	if self._account_id[id] then
		local removed, error = self:_remove_id_from_player(id)
	end

	local stat_data = self._stat_data[id]
	self._listeners[id] = nil
	self._functions[id] = nil
	self._stat_group[id] = nil
	self._stat_data[id] = nil
	self._queues[id] = nil

	return stat_data
end

function StatsManager:update(dt, t)
	self._last_time = t

	for id, queue in pairs(self._queues) do
		while not queue:empty() and queue:peek() < t do
			local _, delayed_trigger = queue:pop()
			local trigger_id = delayed_trigger[1]
			local trigger_value = delayed_trigger[2]
			local trigger_params = delayed_trigger[3]

			self:_on_triggered(id, trigger_id, trigger_value, unpack(trigger_params))
		end
	end
end

function StatsManager:_handle_trigger(id, trigger_id, trigger_time, triggered_value, ...)
	if not trigger_time then
		return
	end

	if trigger_time == 0 then
		self:_on_triggered(id, trigger_id, triggered_value, ...)
	else
		self._queues[id]:push(self._last_time + trigger_time, {
			trigger_id,
			triggered_value,
			{
				...
			}
		})
	end
end

function StatsManager:_check_triggered(id, stat_id_to_check, triggering_id, triggering_value, ...)
	local stat_definition = self._stat_group[id].definitions[stat_id_to_check]
	local stat_data = self._stat_data[id]

	self:_handle_trigger(id, stat_id_to_check, stat_definition:trigger(stat_data, triggering_id, triggering_value, ...))
end

function StatsManager:_on_triggered(id, trigger_id, trigger_value, ...)
	local listening_function = self._functions[id]
	local listener = self._listeners[id]

	if listening_function and listener then
		listening_function(listener, id, trigger_id, trigger_value, ...)
	end

	local dependents = self._stat_group[id].triggered_by[trigger_id]
	local dependent_count = dependents and #dependents or 0

	for i = 1, dependent_count do
		local stat_id_to_check = dependents[i]

		self:_check_triggered(id, stat_id_to_check, trigger_id, trigger_value, ...)
	end
end

function StatsManager:_trigger_hook(player, trigger_id, trigger_value, ...)
	local player_to_ids = self._player_to_ids[player:account_id()]
	local player_to_ids_count = player_to_ids and #player_to_ids or 0

	for i = 1, player_to_ids_count do
		local id = player_to_ids[i]

		self:_on_triggered(id, trigger_id, trigger_value, ...)
	end
end

function StatsManager:_trigger_global_hook(trigger_id, trigger_value, ...)
	for id, _ in pairs(self._queues) do
		self:_on_triggered(id, trigger_id, trigger_value, ...)
	end
end

function StatsManager.can_record_stats()
	if DEDICATED_SERVER then
		return true
	end

	return false
end

function StatsManager:record_mission_end(player, mission_name, main_objective_type, circumstance_name, difficulty, win, mission_time, team_kills, team_downs, team_deaths, side_objective_progress, side_objective_complete, side_objective_name, is_flash)
	side_objective_name = side_objective_name or "none"

	self:_trigger_hook(player, "hook_mission", 1, mission_name, main_objective_type, circumstance_name, difficulty, win, mission_time, team_kills, team_downs, team_deaths, side_objective_progress, side_objective_complete, side_objective_name, is_flash, player:profile().specialization)
end

function StatsManager:record_objective_complete(player, mission_name, objective_name, objective_type, objective_time)
	self:_trigger_hook(player, "hook_objective", 1, mission_name, objective_name, objective_type, objective_time, player:profile().specialization)
end

function StatsManager:record_damage(player, breed_name, weapon_template_name, damage_profile_name, weapon_attack_type, hit_zone_name, distance, player_health, action_name, id, damage, damage_type)
	breed_name = breed_name or "unknown"
	weapon_template_name = weapon_template_name or "unknown"
	weapon_attack_type = weapon_attack_type or "unknown"
	hit_zone_name = hit_zone_name or "unknown"
	action_name = action_name or "unknown"
	damage_profile_name = damage_profile_name or "unknown"
	damage_type = damage_type or "unknown"

	self:_trigger_hook(player, "hook_damage", damage, breed_name, weapon_template_name, weapon_attack_type, hit_zone_name, damage_profile_name, distance, player_health, action_name, id, damage_type, player:profile().specialization)
end

function StatsManager:record_kill(player, breed_name, weapon_template_name, weapon_attack_type, hit_zone_name, damage_profile_name, distance, player_health, action_name, id, buff_keywords, damage_type, solo_kill)
	breed_name = breed_name or "unknown"
	weapon_template_name = weapon_template_name or "unknown"
	weapon_attack_type = weapon_attack_type or "unknown"
	hit_zone_name = hit_zone_name or "unknown"
	action_name = action_name or "unknown"
	damage_profile_name = damage_profile_name or "unknown"
	damage_type = damage_type or "unknown"

	self:_trigger_hook(player, "hook_kill", 1, breed_name, weapon_template_name, weapon_attack_type, hit_zone_name, damage_profile_name, distance, player_health, action_name, id, buff_keywords, damage_type, solo_kill, player:profile().specialization)
end

function StatsManager:record_team_blocked_damage(amount)
	self:_trigger_global_hook("hook_team_blocked_damage", amount)
end

function StatsManager:record_blocked_damage(player, amount, weapon_template_name)
	self:_trigger_hook(player, "hook_blocked_damage", amount, weapon_template_name or "unknown", player:profile().specialization)
end

function StatsManager:record_team_kill(breed_name, weapon_attack_type)
	breed_name = breed_name or "unknown"
	weapon_attack_type = weapon_attack_type or "unknown"

	self:_trigger_global_hook("hook_team_kill", 1, breed_name, weapon_attack_type)
end

function StatsManager:record_toughness_regen(player, reason, amount)
	self:_trigger_hook(player, "hook_toughness_regenerated", amount, reason, player:profile().specialization)
end

function StatsManager:record_dodge(player, attacker_breed, attack_type, reason)
	attacker_breed = attacker_breed or "unknown"

	self:_trigger_hook(player, "hook_dodge", 1, attack_type, attacker_breed, reason, player:profile().specialization)
end

function StatsManager:record_respawn_ally(player, target_player)
	self:_trigger_hook(player, "hook_respawn_ally", 1, target_player:session_id(), player:profile().specialization)
end

function StatsManager:record_help_ally(player, target_player)
	self:_trigger_hook(player, "hook_help_ally", 1, target_player:session_id(), player:profile().specialization)
end

function StatsManager:record_collect_material(type, size)
	type = type or "unknown"
	local amount = size == "large" and 10 or size == "small" and 5 or 0

	self:_trigger_global_hook("hook_collect_material", amount, type)
end

function StatsManager:record_pickup_item(player, pickup_name)
	self:_trigger_hook(player, "hook_pickup_item", 1, pickup_name, player:profile().specialization)
end

function StatsManager:record_place_item(player, pickup_name)
	self:_trigger_hook(player, "hook_place_item", 1, pickup_name, player:profile().specialization)
end

function StatsManager:record_share_item(player, pickup_name)
	self:_trigger_hook(player, "hook_share_item", 1, pickup_name, player:profile().specialization)
end

function StatsManager:record_player_death(player)
	self:_trigger_hook(player, "hook_death", 1, player:profile().specialization)
end

function StatsManager:record_player_knock_down(player)
	self:_trigger_hook(player, "hook_knock_down", 1, player:profile().specialization)
end

function StatsManager:record_player_damage_taken(player, amount, attack_type)
	self:_trigger_hook(player, "hook_damage_taken", amount, player:profile().specialization, attack_type)
end

function StatsManager:record_team_damage_taken(amount)
	self:_trigger_global_hook("hook_team_damage_taken", amount)
end

function StatsManager:record_team_death()
	self:_trigger_global_hook("hook_team_death", 1)
end

function StatsManager:record_team_knock_down()
	self:_trigger_global_hook("hook_team_knock_down", 1)
end

function StatsManager:record_player_joined(player, current_travel_ratio)
	self:_trigger_hook(player, "hook_player_joined", current_travel_ratio, player:profile().specialization)
end

function StatsManager:record_player_spawned(player)
	self:_trigger_hook(player, "hook_spawn_player", player:profile().current_level, player:profile().specialization)
end

function StatsManager:record_hacked_terminal(player, mistakes)
	self:_trigger_hook(player, "hook_hacked_terminal", 1, mistakes, player:profile().specialization)
end

function StatsManager:record_scanned_objects(player, amount)
	self:_trigger_hook(player, "hook_scanned_objects", amount, player:profile().specialization)
end

function StatsManager:record_team_corruptor_destroyed()
	self:_trigger_global_hook("hook_team_corruptor_destroyed", 1)
end

function StatsManager:record_boss_death(max_health, id, breed_name, time_since_first_damage, action)
	self:_trigger_global_hook("hook_boss_kill", 1, breed_name, max_health, id, time_since_first_damage, action)
end

function StatsManager:record_coherency_exit(player, is_exiter_alive)
	self:_trigger_hook(player, "hook_coherency_exit", 1, is_exiter_alive, player:profile().specialization)
end

function StatsManager:record_health_update(player, current_health_percentage, is_knocked_down)
	self:_trigger_hook(player, "hook_health_update", current_health_percentage, is_knocked_down, player:profile().specialization)
end

function StatsManager:record_ranged_attack_concluded(player, hit_minion, hit_weakspot, kill, last_round_in_mag)
	self:_trigger_hook(player, "hook_ranged_attack_concluded", 1, hit_minion, hit_weakspot, kill, last_round_in_mag, player:profile().specialization)
end

function StatsManager:record_alternate_fire_start(player)
	self:_trigger_hook(player, "hook_alternate_fire_start", 1)
end

function StatsManager:record_alternate_fire_stop(player)
	self:_trigger_hook(player, "hook_alternate_fire_stop", 1)
end

function StatsManager:record_ammo_consumed(player, slot_name, amount, remaining_clip, remaining_reserve)
	self:_trigger_hook(player, "hook_ammo_consumed", 1, slot_name, amount, remaining_clip, remaining_reserve)
end

function StatsManager:record_decoder_ignored()
	self:_trigger_global_hook("hook_decoder_ignored")
end

function StatsManager:record_lunge_start(player)
	self:_trigger_hook(player, "hook_lunge_start", 1)
end

function StatsManager:record_lunge_distance(player, distance_lunged)
	self:_trigger_hook(player, "hook_lunge_distance", distance_lunged, player:profile().specialization)
end

function StatsManager:record_lunge_stop(player, number_of_enemies)
	self:_trigger_hook(player, "hook_lunge_stop", number_of_enemies, player:profile().specialization)
end

function StatsManager:record_volley_fire_start(player)
	self:_trigger_hook(player, "hook_volley_fire_start", 1)
end

function StatsManager:record_volley_fire_stop(player)
	self:_trigger_hook(player, "hook_volley_fire_stop", 1)
end

function StatsManager:record_zealot_2_health_healed_with_leech_during_resist_death(player, health_ammount_percentage)
	local round_health_percentage_to_int = math.round(health_ammount_percentage * 100)

	self:_trigger_hook(player, "hook_zealot_2_health_healed_with_leech_during_resist_death", round_health_percentage_to_int, player:profile().specialization)
end

function StatsManager:record_psyker_2_at_max_stack(player, time_at_max)
	self:_trigger_hook(player, "hook_psyker_2_max_souls_hook", time_at_max, player:profile().specialization)
end

return StatsManager
