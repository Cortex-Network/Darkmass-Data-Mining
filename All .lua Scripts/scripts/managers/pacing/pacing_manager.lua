local HordePacing = require("scripts/managers/pacing/horde_pacing/horde_pacing")
local MinionDifficultySettings = require("scripts/settings/difficulty/minion_difficulty_settings")
local MonsterPacing = require("scripts/managers/pacing/monster_pacing/monster_pacing")
local PacingTemplates = require("scripts/managers/pacing/pacing_templates")
local PlayerUnitStatus = require("scripts/utilities/attack/player_unit_status")
local RoamerPacing = require("scripts/managers/pacing/roamer_pacing/roamer_pacing")
local SpecialsPacing = require("scripts/managers/pacing/specials_pacing/specials_pacing")
local PacingManager = class("PacingManager")

function PacingManager:init(world, nav_world, level_name, level_seed, pacing_control)
	self._tension = 0
	self._total_challenge_rating = 0
	self._num_aggroed_minions = 0
	self._aggroed_minions = {}
	self._switch_state_conditions = {
		back = {},
		next = {}
	}
	self._world = world
	local template = PacingTemplates.default
	self._template = template
	self._roamer_pacing = RoamerPacing:new(nav_world, level_name, level_seed, pacing_control)
	self._horde_pacing = HordePacing:new(nav_world)
	self._specials_pacing = SpecialsPacing:new(nav_world)
	self._monster_pacing = MonsterPacing:new(nav_world)
	self._side_system = Managers.state.extension:system("side_system")
	self._paused_spawn_types = {}
	self._pause_durations = {}
	self._player_tension = {}
	self._player_combat_states = {}
	self._current_combat_state = "low"
	self._disabled = false
	self._backend_pacing_control = pacing_control
end

function PacingManager:on_gameplay_post_init(level_name)
	local template = self._template
	local combat_state_settings = Managers.state.difficulty:get_table_entry_by_resistance(template.combat_state_settings)
	self._combat_state_settings = combat_state_settings
	local state_settings = Managers.state.difficulty:get_table_entry_by_resistance(template.state_settings)
	self._state_settings = state_settings
	local starting_state = template.starting_state
	self._next_state = starting_state
	self._state_orders = template.state_orders

	self:_change_state(0, starting_state)

	self._max_tension = Managers.state.difficulty:get_table_entry_by_resistance(template.max_tension)
	self._ramp_up_frequency_settings = Managers.state.difficulty:get_table_entry_by_resistance(template.ramp_up_frequency_modifiers)
	self._ramp_up_frequency_modifiers = {}
	local challenge_rating_thresholds = {}

	for spawn_type, challenge_table in pairs(template.challenge_rating_thresholds) do
		challenge_rating_thresholds[spawn_type] = Managers.state.difficulty:get_table_entry_by_challenge(challenge_table)
	end

	self._challenge_rating_thresholds = challenge_rating_thresholds

	self._roamer_pacing:on_gameplay_post_init(level_name)

	local horde_resistance_templates = template.horde_pacing_template.resistance_templates
	local horde_pacing_template = Managers.state.difficulty:get_table_entry_by_resistance(horde_resistance_templates)

	self._horde_pacing:on_gameplay_post_init(level_name, horde_pacing_template)

	local monster_resistance_templates = template.monster_pacing_template.resistance_templates
	local monster_resistance_template = Managers.state.difficulty:get_table_entry_by_resistance(monster_resistance_templates)

	self._monster_pacing:on_gameplay_post_init(level_name, monster_resistance_template)

	local main_path_available = Managers.state.main_path:is_main_path_available()
	local cinematic_playing = Managers.state.cinematic:is_playing()
	local cinematic_scene_system = Managers.state.extension:system("cinematic_scene_system")
	self._disabled = not main_path_available or cinematic_playing or not cinematic_scene_system:intro_played()

	Managers.event:register(self, "intro_cinematic_started", "_event_intro_cinematic_started")
	Managers.event:register(self, "intro_cinematic_played", "_event_intro_cinematic_played")
end

function PacingManager:on_spawn_points_generated()
	local template = self._template
	local specials_resistance_templates = template.specials_pacing_template.resistance_templates
	local specials_pacing_template = Managers.state.difficulty:get_table_entry_by_resistance(specials_resistance_templates)

	self._specials_pacing:on_spawn_points_generated(specials_pacing_template)
