local WeaponSpecialInterface = require("scripts/extension_systems/weapon/special_classes/weapon_special_interface")
local WeaponSpecialHoldActivated = class("WeaponSpecialHoldActivated")

function WeaponSpecialHoldActivated:init(context, init_data)
	self._input_extension = context.input_extension
	self._inventory_slot_component = init_data.inventory_slot_component
end

function WeaponSpecialHoldActivated:update(dt, t)
	if self._inventory_slot_component.special_active then
		self:_update_active(dt, t)
	else
		self:_update_activation(dt, t)
	end
end

function WeaponSpecialHoldActivated:_update_active(dt, t)
	if not self._input_extension:get("weapon_extra_hold") then
		self._inventory_slot_component.special_active = false
		self._inventory_slot_component.num_special_activations = 0
	end
end

function WeaponSpecialHoldActivated:_update_activation(dt, t)
	if self._input_extension:get("weapon_extra_hold") then
		self._inventory_slot_component.special_active = true
		self._inventory_slot_component.special_active_start_t = t
	end
end

function WeaponSpecialHoldActivated:process_hit(t, weapon, action_settings, num_hit_enemies, target_is_alive, target_unit, hit_position, attack_direction, optional_origin_slot)
end

function WeaponSpecialHoldActivated:on_action_start(t, num_hit_enemies)
end

function WeaponSpecialHoldActivated:on_action_finish(t, num_hit_enemies)
end

function WeaponSpecialHoldActivated:on_exit_damage_window(t, num_hit_enemies)
end

implements(WeaponSpecialHoldActivated, WeaponSpecialInterface)

return WeaponSpecialHoldActivated
