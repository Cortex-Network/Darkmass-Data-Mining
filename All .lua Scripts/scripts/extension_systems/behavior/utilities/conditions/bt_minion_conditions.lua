local AttackIntensity = require("scripts/utilities/attack_intensity")
local conditions = {}

function conditions.has_target_unit(unit, blackboard, scratchpad, condition_args, action_data, is_running)
	local perception_component = blackboard.perception

	if not is_running and perception_component.lock_target then
		return false
	end

	local target_unit = perception_component.target_unit

	return HEALTH_ALIVE[target_unit]
end

function conditions.is_dead(unit, blackboard, scratchpad, condition_args, action_data, is_running)
	local death_component = blackboard.death
	local is_dead = death_component.is_dead

	return is_dead
end

function conditions.is_in_cover(unit, blackboard, scratchpad, condition_args, action_data, is_running)
	local cover_component = blackboard.cover
	local is_in_cover = cover_component.is_in_cover

	return is_in_cover
end

function conditions.is_alerted(unit, blackboard, scratchpad, condition_args, action_data, is_running)
	local has_target_unit = conditions.has_target_unit(unit, blackboard, scratchpad, condition_args, action_data, is_running)

	if not has_target_unit then
		return false
	end

	local perception_component = blackboard.perception
	local is_alerted_aggro_state = perception_component.aggro_state == "alerted"

	return is_alerted_aggro_state
end

function conditions.is_aggroed(unit, blackboard, scratchpad, condition_args, action_data, is_running)
	local has_target_unit = conditions.has_target_unit(unit, blackboard, scratchpad, condition_args, action_data, is_running)

	if not has_target_unit then
		return false
	end

	local perception_component = blackboard.perception
	local is_aggroed = perception_component.aggro_state == "aggroed"

	return is_aggroed
end

function conditions.has_cover(unit, blackboard, scratchpad, condition_args, action_data, is_running)
	local is_aggroed = conditions.is_aggroed(unit, blackboard, scratchpad, condition_args, action_data, is_running)

	if not is_aggroed then
		return false
	end

	local behavior_component = blackboard.behavior
	local combat_range = behavior_component.combat_range
	local combat_ranges = condition_args.combat_ranges

	if not combat_ranges[combat_range] then
		return false
	end

	local cover_component = blackboard.cover
	local has_cover = cover_component.has_cover

	return has_cover
end

function conditions.is_aggroed_in_combat_range(unit, blackboard, scratchpad, condition_args, action_data, is_running)
	local is_aggroed = conditions.is_aggroed(unit, blackboard, scratchpad, condition_args, action_data, is_running)

	if not is_aggroed then
		return false
	end

	local behavior_component = blackboard.behavior
	local combat_range = behavior_component.combat_range
	local condition_combat_ranges = condition_args.combat_ranges

	return condition_combat_ranges[combat_range]
end

function conditions.should_switch_weapon(unit, blackboard, scratchpad, condition_args, action_data, is_running)
	local weapon_switch_component = blackboard.weapon_switch
	local visual_loadout_extension = ScriptUnit.extension(unit, "visual_loadout_system")
	local wanted_weapon_slot = weapon_switch_component.wanted_weapon_slot
	local wielded_slot_name = visual_loadout_extension:wielded_slot_name()

	if scratchpad.is_switching_weapons or wanted_weapon_slot ~= "unarmed" and wanted_weapon_slot ~= wielded_slot_name then
		return true
	end
end

function conditions.is_exiting_spawner(unit, blackboard, scratchpad, condition_args, action_data, is_running)
	local spawn_component = blackboard.spawn

	return spawn_component.is_exiting_spawner
end

function conditions.at_smart_object(unit, blackboard, scratchpad, condition_args, action_data, is_running)
	local nav_smart_object_component = blackboard.nav_smart_object
	local smart_object_id = nav_smart_object_component.id
	local smart_object_is_next = smart_object_id ~= -1

	if not smart_object_is_next then
		return false
	end

	local navigation_extension = ScriptUnit.extension(unit, "navigation_system")
	local is_smart_objecting = navigation_extension:is_using_smart_object()

	if is_smart_objecting then
		return true
	end

	local smart_object_unit = nav_smart_object_component.unit

	if not ALIVE[smart_object_unit] then
		return false
	end

	local nav_graph_extension = ScriptUnit.extension(smart_object_unit, "nav_graph_system")
	local nav_graph_added = nav_graph_extension:nav_graph_added(smart_object_id)

	if not nav_graph_added then
		return false
	end

	local behavior_component = blackboard.behavior
	local is_in_moving_state = behavior_component.move_state == "moving"
	local entrance_is_at_bot_progress_on_path = nav_smart_object_component.entrance_is_at_bot_progress_on_path

	return is_in_moving_state and entrance_is_at_bot_progress_on_path
