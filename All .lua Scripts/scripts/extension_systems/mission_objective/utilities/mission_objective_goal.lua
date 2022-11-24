require("scripts/extension_systems/mission_objective/utilities/mission_objective_base")

local MissionObjectiveGoal = class("MissionObjectiveGoal", "MissionObjectiveBase")

function MissionObjectiveGoal:init()
	MissionObjectiveGoal.super.init(self)
	self:set_updated_externally(true)
end

return MissionObjectiveGoal
