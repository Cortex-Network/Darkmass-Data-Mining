local AchievementTypes = require("scripts/settings/achievements/achievement_types")
local TriggerInterface = require("scripts/managers/achievements/triggers/achievement_trigger_interface")
local AchievementEventTrigger = class("AchievementEventTrigger")

function AchievementEventTrigger:init(event_name, optional_keys, optional_values)
	self._event_name = event_name
	self._triggers = {
		event_name
	}
	self._keys = optional_keys or {}
	self._values = optional_values or {}
end

function AchievementEventTrigger:destroy()
end

function AchievementEventTrigger:trigger(constant_achievement_data, trigger_type, event_name, event_params)
	if trigger_type ~= AchievementTypes.event then
		return false
	end

	if event_name ~= self._event_name then
		return false
	end

	for i = 1, #self._keys do
		local real_value = event_params[self._keys[i]]
		local expected_value = self._values[i]

		if real_value ~= expected_value then
			return false
		end
	end

	return true
end

function AchievementEventTrigger:get_triggers()
	return AchievementTypes.event, self._triggers
end

function AchievementEventTrigger:get_target()
	return 1
end

function AchievementEventTrigger:get_progress(constant_achievement_data)
	return 0
end

function AchievementEventTrigger:get_related_achievements()
end

implements(AchievementEventTrigger, TriggerInterface)

return AchievementEventTrigger
