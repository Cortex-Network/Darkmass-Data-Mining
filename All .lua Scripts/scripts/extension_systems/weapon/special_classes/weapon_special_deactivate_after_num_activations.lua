local WeaponSpecialInterface = require("scripts/extension_systems/weapon/special_classes/weapon_special_interface")
local WeaponSpecial = require("scripts/utilities/weapon_special")
local WeaponSpecialDeactivateAfterNumActivations = class("WeaponSpecialDeactivateAfterNumActivations")

function WeaponSpecialDeactivateAfterNumActivations:init(context, init_data)
	self._input_extension = context.input_extension
	self._inventory_slot_component = init_data.inventory_slot_component
	self._tweak_data = init_data.tweak_data
	self._player_unit = context.player_unit
	self._buff_extension = ScriptUnit.extension(self._player_unit, "buff_system")
end

function WeaponSpecialDeactivateAfterNumActivations:update(dt, t)
	WeaponSpecial.update_active(t, self._tweak_data, self._inventory_slot_component, self._buff_extension, self._input_extension)
end

function WeaponSpecialDeactivateAfterNumActivations:process_hit(t, weapon, action_settings, num_hit_enemies, target_is_alive, target_unit, hit_position, attack_direction, optional_origin_slot)
	self._inventory_slot_component.special_active_start_t = t
end

function WeaponSpecialDeactivateAfterNumActivations:on_action_start(t, num_hit_enemies)
end

function WeaponSpecialDeactivateAfterNumActivations:on_action_finish(t, num_hit_enemies)
end

function WeaponSpecialDeactivateAfterNumActivations:on_exit_damage_window(t, num_hit_enemies)
	if self._inventory_slot_component.special_active and num_hit_enemies > 0 then
		self._inventory_slot_component.num_special_activations = self._inventory_slot_component.num_special_activations + 1
		self._inventory_slot_component.special_active_start_t = t
	end
end

implements(WeaponSpecialDeactivateAfterNumActivations, WeaponSpecialInterface)

return WeaponSpecialDeactivateAfterNumActivations
