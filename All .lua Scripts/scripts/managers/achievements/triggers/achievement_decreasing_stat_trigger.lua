local TriggerInterface = require("scripts/managers/achievements/triggers/achievement_trigger_interface")
local StatTrigger = require("scripts/managers/achievements/triggers/achievement_stat_trigger")
local AchievementDecreasingStatTrigger = class("AchievementDecreasingStatTrigger", "AchievementStatTrigger")

function AchievementDecreasingStatTrigger:_check_complete(stat_value)
	return stat_value <= self._target
end

function AchievementDecreasingStatTrigger:_default_value()
	return math.huge
end

implements(AchievementDecreasingStatTrigger, TriggerInterface, StatTrigger.INTERFACE)

return AchievementDecreasingStatTrigger