end

function PacingManager:destroy()
	Managers.event:unregister(self, "intro_cinematic_started")
	Managers.event:unregister(self, "intro_cinematic_played")
	self._roamer_pacing:delete()
	self._monster_pacing:delete()
end

function PacingManager:update(dt, t)
	local side_id = 2
	local target_side_id = 1

	self:_update_player_combat_state(dt, target_side_id)

	local tension = self._tension
	local decay_tension_rate = self._decay_tension_rate
	local delay_duration = self._decay_tension_delay_duration

	if not delay_duration or delay_duration and delay_duration < t then
		local new_tension = math.clamp(tension - dt * decay_tension_rate, 0, self._max_tension)
		self._tension = new_tension
		self._is_decaying_tension = new_tension > 0
	else
		self._is_decaying_tension = false
	end

	local pause_durations = self._pause_durations

	for spawn_type, duration in pairs(pause_durations) do
		pause_durations[spawn_type] = duration - dt

		if pause_durations[spawn_type] <= 0 then
			if self._paused_spawn_types[spawn_type] then
				self:pause_spawn_type(spawn_type, false, "pause_duration_over")
			end

			pause_durations[spawn_type] = nil

			break
		end
	end

	if not self._disabled then
		self._roamer_pacing:update(dt, t, side_id, target_side_id)
		self._horde_pacing:update(dt, t, side_id, target_side_id)
		self._specials_pacing:update(dt, t, side_id, target_side_id)
		self._monster_pacing:update(dt, t, side_id, target_side_id)
		self:_update_ramp_up_frequency(dt, target_side_id)
	end

	local switch_state_conditions = self._switch_state_conditions
	local state_order = self._state_order

	for name, conditions in pairs(switch_state_conditions) do
		local duration = conditions.duration

		if duration and duration < t then
			local state_name = name == "next" and state_order.next_state or state_order.back_state

			self:_change_state(t, state_name)

			return
		end

		local tension_threshold = conditions.tension_threshold
		local tension_min_threshold = conditions.tension_min_threshold

		if tension_threshold and tension_threshold <= tension or tension_min_threshold and tension <= tension_min_threshold then
			local state_name = name == "next" and state_order.next_state or state_order.back_state

			self:_change_state(t, state_name)

			return
		end
	end
end

function PacingManager:_set_switch_state_condition(conditions, condition_identifier, t)
	local duration_end_condition = conditions.duration
	local tension_threshold = conditions.tension_threshold
	local tension_min_threshold = conditions.tension_min_threshold
	local switch_state_condition = self._switch_state_conditions[condition_identifier]

	if duration_end_condition then
		switch_state_condition.duration = t + math.random_range(duration_end_condition[1], duration_end_condition[2])
	else
		switch_state_condition.duration = nil
	end

	switch_state_condition.tension_threshold = tension_threshold
	switch_state_condition.tension_min_threshold = tension_min_threshold
end

function PacingManager:_change_state(t, state_name)
	local state_settings = self._state_settings
	local state_setting = state_settings[state_name]
	local next_conditions = state_setting.next_conditions
	local back_conditions = state_setting.back_conditions
	local switch_state_conditions = self._switch_state_conditions

	if next_conditions then
		self:_set_switch_state_condition(next_conditions, "next", t)
	else
		table.clear(switch_state_conditions.next)
	end

	if back_conditions then
		self:_set_switch_state_condition(back_conditions, "back", t)
	else
		table.clear(switch_state_conditions.back)
	end

	local allowed_spawn_types = state_setting.allowed_spawn_types
	self._allowed_spawn_types = allowed_spawn_types
	self._state = state_name
	self._state_setting = state_setting
	self._state_order = self._state_orders[state_name]
	self._decay_tension_rate = state_setting.decay_tension_rate

	if state_setting.decay_tension_delay then
		self._decay_tension_delay = state_setting.decay_tension_delay
	else
		self._decay_tension_delay = nil
		self._decay_tension_delay_duration = nil
	end
end

function PacingManager:pause_spawn_type(spawn_type, paused, reason, optional_duration)
	if spawn_type == "all" then
		for type, _ in pairs(self._allowed_spawn_types) do
			self._paused_spawn_types[type] = paused
		end
	else
		self._paused_spawn_types[spawn_type] = paused
	end

	if optional_duration then
		self._pause_durations[spawn_type] = optional_duration
	elseif self._pause_durations[spawn_type] then
		self._pause_durations[spawn_type] = nil
	end
