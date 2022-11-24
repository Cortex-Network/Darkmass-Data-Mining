local VisibilityInterface = require("scripts/managers/achievements/visibility/achievement_visibility_interface")
local AchievementVisibilityAlways = class("AchievementVisibilityAlways")

function AchievementVisibilityAlways:is_visible(constant_achievement_data)
	return true
end

function AchievementVisibilityAlways:destroy()
end

implements(AchievementVisibilityAlways, VisibilityInterface)

return AchievementVisibilityAlways
