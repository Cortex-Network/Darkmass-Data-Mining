local Overheat = require("scripts/utilities/overheat")
local OverheatActionModule = class("OverheatActionModule")

function OverheatActionModule:init(player_unit, action_settings, inventory_slot_component)
	self._player_unit = player_unit
	self._action_settings = action_settings
	self._inventory_slot_component = inventory_slot_component
	local unit_data_extension = ScriptUnit.extension(player_unit, "unit_data_system")
	self._charge_component = unit_data_extension:write_component("action_module_charge")
	self._weapon_extension = ScriptUnit.extension(player_unit, "weapon_system")
end

function OverheatActionModule:start(action_settings, t)
	self._inventory_slot_component.overheat_state = "increasing"
end

function OverheatActionModule:fixed_update(dt, t)
	local charge_level = self._charge_component.charge_level
	local charge_template = self._weapon_extension:charge_template()
	local inventory_slot_component = self._inventory_slot_component

	Overheat.increase_over_time(dt, t, charge_level, inventory_slot_component, charge_template, self._player_unit)
end

function OverheatActionModule:finish(reason, data, t)
	self._inventory_slot_component.overheat_state = "idle"
end

function OverheatActionModule:running_action_state(t, time_in_action)
	local charge_level = self._charge_component.charge_level
	local current_heat = self._inventory_slot_component.overheat_current_percentage

	if current_heat >= 0.99 then
		self._inventory_slot_component.overheat_state = "idle"

		return "overheating"
	end

	local charge_template = self._weapon_extension:charge_template()
	local fully_charged_charge_level = charge_template.fully_charged_charge_level or 1

	if charge_level >= fully_charged_charge_level then
		return "fully_charged"
	end

	return nil
end

return OverheatActionModule
