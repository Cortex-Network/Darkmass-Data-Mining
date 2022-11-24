local VisibilityInterface = require("scripts/managers/achievements/visibility/achievement_visibility_interface")
local AchievementVisibilityHidden = class("AchievementVisibilityHidden")

function AchievementVisibilityHidden:init(achievement_id)
	self._achievement_id = achievement_id
end

function AchievementVisibilityHidden:is_visible(constant_achievement_data)
	return constant_achievement_data.completed[self._achievement_id] ~= nil
end

function AchievementVisibilityHidden:destroy()
end

implements(AchievementVisibilityHidden, VisibilityInterface)

return AchievementVisibilityHidden
