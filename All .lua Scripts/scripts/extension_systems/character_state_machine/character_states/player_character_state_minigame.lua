local Crouch = require("scripts/extension_systems/character_state_machine/character_states/utilities/crouch")
local DisruptiveStateTransition = require("scripts/extension_systems/character_state_machine/character_states/utilities/disruptive_state_transition")
local Dodge = require("scripts/extension_systems/character_state_machine/character_states/utilities/dodge")
local HealthStateTransitions = require("scripts/extension_systems/character_state_machine/character_states/utilities/health_state_transitions")
local InteractionSettings = require("scripts/settings/interaction/interaction_settings")
local Interrupt = require("scripts/utilities/attack/interrupt")
local Luggable = require("scripts/utilities/luggable")
local MinigameSettings = require("scripts/settings/minigame/minigame_settings")
local PlayerUnitVisualLoadout = require("scripts/extension_systems/visual_loadout/utilities/player_unit_visual_loadout")

require("scripts/extension_systems/character_state_machine/character_states/player_character_state_base")

local INTERRUPT_REASON = "minigame"
local PlayerCharacterStateMinigame = class("PlayerCharacterStateMinigame", "PlayerCharacterStateBase")

function PlayerCharacterStateMinigame:init(character_state_init_context, ...)
	PlayerCharacterStateMinigame.super.init(self, character_state_init_context, ...)

	local unit = self._unit
	local minigame_character_state_component = character_state_init_context.unit_data:write_component("minigame_character_state")
	minigame_character_state_component.interface_unit_id = NetworkConstants.invalid_level_unit_id
	self._input_extension = ScriptUnit.extension(unit, "input_system")
	self._minigame_extension = nil
	self._minigame_character_state_component = minigame_character_state_component
end

function PlayerCharacterStateMinigame:on_enter(unit, dt, t, previous_state, params)
	local inventory_component = self._inventory_component
	local visual_loadout_extension = self._visual_loadout_extension

	Interrupt.ability_and_action(t, unit, INTERRUPT_REASON, nil)
	Luggable.drop_luggable(t, unit, inventory_component, visual_loadout_extension, true)

	local locomotion_steering_component = self._locomotion_steering_component
	locomotion_steering_component.velocity_wanted = Vector3.zero()
	locomotion_steering_component.calculate_fall_velocity = true
	locomotion_steering_component.disable_push_velocity = true
	local movement_state_component = self._movement_state_component
	local is_crouching = self._movement_state_component.is_crouching

	if is_crouching then
		local first_person_extension = self._first_person_extension
		local animation_extension = self._animation_extension
		local weapon_extension = self._weapon_extension
		local sway_control_component = self._sway_control_component
		local sway_component = self._sway_component
		local spread_control_component = self._spread_control_component

		Crouch.exit(unit, first_person_extension, animation_extension, weapon_extension, movement_state_component, sway_control_component, sway_component, spread_control_component, t)
	end

	self:_initialize_minigame()

	local weapon_template = PlayerUnitVisualLoadout.wielded_weapon_template(visual_loadout_extension, inventory_component)
	local weapon_actions = weapon_template.actions
	local anim_event = weapon_actions.action_wield.anim_event
	local animation_extension = self._animation_extension

	animation_extension:anim_event_1p(anim_event)

	local unit_data_extension = ScriptUnit.extension(unit, "unit_data_system")
	local interaction_component = unit_data_extension:write_component("interaction")
	interaction_component.state = InteractionSettings.states.none
end

function PlayerCharacterStateMinigame:on_exit(unit, t, next_state)
	self:_deinitialize_minigame()

	self._minigame_character_state_component.interface_unit_id = NetworkConstants.invalid_level_unit_id
	self._locomotion_steering_component.disable_push_velocity = false
	local inventory_component = self._inventory_component

	PlayerUnitVisualLoadout.wield_previous_slot(inventory_component, unit, t)

	local unit_data_extension = ScriptUnit.extension(unit, "unit_data_system")
	local interaction_component = unit_data_extension:write_component("interaction")
	interaction_component.state = InteractionSettings.states.waiting_to_interact
end

function PlayerCharacterStateMinigame:on_enter_server_corrected_state(unit)
	local locomotion_steering_component = self._locomotion_steering_component
	locomotion_steering_component.velocity_wanted = Vector3.zero()
	locomotion_steering_component.calculate_fall_velocity = true

	if self._minigame_extension == nil then
		self:_initialize_minigame()
	end
end

function PlayerCharacterStateMinigame:fixed_update(unit, dt, t, next_state_params, fixed_frame)
	local input_extension = self._input_extension
	local cancelled = self:_update_input(t, input_extension)

	return self:_check_transition(unit, t, next_state_params, cancelled, input_extension)
end

