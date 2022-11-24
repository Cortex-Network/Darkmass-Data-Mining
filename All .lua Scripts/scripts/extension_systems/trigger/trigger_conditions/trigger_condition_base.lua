local TriggerSettings = require("scripts/extension_systems/trigger/trigger_settings")
local ONLY_ONCE = TriggerSettings.only_once
local TriggerConditionBase = class("TriggerConditionBase")

function TriggerConditionBase:init(engine_volume_event_system, is_server, volume_unit, only_once, condition_name, evaluates_bots)
	self._volume_unit = volume_unit
	self._registered_units = {}
	self._num_registered_units = 0
	self._condition_name = condition_name
	self._evaluates_bots = evaluates_bots
	self._engine_volume_event_system = engine_volume_event_system
	self._is_server = is_server
	self._only_once = only_once
	self._triggered_by_units = {}
	self._num_times_triggered = {}
	self._triggered_by_entering_unit = {}
	self._was_triggered_by_entering_unit = {}
end

function TriggerConditionBase:destroy()
	table.clear(self._registered_units)

	self._registered_units = nil
	self._num_registered_units = nil
	self._condition_name = nil
	self._evaluates_bots = nil
end

function TriggerConditionBase:on_volume_enter(entering_unit, dt, t)
	return false
end

function TriggerConditionBase:on_volume_exit(exiting_unit)
	return false
end

function TriggerConditionBase:filter_passed(filter_unit, volume_id)
	return false
end

function TriggerConditionBase:can_trigger_from_unit(entering_unit)
	local can_trigger = true
	local only_once = self._only_once

	if only_once == ONLY_ONCE.only_once_per_unit then
		can_trigger = not self:_was_triggered_by_unit(entering_unit)
	elseif only_once == ONLY_ONCE.only_once_for_all_units then
		can_trigger = not self:_was_triggered_by_unit()
	end

	return can_trigger
end

function TriggerConditionBase:set_triggered_by_unit(entering_unit, value)
	self._triggered_by_entering_unit[entering_unit] = value
end

function TriggerConditionBase:set_was_triggered_by_unit(entering_unit, value)
	self._was_triggered_by_entering_unit[entering_unit] = value
end

function TriggerConditionBase:is_triggered(entering_unit)
	if entering_unit then
		return self._triggered_by_entering_unit[entering_unit]
	else
		return table.size(self._triggered_by_entering_unit) > 0
	end
end

function TriggerConditionBase:_was_triggered_by_unit(entering_unit)
	if entering_unit then
		return self._was_triggered_by_entering_unit[entering_unit]
	else
		return table.size(self._was_triggered_by_entering_unit) > 0
	end
end

function TriggerConditionBase:registered_units()
	return self._registered_units
end

function TriggerConditionBase:_register_unit(unit)
	if not self._registered_units[unit] then
		self._registered_units[unit] = true
		self._num_registered_units = self._num_registered_units + 1

		return true
	end

	return false
end

function TriggerConditionBase:_unregister_unit(unit)
	if self._registered_units[unit] then
		self._registered_units[unit] = nil
		self._num_registered_units = self._num_registered_units - 1

		return true
	end

	return false
end

return TriggerConditionBase