end

function conditions.at_teleport_smart_object(unit, blackboard, scratchpad, condition_args, action_data, is_running)
	local nav_smart_object_component = blackboard.nav_smart_object
	local smart_object_type = nav_smart_object_component.type
	local is_smart_object_teleporter = smart_object_type == "teleporters"

	return is_smart_object_teleporter
end

function conditions.at_jump_smart_object(unit, blackboard, scratchpad, condition_args, action_data, is_running)
	local nav_smart_object_component = blackboard.nav_smart_object
	local smart_object_type = nav_smart_object_component.type
	local is_smart_object_jump = smart_object_type == "jumps" or smart_object_type == "cover_vaults"

	return is_smart_object_jump
end

function conditions.at_smashable_obstacle_smart_object(unit, blackboard, scratchpad, condition_args, action_data, is_running)
	local nav_smart_object_component = blackboard.nav_smart_object
	local smart_object_type = nav_smart_object_component.type

	if smart_object_type == "monster_walls" then
		local wall_unit = nav_smart_object_component.unit

		return HEALTH_ALIVE[wall_unit]
	elseif smart_object_type == "doors" then
		local door_unit = nav_smart_object_component.unit
		local door_extension = ScriptUnit.extension(door_unit, "door_system")

		if not door_extension:can_attack() then
			return false
		end

		local health_extension = ScriptUnit.has_extension(door_unit, "health_system")

		return health_extension ~= nil
	else
		return false
	end
end

function conditions.at_door_smart_object(unit, blackboard, scratchpad, condition_args, action_data, is_running)
	local nav_smart_object_component = blackboard.nav_smart_object
	local smart_object_type = nav_smart_object_component.type
	local is_smart_object_door = smart_object_type == "doors"

	if not is_smart_object_door then
		return false
	end

	local door_unit = nav_smart_object_component.unit
	local door_extension = ScriptUnit.extension(door_unit, "door_system")
	local num_attackers = door_extension:num_attackers()

	return num_attackers <= 0
end

function conditions.at_climb_smart_object(unit, blackboard, scratchpad, condition_args, action_data, is_running)
	local nav_smart_object_component = blackboard.nav_smart_object
	local smart_object_type = nav_smart_object_component.type
	local is_smart_object_ledge = smart_object_type == "ledges" or smart_object_type == "ledges_with_fence" or smart_object_type == "cover_ledges"

	return is_smart_object_ledge
end

function conditions.attack_allowed(unit, blackboard, scratchpad, condition_args, action_data, is_running)
	local perception_component = blackboard.perception

	if not is_running and perception_component.lock_target then
		return false
	end

	if is_running then
		return true
	end

	local target_unit = perception_component.target_unit
	local attack_allowed = AttackIntensity.minion_can_attack(unit, condition_args.attack_type, target_unit)

	return attack_allowed
end

function conditions.attack_not_allowed(unit, blackboard, scratchpad, condition_args, action_data, is_running)
	local perception_component = blackboard.perception

	if not is_running and perception_component.lock_target then
		return false
	end

	local target_unit = perception_component.target_unit
	local attack_allowed = AttackIntensity.minion_can_attack(unit, condition_args.attack_type, target_unit)

	return not attack_allowed
end

function conditions.moving_attack_allowed(unit, blackboard, scratchpad, condition_args, action_data, is_running)
	local perception_component = blackboard.perception

	if not is_running and perception_component.lock_target then
		return false
	end

	local navigation_extension = ScriptUnit.extension(unit, "navigation_system")
	local has_path = navigation_extension:has_path()

	if not has_path then
		return false
	end

	local min_needed_path_distance = 5
	local has_upcoming_smart_object, _ = navigation_extension:path_distance_to_next_smart_object(min_needed_path_distance)

	if has_upcoming_smart_object then
		return false
	end

	if is_running then
		return true
	end

	local slot_component = blackboard.slot
	local has_slot = slot_component.has_slot and not slot_component.has_ghost_slot

	if not has_slot then
		return false
	end

	local behavior_component = blackboard.behavior
	local move_state = behavior_component.move_state
	local is_following_path = navigation_extension:is_following_path()

	if move_state ~= "moving" or not is_following_path then
		return false
	end

	if condition_args and condition_args.attack_type then
		local target_unit = perception_component.target_unit
		local attack_allowed = AttackIntensity.minion_can_attack(unit, condition_args.attack_type, target_unit)

		return attack_allowed
	else
		return true
	end
end

