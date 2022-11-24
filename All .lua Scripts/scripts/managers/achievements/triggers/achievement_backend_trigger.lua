local TriggerInterface = require("scripts/managers/achievements/triggers/achievement_trigger_interface")
local AchievementBackendTrigger = class("AchievementBackendTrigger")

function AchievementBackendTrigger:init(_, target)
	self._target = target or 1
end

function AchievementBackendTrigger:destroy()
end

function AchievementBackendTrigger:trigger()
	return false
end

function AchievementBackendTrigger:get_triggers()
end

function AchievementBackendTrigger:get_target()
	return self._target
end

function AchievementBackendTrigger:get_progress(constant_achievement_data)
	return 0
end

function AchievementBackendTrigger:get_related_achievements()
	return nil
end

implements(AchievementBackendTrigger, TriggerInterface)

return AchievementBackendTrigger
