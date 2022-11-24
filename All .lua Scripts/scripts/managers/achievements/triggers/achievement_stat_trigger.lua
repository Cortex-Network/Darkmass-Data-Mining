local AchievementTypes = require("scripts/settings/achievements/achievement_types")
local AchievementStatTrigger = class("AchievementStatTrigger")
AchievementStatTrigger.INTERFACE = {
	"_default_value",
	"_check_complete"
}

function AchievementStatTrigger:init(stat_definition, target)
	self._stat_name = stat_definition:get_id()
	self._triggers = {
		stat_definition:get_id()
	}
	self._target = target
end

function AchievementStatTrigger:destroy()
end

function AchievementStatTrigger:trigger(_, trigger_type, stat_name, stat_value)
	if trigger_type ~= AchievementTypes.stat then
		return false
	end

	if stat_name ~= self._stat_name then
		return false
	end

	return self:_check_complete(stat_value)
end

function AchievementStatTrigger:get_triggers()
	return AchievementTypes.stat, self._triggers
end

function AchievementStatTrigger:get_target()
	return self._target
end

function AchievementStatTrigger:get_progress(constant_achievement_data)
	return constant_achievement_data.stats[self._stat_name] or self:_default_value()
end

function AchievementStatTrigger:get_related_achievements()
end

return AchievementStatTrigger