function conditions.not_assaulting(unit, blackboard, scratchpad, condition_args, action_data, is_running)
	if scratchpad.is_assaulting then
		return false
	end

	return true
end

function conditions.should_run_stop_and_shoot(unit, blackboard, scratchpad, condition_args, action_data, is_running)
	local perception_component = blackboard.perception

	if not is_running and perception_component.lock_target then
		return false
	end

	if not is_running or not scratchpad.is_anim_driven then
		local navigation_extension = ScriptUnit.extension(unit, "navigation_system")
		local is_following_path = navigation_extension:is_following_path()

		if not is_following_path then
			return false
		end

		local min_needed_path_distance = action_data.move_distance
		local has_upcoming_smart_object, _ = navigation_extension:path_distance_to_next_smart_object(min_needed_path_distance)

		if has_upcoming_smart_object then
			return false
		end

		local remaining_path_distance = navigation_extension:remaining_distance_from_progress_to_end_of_path()

		if remaining_path_distance <= min_needed_path_distance then
			return false
		end
	end

	if is_running then
		return true
	end

	local behavior_component = blackboard.behavior
	local move_state = behavior_component.move_state

	if move_state ~= "moving" then
		return false
	end

	local target_unit = perception_component.target_unit
	local attack_allowed = AttackIntensity.minion_can_attack(unit, "ranged", target_unit)

	if not attack_allowed then
		return false
	end

	local enter_combat_range_flag = behavior_component.enter_combat_range_flag

	return enter_combat_range_flag
end

function conditions.should_strafe_shoot(unit, blackboard, scratchpad, condition_args, action_data, is_running)
	local navigation_extension = ScriptUnit.extension(unit, "navigation_system")
	local is_following_path = navigation_extension:is_following_path()

	if not is_following_path then
		return false
	end

	local min_needed_path_distance = 5
	local has_upcoming_smart_object, _ = navigation_extension:path_distance_to_next_smart_object(min_needed_path_distance)

	if has_upcoming_smart_object then
		return false
	end

	if is_running then
		return true
	end

	local behavior_component = blackboard.behavior
	local move_state = behavior_component.move_state

	return move_state == "moving"
end

function conditions.should_step_shoot(unit, blackboard, scratchpad, condition_args, action_data, is_running)
	local perception_component = blackboard.perception

	if not is_running and perception_component.lock_target then
		return false
	end

	local navigation_extension = ScriptUnit.extension(unit, "navigation_system")
	local is_on_wait_time = navigation_extension:is_on_wait_time()

	if is_on_wait_time then
		return false
	end

	if is_running then
		return true
	end

	local target_unit = perception_component.target_unit
	local attack_allowed = AttackIntensity.minion_can_attack(unit, condition_args.attack_type, target_unit)

	return attack_allowed
end

function conditions.is_suppressed(unit, blackboard, scratchpad, condition_args, action_data, is_running)
	local suppression_component = blackboard.suppression
	local is_suppressed = suppression_component.is_suppressed

	return is_suppressed
end

function conditions.is_staggered(unit, blackboard, scratchpad, condition_args, action_data, is_running)
	local stagger_component = blackboard.stagger
	local is_staggered = stagger_component.num_triggered_staggers > 0

	return is_staggered
end

function conditions.is_blocked(unit, blackboard, scratchpad, condition_args, action_data, is_running)
	local blocked_component = blackboard.blocked
	local is_blocked = blocked_component.is_blocked

	return is_blocked
end

function conditions.should_use_combat_idle(unit, blackboard, scratchpad, condition_args, action_data, is_running)
	local slot_component = blackboard.slot
	local is_waiting_on_slot = slot_component.is_waiting_on_slot

	if is_waiting_on_slot then
		local navigation_extension = ScriptUnit.extension(unit, "navigation_system")
		local has_reached_destination = navigation_extension:has_reached_destination()

		return has_reached_destination
	end
end

function conditions.has_pounce_target(unit, blackboard, scratchpad, condition_args, action_data, is_running)
	local pounce_component = blackboard.pounce
	local has_pounce_target = ALIVE[pounce_component.pounce_target]

	return has_pounce_target
end

function conditions.has_clear_shot(unit, blackboard, scratchpad, condition_args, action_data, is_running)
	if is_running then
		return true
	end

	local perception_component = blackboard.perception
	local target_unit = perception_component.target_unit
	local line_of_sight_id = action_data.clear_shot_line_of_sight_id
	local perception_extension = ScriptUnit.extension(unit, "perception_system")
	local has_clear_shot = perception_extension:has_line_of_sight_by_id(target_unit, line_of_sight_id)

	return has_clear_shot
end

