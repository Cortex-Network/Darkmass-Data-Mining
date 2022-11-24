local VisibilityInterface = require("scripts/managers/achievements/visibility/achievement_visibility_interface")
local AchievementVisibilityChain = class("AchievementVisibilityChain")

function AchievementVisibilityChain:init(achievement_id, show_in_progress, optional_previous_id, optional_next_id)
	self._show_in_progress = show_in_progress
	self._achievement_id = achievement_id
	self._previous_id = optional_previous_id
	self._next_id = optional_next_id
end

function AchievementVisibilityChain:is_visible(constant_achievement_data)
	if self._previous_id ~= nil and not constant_achievement_data.completed[self._previous_id] then
		return false
	end

	if self._next_id ~= nil and constant_achievement_data.completed[self._next_id] then
		return false
	end

	return self._show_in_progress or constant_achievement_data.completed[self._achievement_id]
end

function AchievementVisibilityChain:destroy()
end

implements(AchievementVisibilityChain, VisibilityInterface)

return AchievementVisibilityChain
