require("scripts/extension_systems/character_state_machine/character_states/player_character_state_base")

local HangLedge = require("scripts/extension_systems/character_state_machine/character_states/utilities/hang_ledge")
local PlayerMovement = require("scripts/utilities/player_movement")
local PlayerCharacterStateLedgeHangingPullUp = class("PlayerCharacterStateLedgeHangingPullUp", "PlayerCharacterStateBase")

function PlayerCharacterStateLedgeHangingPullUp:init(character_state_init_context, ...)
	PlayerCharacterStateLedgeHangingPullUp.super.init(self, character_state_init_context, ...)

	local unit_data_extension = character_state_init_context.unit_data
	local ledge_hanging_character_state_component = unit_data_extension:write_component("ledge_hanging_character_state")
	self._ledge_hanging_character_state_component = ledge_hanging_character_state_component
end

function PlayerCharacterStateLedgeHangingPullUp:on_enter(unit, dt, t, previous_state, params)
	local hang_ledge_unit = self._ledge_hanging_character_state_component.hang_ledge_unit

	self:_teleport(unit, hang_ledge_unit)
	self:_restore_locomotion()
end

function PlayerCharacterStateLedgeHangingPullUp:on_exit(unit, t, next_state)
	self._ledge_hanging_character_state_component.hang_ledge_unit = nil
end

function PlayerCharacterStateLedgeHangingPullUp:_restore_locomotion()
	local locomotion_steering = self._locomotion_steering_component
	locomotion_steering.move_method = "script_driven"
	locomotion_steering.calculate_fall_velocity = true
	locomotion_steering.disable_velocity_rotation = false
end

function PlayerCharacterStateLedgeHangingPullUp:fixed_update(unit, dt, t, next_state_params, fixed_frame)
	Unit.set_local_pose(unit, Unit.node(unit, "j_hips_handle"), Matrix4x4.identity())

	return self:_check_transition(unit, t, next_state_params)
end

function PlayerCharacterStateLedgeHangingPullUp:_check_transition(unit, t, next_state_params)
	return "walking"
end

function PlayerCharacterStateLedgeHangingPullUp:_teleport(unit, hang_ledge_unit)
	if self._is_server then
		local new_position = HangLedge.calculate_pull_up_end_position(self._nav_world, hang_ledge_unit, unit)
		local rotation = Unit.local_rotation(unit, 1)

		PlayerMovement.teleport_fixed_update(unit, new_position, rotation)
	end
end

return PlayerCharacterStateLedgeHangingPullUp