end

function PacingManager:set_enabled(enabled)
	self._disabled = not enabled
end

function PacingManager:set_in_safe_zone(in_safe_zone)
	self._in_safe_zone = in_safe_zone
end

function PacingManager:_event_intro_cinematic_started(cinematic_name)
	self._disabled = true
end

function PacingManager:_event_intro_cinematic_played(cinematic_name)
	if self._disabled then
		self._disabled = not Managers.state.main_path:is_main_path_available()
	end
end

function PacingManager:spawn_type_enabled(spawn_type)
	if self._disabled then
		return false, "pacing_is_disabled"
	end

	local challenge_rating_thresholds = self._challenge_rating_thresholds
	local challenge_rating_threshold = challenge_rating_thresholds[spawn_type]
	local total_challenge_rating = self._total_challenge_rating

	if challenge_rating_threshold and challenge_rating_threshold < total_challenge_rating then
		return false, "disabled_by_challenge_rating"
	end

	if self._paused_spawn_types[spawn_type] then
		return false, "paused"
	end

	if not self._allowed_spawn_types or not self._allowed_spawn_types[spawn_type] then
		return false, "not_allowed"
	end

	return true
end

function PacingManager:spawn_type_allowed(spawn_type)
	if not self._allowed_spawn_types or not self._allowed_spawn_types[spawn_type] then
		return false
	end

	return true
end

function PacingManager:add_tension(tension, optional_player_unit, reason)
	local decay_tension_delay = self._decay_tension_delay

	if decay_tension_delay then
		local t = Managers.time:time("gameplay")
		self._decay_tension_delay_duration = t + decay_tension_delay
	end

	self._tension = math.min(self._tension + tension, self._max_tension)

	if optional_player_unit then
		local settings = self._combat_state_settings
		local current_player_tension = self._player_tension[optional_player_unit] or 0
		local tension_modifier = settings.tension_modifier
		local max_value = settings.max_value
		self._player_tension[optional_player_unit] = math.min(current_player_tension + tension * tension_modifier, max_value)
	end
end

function PacingManager:add_damage_tension(tension_type, damage, attacked_unit)
	local target_unit_data_extension = ScriptUnit.extension(attacked_unit, "unit_data_system")
	local character_state_component = target_unit_data_extension:read_component("character_state")
	local is_disabled = PlayerUnitStatus.is_disabled(character_state_component)

	if is_disabled then
		return
	end

	local diff_table = MinionDifficultySettings.damage_tension_to_add[tension_type]
	local value = Managers.state.difficulty:get_table_entry_by_challenge(diff_table)
	local tension = damage * value
	local side_id = 1
	local side = self._side_system:get_side(side_id)
	local valid_player_units = side.valid_player_units
	local num_valid_player_units = #valid_player_units
	tension = tension / num_valid_player_units

	self:add_tension(tension, attacked_unit, tension_type)
end

function PacingManager:add_tension_type(tension_type, attacked_unit)
	local diff_table = MinionDifficultySettings.tension_to_add[tension_type]
	local value = Managers.state.difficulty:get_table_entry_by_challenge(diff_table)

	self:add_tension(value, attacked_unit, tension_type)
end

function PacingManager:player_tension(unit)
	local settings = self._combat_state_settings
	local max_value = settings.max_value
	local tension = self._player_tension[unit] or 0
	local value = tension / max_value

	return value
end

