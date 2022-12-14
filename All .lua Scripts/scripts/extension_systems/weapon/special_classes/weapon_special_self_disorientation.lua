local AttackSettings = require("scripts/settings/damage/attack_settings")
local HitReaction = require("scripts/utilities/attack/hit_reaction")
local Push = require("scripts/extension_systems/character_state_machine/character_states/utilities/push")
local WeaponSpecial = require("scripts/utilities/weapon_special")
local WeaponSpecialInterface = require("scripts/extension_systems/weapon/special_classes/weapon_special_interface")
local attack_types = AttackSettings.attack_types
local WeaponSpecialSelfDisorientation = class("WeaponSpecialSelfDisorientation")

function WeaponSpecialSelfDisorientation:init(context, init_data)
	local player_unit = context.player_unit
	self._player_unit = player_unit
	self._is_server = context.is_server
	self._world = context.world
	self._physics_world = context.physics_world
	self._input_extension = context.input_extension
	self._tweak_data = init_data.tweak_data
	self._weapon_template = init_data.weapon_template
	local unit_data_extension = context.unit_data_extension
	self._unit_data_extension = unit_data_extension
	self._locomotion_push_component = unit_data_extension:write_component("locomotion_push")
	self._inventory_slot_component = init_data.inventory_slot_component
	self._buff_extension = ScriptUnit.extension(player_unit, "buff_system")
end

function WeaponSpecialSelfDisorientation:update(dt, t)
	WeaponSpecial.update_active(t, self._tweak_data, self._inventory_slot_component, self._buff_extension, self._input_extension)
end

function WeaponSpecialSelfDisorientation:process_hit(t, weapon, action_settings, num_hit_enemies, target_is_alive, target_unit, hit_position, attack_direction, optional_origin_slot)
	local special_active = self._inventory_slot_component.special_active

	if not special_active or not target_is_alive then
		return
	end

	local player_unit = self._player_unit
	local tweak_data = self._tweak_data
	local direction = Vector3.normalize(POSITION_LOOKUP[player_unit] - POSITION_LOOKUP[target_unit])
	local disorientation_type = tweak_data.disorientation_type

	if disorientation_type then
		HitReaction.disorient_player(player_unit, self._unit_data_extension, disorientation_type, true, true, direction, attack_types.melee, self._weapon_template, true)
	end

	local push_template = tweak_data.push_template

	if push_template then
		Push.add(player_unit, self._locomotion_push_component, direction, push_template, attack_types.melee)
	end

	local inventory_slot_component = self._inventory_slot_component
	inventory_slot_component.special_active = false
	inventory_slot_component.num_special_activations = 0
end

function WeaponSpecialSelfDisorientation:on_action_start(t, num_hit_enemies)
end

function WeaponSpecialSelfDisorientation:on_action_finish(t, num_hit_enemies)
end

function WeaponSpecialSelfDisorientation:on_exit_damage_window(t, num_hit_enemies)
end

implements(WeaponSpecialSelfDisorientation, WeaponSpecialInterface)

return WeaponSpecialSelfDisorientation
