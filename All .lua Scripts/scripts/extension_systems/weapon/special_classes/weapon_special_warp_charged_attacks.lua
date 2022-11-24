local WarpCharge = require("scripts/utilities/warp_charge")
local WeaponSpecialInterface = require("scripts/extension_systems/weapon/special_classes/weapon_special_interface")
local WeaponSpecial = require("scripts/utilities/weapon_special")
local WeaponSpecialWarpChargedAttacks = class("WeaponSpecialWarpChargedAttacks")

function WeaponSpecialWarpChargedAttacks:init(weapon_special_context, weapon_special_init_data)
	self._input_extension = weapon_special_context.input_extension
	self._weapon_extension = weapon_special_context.weapon_extension
	self._player_unit = weapon_special_context.player_unit
	self._warp_charge_component = weapon_special_context.warp_charge_component
	self._inventory_slot_component = weapon_special_init_data.inventory_slot_component
	local tweak_data = weapon_special_init_data.tweak_data
	self._tweak_data = tweak_data
	self._buff_extension = ScriptUnit.extension(self._player_unit, "buff_system")
end

function WeaponSpecialWarpChargedAttacks:update(dt, t)
	WeaponSpecial.update_active(t, self._tweak_data, self._inventory_slot_component, self._buff_extension, self._input_extension)
end

function WeaponSpecialWarpChargedAttacks:process_hit(t, weapon, action_settings, num_hit_enemies, target_is_alive, target_unit, hit_position, attack_direction, optional_origin_slot)
	if not target_is_alive then
		return
	end

	self._inventory_slot_component.special_active = false
	self._inventory_slot_component.num_special_activations = 0
end

function WeaponSpecialWarpChargedAttacks:on_action_start(t)
	local charge_template = self._weapon_extension:charge_template()

	if charge_template then
		WarpCharge.increase_immediate(t, nil, self._warp_charge_component, charge_template, self._player_unit)
	end
end

function WeaponSpecialWarpChargedAttacks:on_action_finish(t, num_hit_enemies)
end

function WeaponSpecialWarpChargedAttacks:on_exit_damage_window(t, num_hit_enemies)
end

implements(WeaponSpecialWarpChargedAttacks, WeaponSpecialInterface)

return WeaponSpecialWarpChargedAttacks