function conditions.dont_have_clear_shot(unit, blackboard, scratchpad, condition_args, action_data, is_running)
	if is_running then
		return true
	end

	local perception_component = blackboard.perception
	local target_unit = perception_component.target_unit
	local line_of_sight_id = action_data.line_of_sight_id
	local perception_extension = ScriptUnit.extension(unit, "perception_system")
	local has_clear_shot = perception_extension:has_line_of_sight_by_id(target_unit, line_of_sight_id)

	return not has_clear_shot
end

function conditions.can_shoot_net(unit, blackboard, scratchpad, condition_args, action_data, is_running)
	local behavior_component = blackboard.behavior
	local shoot_net_cooldown = behavior_component.shoot_net_cooldown
	local t = Managers.time:time("gameplay")

	return shoot_net_cooldown <= t
end

function conditions.netgunner_is_on_cooldown(unit, blackboard, scratchpad, condition_args, action_data, is_running)
	local behavior_component = blackboard.behavior
	local shoot_net_cooldown = behavior_component.shoot_net_cooldown
	local t = Managers.time:time("gameplay")

	return t < shoot_net_cooldown
end

function conditions.netgunner_hit_target(unit, blackboard, scratchpad, condition_args, action_data, is_running)
	local behavior_component = blackboard.behavior
	local hit_target = behavior_component.hit_target

	return hit_target
end

function conditions.daemonhost_can_warp_grab(unit, blackboard, scratchpad, condition_args, action_data, is_running)
	if is_running then
		return true
	end

	local is_aggroed = conditions.is_aggroed(unit, blackboard, scratchpad, condition_args, action_data, is_running)

	if not is_aggroed then
		return
	end

	local perception_component = blackboard.perception
	local target_unit = perception_component.target_unit
	local unit_data_extension = ScriptUnit.extension(target_unit, "unit_data_system")
	local character_state_component = unit_data_extension:read_component("character_state")
	local PlayerUnitStatus = require("scripts/utilities/attack/player_unit_status")
	local is_knocked_down = PlayerUnitStatus.is_knocked_down(character_state_component)
	local hit_unit_data_extension = ScriptUnit.extension(target_unit, "unit_data_system")
	local disabled_state_input = hit_unit_data_extension:read_component("disabled_state_input")
	local is_disabled_by_this_deamonhost = disabled_state_input.disabling_unit == unit

	return is_knocked_down or is_disabled_by_this_deamonhost
end

function conditions.chaos_hound_is_aggroed(unit, blackboard, scratchpad, condition_args, action_data, is_running)
	local is_aggroed = conditions.is_aggroed(unit, blackboard, scratchpad, condition_args, action_data, is_running)
	local pounce_component = blackboard.pounce

	return is_aggroed or pounce_component.started_leap
end

function conditions.chaos_hound_can_pounce(unit, blackboard, scratchpad, condition_args, action_data, is_running)
	local pounce_component = blackboard.pounce
	local pounce_cooldown = pounce_component.pounce_cooldown
	local t = Managers.time:time("gameplay")

	return pounce_cooldown <= t
end

function conditions.chaos_hound_pounce_is_on_cooldown(unit, blackboard, scratchpad, condition_args, action_data, is_running)
	local pounce_component = blackboard.pounce
	local pounce_cooldown = pounce_component.pounce_cooldown
	local t = Managers.time:time("gameplay")

	return t <= pounce_cooldown
end

function conditions.can_throw_grenade(unit, blackboard, scratchpad, condition_args, action_data, is_running)
	local behavior_component = blackboard.throw_grenade
	local next_throw_at_t = behavior_component.next_throw_at_t
	local t = Managers.time:time("gameplay")

	return next_throw_at_t <= t
end

function conditions.slot_not_wielded(unit, blackboard, scratchpad, condition_args, action_data, is_running)
	local visual_loadout_extension = ScriptUnit.extension(unit, "visual_loadout_system")
	local wielded_slot_name = visual_loadout_extension:wielded_slot_name()
	local wanted_slot_name = condition_args.slot_name

	return wielded_slot_name ~= wanted_slot_name
end

function conditions.slot_wielded(unit, blackboard, scratchpad, condition_args, action_data, is_running)
	local visual_loadout_extension = ScriptUnit.extension(unit, "visual_loadout_system")
	local wielded_slot_name = visual_loadout_extension:wielded_slot_name()
	local wanted_slot_name = condition_args.slot_name

	return wielded_slot_name == wanted_slot_name
end