function PacingManager:_update_player_combat_state(dt, side_id)
	local settings = self._combat_state_settings
	local combat_states = settings.combat_states
	local low_threshold = settings.low_threshold
	local medium_threshold = settings.medium_threshold
	local high_threshold = settings.high_threshold
	local max_value = settings.max_value
	local base_decay_rate = settings.base_decay_rate
	local player_combat_states = self._player_combat_states
	local player_tension = self._player_tension
	local decay_tension_rate = self._decay_tension_rate
	local total_challenge_rating = self._total_challenge_rating
	local side = self._side_system:get_side(side_id)
	local valid_player_units = side.valid_player_units
	local num_valid_player_units = #valid_player_units
	local num_low = 0
	local num_high = 0
	local num_medium = 0

	for i = 1, num_valid_player_units do
		local player_unit = valid_player_units[i]
		local tension = player_tension[player_unit] or 0
		local new_tension = math.max(tension - dt * (base_decay_rate + decay_tension_rate), 0)
		player_tension[player_unit] = new_tension
		local value = math.clamp(total_challenge_rating + new_tension, 0, max_value)
		local current_combat_state = nil

		if low_threshold <= value and value < medium_threshold then
			current_combat_state = combat_states.low
			num_low = num_low + 1
		elseif medium_threshold <= value and value < high_threshold then
			current_combat_state = combat_states.medium
			num_medium = num_medium + 1
		elseif high_threshold <= value then
			current_combat_state = combat_states.high
			num_high = num_high + 1
		end

		player_combat_states[player_unit] = current_combat_state
	end

	if num_high == num_valid_player_units then
		self._current_combat_state = combat_states.high
	elseif num_medium == num_valid_player_units then
		self._current_combat_state = combat_states.medium
	elseif num_low == num_valid_player_units then
		self._current_combat_state = combat_states.low
	end

	local ALIVE = ALIVE

	for unit, _ in pairs(player_tension) do
		if not ALIVE[unit] then
			player_tension[unit] = nil
		end
	end
end

function PacingManager:_update_ramp_up_frequency(dt, target_side_id)
	local state = self._state
	local ramp_up_frequency_settings = self._ramp_up_frequency_settings
	local ramp_up_frequency_modifiers = self._ramp_up_frequency_modifiers
	local ramp_modifiers = ramp_up_frequency_settings.ramp_modifiers
	local ramp_up_states = ramp_up_frequency_settings.ramp_up_states

	if not ramp_up_states[state] or self._in_safe_zone then
		if self._current_ramp_up_duration then
			for spawn_type, max_modifier in pairs(ramp_modifiers) do
				ramp_up_frequency_modifiers[spawn_type] = 1
			end
		end

		self._current_ramp_up_duration = nil

		return
	end

	local ramp_duration = ramp_up_frequency_settings.ramp_duration

	if not self._current_ramp_up_duration then
		self._current_ramp_up_duration = ramp_duration
	else
		local travel_change_pause_time = ramp_up_frequency_settings.travel_change_pause_time
		local time_since_forward_travel_changed = Managers.state.main_path:time_since_forward_travel_changed(target_side_id)

		if time_since_forward_travel_changed < travel_change_pause_time then
			self._current_ramp_up_duration = math.max(self._current_ramp_up_duration - dt, 0)
		end
	end

	local ramp_up_percentage = math.min(1 - self._current_ramp_up_duration / ramp_duration, 1)

	for spawn_type, max_modifier in pairs(ramp_modifiers) do
		local diff = math.abs(1 - max_modifier)
		ramp_up_frequency_modifiers[spawn_type] = 1 + diff * ramp_up_percentage
	end
end

function PacingManager:_get_ramp_up_frequency_modifier(spawn_type)
	return self._ramp_up_frequency_modifiers[spawn_type] or 1
end

function PacingManager:player_unit_combat_state(player_unit)
	return self._player_combat_states[player_unit]
end

function PacingManager:combat_state()
	return self._current_combat_state
end

function PacingManager:state()
	return self._state
end

function PacingManager:add_aggroed_minion(unit)
	local aggroed_minions = self._aggroed_minions

	if not aggroed_minions[unit] then
		local unit_data_extension = ScriptUnit.extension(unit, "unit_data_system")
		local challenge_rating = unit_data_extension:breed().challenge_rating

		if challenge_rating then
			self._total_challenge_rating = self._total_challenge_rating + challenge_rating
		end

		self._num_aggroed_minions = self._num_aggroed_minions + 1
		aggroed_minions[unit] = true

		self._side_system:add_aggroed_minion(unit)

		if self._in_safe_zone then
			self:pause_spawn_type("specials", false)
			self:pause_spawn_type("hordes", false)
			self:pause_spawn_type("trickle_hordes", false)
			self:set_in_safe_zone(false)
		end
	end
end

