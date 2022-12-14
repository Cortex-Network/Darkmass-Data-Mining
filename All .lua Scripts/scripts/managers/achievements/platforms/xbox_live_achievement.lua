local Promise = require("scripts/foundation/utilities/promise")
local PlatformAchievementInterface = require("scripts/managers/achievements/platforms/platform_achievement_interface")
local XboxLivePlatformAchievements = require("scripts/settings/achievements/xbox_live_platform_achievements")
local XboxLiveUtilities = require("scripts/foundation/utilities/xbox_live")
local XboxLiveAchievement = class("XboxLiveAchievement")

local function _get_platform_id(achievement_id)
	return XboxLivePlatformAchievements.backend_to_platform[achievement_id]
end

function XboxLiveAchievement:_set_progress(platform_id, percent)
	local current_percent = self._progress[platform_id] or 0
	local show_progress = XboxLivePlatformAchievements.show_progress[platform_id]

	if (percent == 100 or show_progress) and current_percent < percent then
		self._progress[platform_id] = percent

		XboxLiveUtilities.update_achievement(platform_id, percent)
	end
end

function XboxLiveAchievement:_get_progress(platform_id)
	return self._progress[platform_id] or 0
end

function XboxLiveAchievement:init()
	self._progress = {}

	return Promise.resolved()
end

function XboxLiveAchievement:unlock_achievement(achievement_id)
	local platform_id = _get_platform_id(achievement_id)

	if platform_id then
		self:_set_progress(platform_id, 100)

		return true
	end

	return false
end

function XboxLiveAchievement:update_progress(achievement_id, value, target)
	local platform_id = _get_platform_id(achievement_id)
	local progress_in_percentage = math.floor(100 * value / target)

	if platform_id and progress_in_percentage < 100 then
		self:_set_progress(platform_id, progress_in_percentage)

		return true
	end

	return false
end

function XboxLiveAchievement:is_unlocked(achievement_id)
	local platform_id = _get_platform_id(achievement_id)

	return platform_id ~= nil and self:_get_progress(platform_id) == 100
end

function XboxLiveAchievement:get_progress(achievement_id)
	local platform_id = _get_platform_id(achievement_id)

	return platform_id and self:_get_progress(platform_id)
end

function XboxLiveAchievement:is_platform_achievement(achievement_id)
	return _get_platform_id(achievement_id) ~= nil
end

implements(XboxLiveAchievement, PlatformAchievementInterface)

return XboxLiveAchievement
