local BoneLodManager = require("scripts/managers/bone_lod/bone_lod_manager")
local GameplayInitStepInterface = require("scripts/game_states/game/gameplay_sub_states/gameplay_init_step_states/gameplay_init_step_state_interface")
local GameplayInitStepNavigation = require("scripts/game_states/game/gameplay_sub_states/gameplay_init_step_states/gameplay_init_step_navigation")
local GameplayInitStepBoneLod = class("GameplayInitStepBoneLod")

function GameplayInitStepBoneLod:on_enter(parent, params)
	local shared_state = params.shared_state
	self._shared_state = shared_state
	local world = shared_state.world
	local is_server = shared_state.is_server
	Managers.state.bone_lod = BoneLodManager:new(world, DEDICATED_SERVER, is_server)
end

function GameplayInitStepBoneLod:update(main_dt, main_t)
	local next_step_params = {
		shared_state = self._shared_state
	}

	return GameplayInitStepNavigation, next_step_params
end

implements(GameplayInitStepBoneLod, GameplayInitStepInterface)

return GameplayInitStepBoneLod