function conditions.daemonhost_wants_to_leave(unit, blackboard, scratchpad, condition_args, action_data, is_running)
	local target_side_id = 1
	local side_system = Managers.state.extension:system("side_system")
	local side = side_system:get_side(target_side_id)
	local target_units = side.valid_player_units
	local num_valid_target_units = #target_units
	local num_alive_targets = 0

	for i = 1, num_valid_target_units do
		local player_unit = target_units[i]

		if HEALTH_ALIVE[player_unit] then
			num_alive_targets = num_alive_targets + 1
		end
	end

	local statistics_component = blackboard.statistics
	local valid_targets_on_aggro = statistics_component.valid_targets_on_aggro

	if valid_targets_on_aggro > 1 and num_alive_targets == 1 then
		return true
	end

	local DaemonhostSettings = require("scripts/settings/specials/daemonhost_settings")
	local num_player_kills_for_despawn = Managers.state.difficulty:get_table_entry_by_challenge(DaemonhostSettings.num_player_kills_for_despawn)
	local num_dead_players = valid_targets_on_aggro - num_alive_targets
	local wants_to_leave = num_player_kills_for_despawn <= num_dead_players

	return wants_to_leave
end

function conditions.daemonhost_is_passive(unit, blackboard, scratchpad, condition_args, action_data, is_running)
	local perception_component = blackboard.perception
	local aggro_state = perception_component.aggro_state
	local should_be_passive = aggro_state == "alerted" or aggro_state == "passive"

	return should_be_passive
end

function conditions.daemonhost_can_warp_sweep(unit, blackboard, scratchpad, condition_args, action_data, is_running)
	if is_running then
		return true
	end

	local behavior_component = blackboard.behavior
	local t = Managers.time:time("gameplay")

	if t < behavior_component.warp_sweep_cooldown then
		return false
	end

	local num_nearby_units_threshold = action_data.num_nearby_units_threshold
	local broadphase_component = blackboard.nearby_units_broadphase
	local num_broadphase_units = broadphase_component.num_units

	return num_nearby_units_threshold <= num_broadphase_units
end

function conditions.target_changed_and_valid(unit, blackboard, scratchpad, condition_args, action_data, is_running)
	if is_running then
		return true
	end

	local perception_component = blackboard.perception

	if perception_component.target_changed then
		local new_target_unit = perception_component.target_unit

		return new_target_unit and ALIVE[new_target_unit]
	end

	return false
end

function conditions.is_aggroed_in_combat_range_or_running(unit, blackboard, scratchpad, condition_args, action_data, is_running)
	local is_aggroed = conditions.is_aggroed(unit, blackboard, scratchpad, condition_args, action_data, is_running)

	if not is_aggroed then
		return false
	end

	if is_running then
		return true
	end

	local behavior_component = blackboard.behavior
	local combat_range = behavior_component.combat_range
	local condition_combat_ranges = condition_args.combat_ranges

	return condition_combat_ranges[combat_range]
end

function conditions.should_patrol(unit, blackboard, scratchpad, condition_args, action_data, is_running)
	local has_target_unit = conditions.has_target_unit(unit, blackboard, scratchpad, condition_args, action_data, is_running)

	if has_target_unit then
		return false
	end

	local patrol_component = blackboard.patrol
	local should_patrol = patrol_component.should_patrol
	local perception_component = blackboard.perception
	local aggro_state = perception_component.aggro_state
	local is_passive = aggro_state == "passive"

	return is_passive and should_patrol
end

function conditions.captain_can_use_special_actions(unit, blackboard, scratchpad, condition_args, action_data, is_running)
	local captain_can_use_special_action = not scratchpad.is_blocking_captain_special_actions

	return captain_can_use_special_action
end

function conditions.beast_of_nurgle_has_consume_target(unit, blackboard, scratchpad, condition_args, action_data, is_running)
	local has_target_unit = conditions.has_target_unit(unit, blackboard, scratchpad, condition_args, action_data, is_running)

	if not has_target_unit then
		return false
	end

	local behavior_component = blackboard.behavior
	local scratchpad_consumed_unit = scratchpad.consumed_unit

	if HEALTH_ALIVE[scratchpad_consumed_unit] then
		return true
	end

	local consumed_unit = behavior_component.consumed_unit

	if HEALTH_ALIVE[consumed_unit] then
		return false
	end

	local perception_component = blackboard.perception
	local target_unit = perception_component.target_unit
	local target_unit_data_extension = ScriptUnit.extension(target_unit, "unit_data_system")
	local character_state_component = target_unit_data_extension:read_component("character_state")
	local PlayerUnitStatus = require("scripts/utilities/attack/player_unit_status")
	local is_disabled = PlayerUnitStatus.is_disabled(character_state_component)

	if is_disabled then
		return false
	end

	local buff_extension = ScriptUnit.extension(target_unit, "buff_system")
	local vomit_buff_name = "chaos_beast_of_nurgle_hit_by_vomit"
	local current_stacks = buff_extension:current_stacks(vomit_buff_name)
	local wants_to_eat = behavior_component.wants_to_eat

	return current_stacks == 3 or wants_to_eat