function PacingManager:remove_aggroed_minion(unit)
	local aggroed_minions = self._aggroed_minions

	if aggroed_minions[unit] then
		local unit_data_extension = ScriptUnit.extension(unit, "unit_data_system")
		local challenge_rating = unit_data_extension:breed().challenge_rating

		if challenge_rating then
			self._total_challenge_rating = self._total_challenge_rating - challenge_rating
		end

		self._num_aggroed_minions = self._num_aggroed_minions - 1
		aggroed_minions[unit] = nil

		self._side_system:remove_aggroed_minion(unit)
	end
end

function PacingManager:total_challenge_rating()
	return self._total_challenge_rating
end

function PacingManager:num_aggroed_minions()
	return self._num_aggroed_minions
end

function PacingManager:tension()
	return self._tension
end

function PacingManager:add_monster_spawn_point(unit, position, path_position, travel_distance, section, spawn_type)
	local success = self._monster_pacing:add_spawn_point(unit, position, path_position, travel_distance, section, spawn_type)

	return success
end

function PacingManager:add_trickle_horde(template)
	self._horde_pacing:add_trickle_horde(template)
end

function PacingManager:add_pacing_modifiers(modify_settings)
	local modify_resistance = modify_settings.modify_resistance

	if modify_resistance then
		Managers.state.difficulty:modify_resistance(modify_resistance)
	end

	local horde_timer_modifier = modify_settings.horde_timer_modifier

	if horde_timer_modifier then
		self._horde_pacing:set_timer_modifier(horde_timer_modifier)
	end

	local required_horde_travel_distance = modify_settings.required_horde_travel_distance

	if required_horde_travel_distance then
		self._horde_pacing:set_override_required_travel_distance(required_horde_travel_distance)
	end

	local specials_timer_modifier = modify_settings.specials_timer_modifier

	if specials_timer_modifier then
		self._specials_pacing:set_timer_modifier(specials_timer_modifier)
	end

	local max_alive_specials_multiplier = modify_settings.max_alive_specials_multiplier

	if max_alive_specials_multiplier then
		self._specials_pacing:set_max_alive_specials_multiplier(max_alive_specials_multiplier)
	end

	local monsters_per_travel_distance = modify_settings.monsters_per_travel_distance
	local monster_breed_name = modify_settings.monster_breed_name
	local monster_spawn_type = modify_settings.monster_spawn_type

	if monsters_per_travel_distance and monster_breed_name then
		self._monster_pacing:fill_spawns_by_travel_distance(monster_breed_name, monster_spawn_type, monsters_per_travel_distance)
	end

	local override_faction = modify_settings.override_faction

	if override_faction then
		self._roamer_pacing:override_faction(override_faction)
	end

	local num_encampments_override = modify_settings.num_encampments_override
	local encampments_override_chance = modify_settings.encampments_override_chance

	if num_encampments_override and encampments_override_chance then
		self._roamer_pacing:num_encampments_override(num_encampments_override, encampments_override_chance)
	end
end

function PacingManager:aggro_roamer_zone_range(target_unit, range)
	self._roamer_pacing:aggro_zone_range(target_unit, range)
end

function PacingManager:allow_nav_tag_layer(layer_name, layer_allowed)
	local roamer_pacing = self._roamer_pacing

	if roamer_pacing:is_traverse_logic_initialized() then
		roamer_pacing:allow_nav_tag_layer(layer_name, layer_allowed)
	end
end

function PacingManager:start_terror_trickle(template_name, spawner_group)
	self._horde_pacing:start_terror_trickle(template_name, spawner_group)
end

function PacingManager:is_decaying_tension()
	return self._is_decaying_tension
end

function PacingManager:current_faction()
	return self._roamer_pacing:current_faction()
end

function PacingManager:current_density_type()
	return self._roamer_pacing:current_density_type()
end

function PacingManager:try_inject_special(breed_name, optional_prefered_spawn_direction, optional_target_unit, optional_spawner_group)
	self._specials_pacing:try_inject_special(breed_name, optional_prefered_spawn_direction, optional_target_unit, optional_spawner_group)
end

function PacingManager:refund_special_slot()
	return self._specials_pacing:refund_special_slot()
end

function PacingManager:freeze_specials_pacing(enabled)
	self._specials_pacing:freeze(enabled)
end

function PacingManager:roamer_traverse_logic()
	return self._roamer_pacing:traverse_logic()
end

function PacingManager:get_backend_pacing_control_flag(flag)
	return self._backend_pacing_control and self._backend_pacing_control[flag]
end

return PacingManager
