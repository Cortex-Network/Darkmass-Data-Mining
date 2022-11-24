local Promise = require("scripts/foundation/utilities/promise")
local PlatformAchievementInterface = require("scripts/managers/achievements/platforms/platform_achievement_interface")
local NoPlatformAchievement = class("NoPlatformAchievement")

function NoPlatformAchievement:init()
	return Promise.resolved()
end

function NoPlatformAchievement:unlock_achievement(achievement_id)
	return false
end

function NoPlatformAchievement:update_progress(achievement_id, value, target)
	return false
end

function NoPlatformAchievement:is_unlocked(achievement_id)
	return false
end

function NoPlatformAchievement:get_progress(achievement_id)
	return nil
end

function NoPlatformAchievement:is_platform_achievement(achievement_id)
	return false
end

implements(NoPlatformAchievement, PlatformAchievementInterface)

return NoPlatformAchievement