end

function conditions.beast_of_nurgle_can_consume_minion(unit, blackboard, scratchpad, condition_args, action_data, is_running)
	if is_running then
		return true
	end

	local behavior_component = blackboard.behavior
	local t = Managers.time:time("gameplay")

	if t < behavior_component.consume_minion_cooldown then
		return false
	end

	local health_extension = ScriptUnit.extension(unit, "health_system")
	local current_health_percent = health_extension:current_health_percent()

	if action_data.health_percent_threshold < current_health_percent then
		return false
	end

	local num_nearby_units_threshold = action_data.num_nearby_units_threshold
	local broadphase_component = blackboard.nearby_units_broadphase
	local num_broadphase_units = broadphase_component.num_units

	return num_nearby_units_threshold <= num_broadphase_units
end

function conditions.beast_of_nurgle_should_vomit(unit, blackboard, scratchpad, condition_args, action_data, is_running)
	local behavior_component = blackboard.behavior
	local vomit_cooldown = behavior_component.vomit_cooldown
	local t = Managers.time:time("gameplay")

	if t < vomit_cooldown then
		return false
	end

	local is_aggroed = conditions.is_aggroed(unit, blackboard, scratchpad, condition_args, action_data, is_running)

	if not is_aggroed then
		return false
	end

	if is_running then
		return true
	end

	local perception_component = blackboard.perception

	if not perception_component.has_line_of_sight then
		return false
	end

	local target_unit = perception_component.target_unit
	local line_of_sight_id = "vomit"
	local perception_extension = ScriptUnit.extension(unit, "perception_system")
	local has_clear_shot = perception_extension:has_line_of_sight_by_id(target_unit, line_of_sight_id)

	if not has_clear_shot then
		return false
	end

	local target_distance_z = perception_component.target_distance_z

	if target_distance_z >= 3 then
		return false
	end

	local target_distance = perception_component.target_distance
	local wanted_distance = condition_args.wanted_distance

	if wanted_distance < target_distance then
		return false
	end

	return true
end

function conditions.beast_of_nurgle_has_spit_out_target(unit, blackboard, scratchpad, condition_args, action_data, is_running)
	local is_aggroed = conditions.is_aggroed(unit, blackboard, scratchpad, condition_args, action_data, is_running)

	if not is_aggroed then
		return false
	end

	local behavior_component = blackboard.behavior
	local consumed_unit = behavior_component.consumed_unit

	if not HEALTH_ALIVE[consumed_unit] then
		return false
	end

	if is_running then
		return true
	end

	if behavior_component.force_spit_out then
		return true
	end

	local health_extension = ScriptUnit.extension(consumed_unit, "health_system")
	local permanent_damage_taken_percent = health_extension:permanent_damage_taken_percent()
	local required_permanent_damage_taken_percent = Managers.state.difficulty:get_table_entry_by_challenge(action_data.required_permanent_damage_taken_percent)

	if permanent_damage_taken_percent < required_permanent_damage_taken_percent then
		return false
	end

	return true
end

function conditions.beast_of_nurgle_can_melee(unit, blackboard, scratchpad, condition_args, action_data, is_running)
	local behavior_component = blackboard.behavior
	local melee_cooldown = behavior_component.melee_cooldown
	local t = Managers.time:time("gameplay")

	if t < melee_cooldown then
		return false
	end

	return true
end

function conditions.beast_of_nurgle_can_aoe_melee(unit, blackboard, scratchpad, condition_args, action_data, is_running)
	local behavior_component = blackboard.behavior
	local melee_aoe_cooldown = behavior_component.melee_aoe_cooldown
	local t = Managers.time:time("gameplay")

	if t < melee_aoe_cooldown then
		return false
	end

	return true
end

function conditions.beast_of_nurgle_can_vomit(unit, blackboard, scratchpad, condition_args, action_data, is_running)
	local behavior_component = blackboard.behavior
	local vomit_cooldown = behavior_component.vomit_cooldown
	local t = Managers.time:time("gameplay")

	if t < vomit_cooldown then
		return false
	end

	return true
end

