local ActionBase = class("ActionBase")

function ActionBase:init(action_context, action_params, action_settings)
	self._world = action_context.world
	self._physics_world = action_context.physics_world
	self._wwise_world = action_context.wwise_world
	self._first_person_unit = action_context.first_person_unit
	local player_unit = action_context.player_unit
	self._player_unit = player_unit
	local player_unit_spawn_manager = Managers.state.player_unit_spawn
	self._player = player_unit_spawn_manager:owner(player_unit)
	self._animation_extension = action_context.animation_extension
	self._camera_extension = action_context.camera_extension
	self._first_person_extension = action_context.first_person_extension
	self._fx_extension = action_context.fx_extension
	self._input_extension = action_context.input_extension
	self._visual_loadout_extension = action_context.visual_loadout_extension
	self._smart_targeting_extension = action_context.smart_targeting_extension
	self._unit_data_extension = action_context.unit_data_extension
	self._dialogue_input = action_context.dialogue_input
	local weapon_action_component = action_context.weapon_action_component
	self._weapon_action_component = weapon_action_component
	self._first_person_component = action_context.first_person_component
	self._inventory_component = action_context.inventory_component
	self._locomotion_component = action_context.locomotion_component
	self._movement_state_component = action_context.movement_state_component
	self._sprint_character_state_component = action_context.sprint_character_state_component
	self._ability_extension = action_context.ability_extension
	self._action_settings = action_settings
	self._is_server = action_context.is_server
	self._is_local_unit = action_context.is_local_unit
	self._buff_extension = ScriptUnit.extension(player_unit, "buff_system")
end

function ActionBase:start(action_settings, t, time_scale, action_start_params)
end

function ActionBase:finish(reason, data, t, time_in_action)
end

function ActionBase:update(dt, t)
end

function ActionBase:fixed_update(dt, t, time_in_action)
end

function ActionBase:action_settings()
	return self._action_settings
end

function ActionBase:server_correction_occurred()
end

function ActionBase:trigger_anim_event(anim_event, anim_event_3p, action_time_offset, ...)
	local time_scale = self._weapon_action_component.time_scale
	local anim_ext = self._animation_extension
	action_time_offset = action_time_offset or 0

	anim_ext:anim_event_with_variable_floats_1p(anim_event, "attack_speed", time_scale, "action_time_offset", action_time_offset, ...)

	if anim_event_3p then
		anim_ext:anim_event_with_variable_floats(anim_event_3p, "attack_speed", time_scale, "action_time_offset", action_time_offset, ...)
	end
end

function ActionBase:running_action_state(t, time_in_action)
	return nil
end

function ActionBase:allow_chain_actions()
	return true
end

function ActionBase:sensitivity_modifier(t)
	local action_settings = self._action_settings
	local sensitivity_modifier = action_settings and action_settings.sensitivity_modifier or 1

	return sensitivity_modifier
end

function ActionBase:rotation_contraints()
	local action_settings = self._action_settings
	local rotation_contraints = action_settings and action_settings.rotation_contraints

	return rotation_contraints
end

return ActionBase