function PlayerCharacterStateMinigame:_update_input(t)
	local input_extension = self._input_extension
	local action_one_pressed = input_extension:get("action_one_pressed")
	local action_two_pressed = input_extension:get("action_two_pressed")
	local action_interaction_pressed = input_extension:get("interact_pressed")
	local move_input = input_extension:get("move")
	local animation_extension = self._animation_extension

	if Vector3.length_squared(move_input) > 0 then
		local vertical_move = move_input.y

		if vertical_move > 0 then
			animation_extension:anim_event_1p("knob_turn_up")
		else
			animation_extension:anim_event_1p("knob_turn_down")
		end
	end

	local minigame_extension = self._minigame_extension

	if minigame_extension and (action_one_pressed or action_interaction_pressed) then
		if self._is_server then
			minigame_extension:on_action_pressed(t)
		end

		animation_extension:anim_event_1p("button_press")

		local current_minigame_state = minigame_extension:current_state()

		if current_minigame_state == MinigameSettings.states.completed then
			animation_extension:anim_event_1p("scan_end")
		end
	end

	return action_two_pressed
end

function PlayerCharacterStateMinigame:_is_minigame_active()
	local minigame_extension = self._minigame_extension

	if minigame_extension then
		local is_active = minigame_extension:current_state() == MinigameSettings.states.active

		return is_active
	end

	return true
end

local HALF_PI = math.pi * 0.5

function PlayerCharacterStateMinigame:_is_looking_away_from_device()
	local minigame_extension = self._minigame_extension

	if not minigame_extension then
		return false
	end

	local interfaced_unit = minigame_extension:unit()
	local interfaced_unit_pos = POSITION_LOOKUP[interfaced_unit]

	if interfaced_unit and interfaced_unit_pos then
		local first_person_component = self._first_person_component
		local player_pos = first_person_component.position
		local look_rot = first_person_component.rotation
		local to_unit_position = Vector3.normalize(interfaced_unit_pos - player_pos)
		local up = Quaternion.up(look_rot)
		local up_dot = math.clamp(Vector3.dot(up, to_unit_position), -1, 1)
		local up_angle = math.acos(up_dot) - HALF_PI
		local right_flat = Vector3.normalize(Vector3.flat(Quaternion.right(look_rot)))
		local to_unit_pos_flat = Vector3.normalize(Vector3.flat(to_unit_position))
		local right_dot = math.clamp(Vector3.dot(right_flat, to_unit_pos_flat), -1, 1)
		local right_angle = math.abs(math.acos(right_dot) - HALF_PI)
		local horizontal_disengage = MinigameSettings.disengage_view_angle_h
		local vertical_disengage = MinigameSettings.disengage_view_angle_v
		local should_disengage_horizontal = horizontal_disengage <= right_angle
		local should_disengage_vertical = vertical_disengage <= up_angle

		if should_disengage_horizontal or should_disengage_vertical then
			return true
		end
	end

	return false
end

function PlayerCharacterStateMinigame:_check_transition(unit, t, next_state_params, cancelled, input_source)
	local unit_data_extension = self._unit_data_extension
	local health_transition = HealthStateTransitions.poll(unit_data_extension, next_state_params)

	if health_transition then
		return health_transition
	end

	local is_colliding_on_hang_ledge, hang_ledge_unit = self:_should_hang_on_ledge(unit, t)

	if is_colliding_on_hang_ledge then
		next_state_params.hang_ledge_unit = hang_ledge_unit

		return "ledge_hanging"
	end

	local disruptive_transition = DisruptiveStateTransition.poll(unit, unit_data_extension, next_state_params)

	if disruptive_transition then
		return disruptive_transition
	end

	local inair_state = self._inair_state_component

	if not inair_state.on_ground then
		return "falling"
	end

	local specialization_dodge_template = self._specialization_dodge_template
	local should_dodge, local_dodge_direction = Dodge.check(t, self._unit_data_extension, specialization_dodge_template, input_source)

	if should_dodge then
		next_state_params.dodge_direction = local_dodge_direction

		return "dodging"
	end

	local is_looking_away_from_device = self:_is_looking_away_from_device()
	local is_wielding_minigame_device = self:_is_wielding_minigame_device()
	local is_minigame_active = self:_is_minigame_active()

	if cancelled or is_looking_away_from_device or not is_wielding_minigame_device or not is_minigame_active then
		return "walking"
	end

	return nil
end

function PlayerCharacterStateMinigame:_initialize_minigame()
	local is_level_unit = true
	local level_unit_id = self._minigame_character_state_component.interface_unit_id
	local interface_unit = Managers.state.unit_spawner:unit(level_unit_id, is_level_unit)
	local minigame_extension = interface_unit and ScriptUnit.has_extension(interface_unit, "minigame_system")

	if minigame_extension then
		if self._is_server then
			minigame_extension:setup_game()
		end

		minigame_extension:start(self._player)

		self._minigame_extension = minigame_extension
	end
end

function PlayerCharacterStateMinigame:_deinitialize_minigame()
	local minigame_extension = self._minigame_extension

	if minigame_extension and minigame_extension:current_state() == MinigameSettings.states.active then
		minigame_extension:stop(self._player)
	end

	self._minigame_extension = nil
end

return PlayerCharacterStateMinigame
