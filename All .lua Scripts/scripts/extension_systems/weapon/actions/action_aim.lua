require("scripts/extension_systems/weapon/actions/action_weapon_base")

local AlternateFire = require("scripts/utilities/alternate_fire")
local ActionAim = class("ActionAim", "ActionWeaponBase")

function ActionAim:init(action_context, action_params, action_settings)
	ActionAim.super.init(self, action_context, action_params, action_settings)

	local unit_data_extension = action_context.unit_data_extension
	self._spread_control_component = unit_data_extension:write_component("spread_control")
	self._sway_control_component = unit_data_extension:write_component("sway_control")
	self._sway_component = unit_data_extension:read_component("sway")
	self._alternate_fire_component = unit_data_extension:write_component("alternate_fire")
end

function ActionAim:start(action_settings, t, ...)
	ActionAim.super.start(self, action_settings, t, ...)
	AlternateFire.start(self._alternate_fire_component, self._weapon_tweak_templates_component, self._spread_control_component, self._sway_control_component, self._sway_component, self._movement_state_component, self._first_person_extension, self._animation_extension, self._weapon_extension, self._weapon_template, self._player_unit, t)
end

return ActionAim
