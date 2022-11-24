local GameplayInitStepInterface = require("scripts/game_states/game/gameplay_sub_states/gameplay_init_step_states/gameplay_init_step_state_interface")
local GameplayInitStepBoneLod = require("scripts/game_states/game/gameplay_sub_states/gameplay_init_step_states/gameplay_init_step_bone_lod")
local MissionManager = require("scripts/managers/mission/mission_manager")
local GameplayInitStepMission = class("GameplayInitStepMission")

function GameplayInitStepMission:on_enter(parent, params)
	local shared_state = params.shared_state
	self._shared_state = shared_state
	local mission_name = shared_state.mission_name
	local level = shared_state.level
	local level_name = shared_state.level_name
	local side_mission = shared_state.side_mission
	Managers.state.mission = MissionManager:new(mission_name, level, level_name, side_mission)
end

function GameplayInitStepMission:update(main_dt, main_t)
	local next_step_params = {
		shared_state = self._shared_state
	}

	return GameplayInitStepBoneLod, next_step_params
end

implements(GameplayInitStepMission, GameplayInitStepInterface)

return GameplayInitStepMission
