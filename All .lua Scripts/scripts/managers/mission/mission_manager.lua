local MissionObjectiveTemplates = require("scripts/settings/mission_objective/mission_objective_templates")
local MissionTemplates = require("scripts/settings/mission/mission_templates")
local MissionTypes = require("scripts/settings/mission/mission_types")
local MissionSettings = require("scripts/settings/mission/mission_settings")
local mission_zone_ids = MissionSettings.mission_zone_ids
local mission_game_mode_names = MissionSettings.mission_game_mode_names
local main_objective_names = MissionSettings.main_objective_names
local MissionManager = class("MissionManager")
MissionManager.SIDE_MISSION_TYPES = table.enum("none", "luggable", "collect")
local SIDE_MISSION_TYPES = MissionManager.SIDE_MISSION_TYPES

function MissionManager:init(mission_name, level, level_name, side_mission_name)
	rawset(_G, "SPAWNED_LEVEL_NAME", level_name)

	local mission = MissionTemplates[mission_name]
	local side_mission = nil

	if side_mission_name ~= "default" then
		side_mission = MissionObjectiveTemplates.side_mission.objectives[side_mission_name]
	end

	self._mission_level = level
	self._mission_name = mission_name
	self._mission = mission
	self._side_mission = side_mission
	self._side_mission_name = side_mission_name
	self._side_mission_type = SIDE_MISSION_TYPES.none

	if side_mission then
		self:_set_side_mission_type(side_mission.side_objective_type)
	end
end

function MissionManager:destroy()
	rawset(_G, "SPAWNED_LEVEL_NAME", nil)
end

function MissionManager:mission_level()
	return self._mission_level
end

function MissionManager:side_mission()
	return self._side_mission
end

function MissionManager:mission()
	return self._mission
end

function MissionManager:mission_name()
	return self._mission_name
end

function MissionManager:side_mission_name()
	return self._side_mission_name
end

function MissionManager:force_third_person_mode()
	return self._mission.force_third_person_mode or false
end

function MissionManager:_set_side_mission_type(side_mission_type)
	self._side_mission_type = side_mission_type
end

function MissionManager:side_mission_is_pickup()
	return self._side_mission_type == SIDE_MISSION_TYPES.collect
end

function MissionManager:side_mission_is_luggable()
	return self._side_mission_type == SIDE_MISSION_TYPES.luggable
end

function MissionManager:main_objective_type()
	local mission = self._mission
	local mission_type = MissionTypes[mission.mission_type]

	return mission_type and mission_type.id or -1
end

return MissionManager