function conditions.beast_of_nurgle_melee_tail_whip(unit, blackboard, scratchpad, condition_args, action_data, is_running)
	local is_aggroed = conditions.is_aggroed(unit, blackboard, scratchpad, condition_args, action_data, is_running)

	if not is_aggroed then
		return false
	end

	if is_running then
		return true
	end

	local target_side_id = 1
	local side_system = Managers.state.extension:system("side_system")
	local side = side_system:get_side(target_side_id)
	local target_units = side.valid_player_units
	local num_valid_target_units = #target_units
	local position = POSITION_LOOKUP[unit]
	local fwd = Quaternion.forward(Unit.local_rotation(unit, 1))
	local radius = action_data.radius
	local has_valid_target = false
	local behavior_component = blackboard.behavior
	local consumed_unit = behavior_component.consumed_unit
	local PlayerUnitStatus = require("scripts/utilities/attack/player_unit_status")
	local perception_extension = ScriptUnit.extension(unit, "perception_system")
	local perception_component = blackboard.perception
	local target_unit = perception_component.target_unit

	for i = 1, num_valid_target_units do
		local player_unit = target_units[i]

		if HEALTH_ALIVE[player_unit] and player_unit ~= consumed_unit and player_unit ~= target_unit then
			local has_line_of_sight_to_target = perception_extension:has_line_of_sight(player_unit)

			if has_line_of_sight_to_target then
				local target_unit_data_extension = ScriptUnit.extension(player_unit, "unit_data_system")
				local character_state_component = target_unit_data_extension:read_component("character_state")
				local is_disabled = PlayerUnitStatus.is_disabled(character_state_component)

				if not is_disabled then
					local player_position = POSITION_LOOKUP[player_unit]
					local distance = Vector3.distance(position, player_position)

					if distance <= radius then
						local to_player = Vector3.normalize(Vector3.flat(player_position - position))
						local dot = Vector3.dot(fwd, to_player)
						local is_to_the_left = Vector3.cross(fwd, to_player).z > 0

						if condition_args.check_fwd_left then
							if dot >= 0.6 and dot < 0.9 and is_to_the_left then
								has_valid_target = true

								break
							end
						elseif condition_args.check_fwd_right then
							if dot >= 0.6 and dot < 0.9 and not is_to_the_left then
								has_valid_target = true

								break
							end
						elseif condition_args.check_bwd then
							if dot < -0.8 then
								has_valid_target = true

								break
							end
						elseif condition_args.check_right then
							if dot < 0.6 and not is_to_the_left then
								has_valid_target = true

								break
							end
						elseif condition_args.check_left and dot < 0.6 and is_to_the_left then
							has_valid_target = true

							break
						end
					end
				end
			end
		end
	end

	return has_valid_target
end

function conditions.beast_of_nurgle_wants_to_run_away(unit, blackboard, scratchpad, condition_args, action_data, is_running)
	local is_aggroed = conditions.is_aggroed(unit, blackboard, scratchpad, condition_args, action_data, is_running)

	if not is_aggroed then
		return false
	end

	local behavior_component = blackboard.behavior
	local consumed_unit = behavior_component.consumed_unit

	if not HEALTH_ALIVE[consumed_unit] then
		return false
	end

	local health_extension = ScriptUnit.extension(consumed_unit, "health_system")
	local permanent_damage_taken_percent = health_extension:permanent_damage_taken_percent()

	if permanent_damage_taken_percent >= 0.5 then
		return false
	end

	return true
end

function conditions.beast_of_nurgle_melee_body_slam_aoe(unit, blackboard, scratchpad, condition_args, action_data, is_running)
	local is_aggroed = conditions.is_aggroed(unit, blackboard, scratchpad, condition_args, action_data, is_running)

	if not is_aggroed then
		return false
	end

	if is_running then
		return true
	end

	local behavior_component = blackboard.behavior
	local melee_aoe_cooldown = behavior_component.melee_aoe_cooldown
	local t = Managers.time:time("gameplay")

	if t < melee_aoe_cooldown then
		return false
	end

	local perception_component = blackboard.perception
	local target_unit = perception_component.target_unit
	local buff_extension = ScriptUnit.extension(target_unit, "buff_system")
	local vomit_buff_name = "chaos_beast_of_nurgle_hit_by_vomit"
	local target_is_vomited = buff_extension:current_stacks(vomit_buff_name) > 0

	if target_is_vomited then
		return false
	end

	local target_side_id = 1
	local side_system = Managers.state.extension:system("side_system")
	local side = side_system:get_side(target_side_id)
	local target_units = side.valid_player_units
	local num_valid_target_units = #target_units
	local position = POSITION_LOOKUP[unit]
	local radius = action_data.radius
	local consumed_unit = behavior_component.consumed_unit
	local PlayerUnitStatus = require("scripts/utilities/attack/player_unit_status")
	local perception_extension = ScriptUnit.extension(unit, "perception_system")
	local num_close_players = 0
	local has_very_close_player = false

	for i = 1, num_valid_target_units do
		local player_unit = target_units[i]

		if HEALTH_ALIVE[player_unit] and player_unit ~= consumed_unit then
			local has_line_of_sight_to_target = perception_extension:has_line_of_sight(player_unit)

			if has_line_of_sight_to_target then
				local target_unit_data_extension = ScriptUnit.extension(player_unit, "unit_data_system")
				local character_state_component = target_unit_data_extension:read_component("character_state")
				local is_disabled = PlayerUnitStatus.is_disabled(character_state_component)

				if not is_disabled then
					local player_position = POSITION_LOOKUP[player_unit]
					local distance = Vector3.distance(position, player_position)

					if player_unit ~= target_unit and distance < action_data.very_close_distance then
						has_very_close_player = true

						break
					end

					if distance <= radius then
						num_close_players = num_close_players + 1
					end
				end
			end
		end
	end

	return has_very_close_player or num_close_players >= 2
