local AchievementTypes = require("scripts/settings/achievements/achievement_types")
local AchievementUITypes = require("scripts/settings/achievements/achievement_ui_types")
local AchievementLocKeys = require("scripts/settings/achievements/achievement_loc_keys")
local AchievementDefinition = class("AchievementDefinition")

function AchievementDefinition:init(id, ui_type, icon, category, trigger_component, visibility_component, optional_description_id, optional_description_table, optional_previous_ids)
	self._id = id
	self._category = category
	self._trigger_component = trigger_component
	self._visibility_component = visibility_component
	self._ui_type = ui_type
	self._description_id = optional_description_id or id
	self._description_table = optional_description_table or {}
	self._previous_ids = optional_previous_ids
	self._icon = icon
	local target = self._description_table.target or self:get_target()
	self._description_table.target = target
	self._description_table.x = self._description_table.x or target
	self._score = 0
	self._rewards = nil
	self._allow_solo = false
end

function AchievementDefinition:destroy()
	self._trigger_component:destroy()
	self._visibility_component:destroy()
end

function AchievementDefinition:id()
	return self._id
end

function AchievementDefinition:category()
	return self._category
end

function AchievementDefinition:ui_type()
	return self._ui_type
end

function AchievementDefinition:set_score(score)
	self._score = score
end

function AchievementDefinition:score()
	return self._score
end

function AchievementDefinition:get_rewards()
	return self._rewards
end

function AchievementDefinition:add_reward(reward)
	local rewards = self._rewards

	if not rewards then
		rewards = {}
		self._rewards = rewards
	end

	rewards[#rewards + 1] = reward
end

function AchievementDefinition:label(unlocalized)
	local label = AchievementLocKeys.labels[self._id]

	return unlocalized and label or Localize(label)
end

function AchievementDefinition:description(unlocalized)
	local description = AchievementLocKeys.descriptions[self._description_id]

	return unlocalized and description or Localize(description, true, self._description_table)
end

function AchievementDefinition:icon()
	return self._icon
end

function AchievementDefinition:get_related_achievements()
	local _, triggers = self._trigger_component:get_triggers()

	if self._ui_type == AchievementUITypes.meta then
		return triggers
	end

	return self._previous_ids
end

function AchievementDefinition:is_visible(constant_achievement_data)
	return self._visibility_component:is_visible(constant_achievement_data)
end

function AchievementDefinition:is_completed(constant_achievement_data)
	return constant_achievement_data.completed[self._id] ~= nil
end

function AchievementDefinition:completed_time(constant_achievement_data)
	local completed = constant_achievement_data.completed[self._id]

	if type(completed) == "string" then
		return completed
	end

	return nil
end

function AchievementDefinition:trigger(constant_achievement_data, trigger_type, ...)
	if self:is_completed(constant_achievement_data) then
		return false
	end

	return self._trigger_component:trigger(constant_achievement_data, trigger_type, ...)
end

function AchievementDefinition:get_triggers()
	return self._trigger_component:get_triggers()
end

function AchievementDefinition:get_target()
	return self._trigger_component:get_target()
end

function AchievementDefinition:get_progress(constant_achievement_data)
	if self:is_completed(constant_achievement_data) then
		return self:get_target()
	end

	return self._trigger_component:get_progress(constant_achievement_data)
end

return AchievementDefinition
