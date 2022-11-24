local TriggerInterface = require("scripts/managers/achievements/triggers/achievement_trigger_interface")
local StatTrigger = require("scripts/managers/achievements/triggers/achievement_stat_trigger")
local AchievementIncreasingStatTrigger = class("AchievementIncreasingStatTrigger", "AchievementStatTrigger")

function AchievementIncreasingStatTrigger:_check_complete(stat_value)
	return self._target <= stat_value
end

function AchievementIncreasingStatTrigger:_default_value()
	return 0
end

implements(AchievementIncreasingStatTrigger, TriggerInterface, StatTrigger.INTERFACE)

return AchievementIncreasingStatTrigger