end

function conditions.beast_of_nurgle_should_eat(unit, blackboard, scratchpad, condition_args, action_data, is_running)
	local is_aggroed = conditions.is_aggroed(unit, blackboard, scratchpad, condition_args, action_data, is_running)

	if not is_aggroed then
		return false
	end

	if is_running then
		return true
	end

	local perception_component = blackboard.perception
	local target_is_close = perception_component.target_distance < 5

	if not target_is_close then
		return false
	end

	local behavior_component = blackboard.behavior
	local cooldown = behavior_component.consume_cooldown
	local t = Managers.time:time("gameplay")

	if t < cooldown then
		return false
	end

	local target_unit = perception_component.target_unit
	local buff_extension = ScriptUnit.extension(target_unit, "buff_system")
	local vomit_buff_name = "chaos_beast_of_nurgle_hit_by_vomit"
	local current_stacks = buff_extension:current_stacks(vomit_buff_name)

	if current_stacks == 0 then
		return false
	end

	return true
end

function conditions.beast_of_nurgle_wants_to_play_change_target(unit, blackboard, scratchpad, condition_args, action_data, is_running)
	if is_running then
		return true
	end

	local perception_component = blackboard.perception

	if perception_component.target_changed then
		local new_target_unit = perception_component.target_unit
		local target_is_close = perception_component.target_distance < 5.25

		return new_target_unit and ALIVE[new_target_unit] and not target_is_close
	end

	return false
end

function conditions.beast_of_nurgle_wants_to_play_alerted(unit, blackboard, scratchpad, condition_args, action_data, is_running)
	if is_running then
		return true
	end

	local is_aggroed = conditions.is_aggroed(unit, blackboard, scratchpad, condition_args, action_data, is_running)

	if not is_aggroed then
		return false
	end

	local perception_component = blackboard.perception
	local behavior_component = blackboard.behavior
	local target_is_close = perception_component.target_distance < 5.25

	return behavior_component.wants_to_play_alerted and not target_is_close
end

function conditions.beast_of_nurgle_normal_stagger(unit, blackboard, scratchpad, condition_args, action_data, is_running)
	local stagger_component = blackboard.stagger
	local is_staggered = stagger_component.num_triggered_staggers > 0 and stagger_component.type == "explosion"

	return is_staggered
end

function conditions.beast_of_nurgle_weakspot_stagger(unit, blackboard, scratchpad, condition_args, action_data, is_running)
	if is_running then
		return true
	end

	local behavior_component = blackboard.behavior
	local consumed_unit = behavior_component.consumed_unit

	if not HEALTH_ALIVE[consumed_unit] or ALIVE[scratchpad.consumed_unit] then
		return false
	end

	local stagger_component = blackboard.stagger
	local is_staggered = stagger_component.num_triggered_staggers > 0 and stagger_component.type == "heavy"

	return is_staggered
end

function conditions.beast_of_nurgle_movement(unit, blackboard, scratchpad, condition_args, action_data, is_running)
	local is_aggroed = conditions.is_aggroed(unit, blackboard, scratchpad, condition_args, action_data, is_running)

	if not is_aggroed then
		return false
	end

	if is_running then
		return true
	end

	local perception_component = blackboard.perception
	local target_is_far_away = perception_component.target_distance > 3.5

	if target_is_far_away then
		return true
	end

	local target_unit = perception_component.target_unit
	local buff_extension = ScriptUnit.extension(target_unit, "buff_system")
	local vomit_buff_name = "chaos_beast_of_nurgle_hit_by_vomit"
	local target_is_vomited = buff_extension:current_stacks(vomit_buff_name) > 0

	if target_is_vomited then
		return true
	end

	return false
end

return conditions
