local GameplayInitStepInterface = require("scripts/game_states/game/gameplay_sub_states/gameplay_init_step_states/gameplay_init_step_state_interface")
local GameplayInitStepMainPathOcclusion = require("scripts/game_states/game/gameplay_sub_states/gameplay_init_step_states/gameplay_init_step_main_path_occlusion")
local GameplayInitStepNavSpawnPoints = class("GameplayInitStepNavSpawnPoints")

function GameplayInitStepNavSpawnPoints:init()
	self._skipped_first_update = false
end

function GameplayInitStepNavSpawnPoints:on_enter(parent, params)
	local shared_state = params.shared_state
	self._shared_state = shared_state

	Managers.state.main_path:on_gameplay_post_init()
end

function GameplayInitStepNavSpawnPoints:update(main_dt, main_t)
	if not self._skipped_first_update then
		self._skipped_first_update = true

		return nil, 
	end

	local main_path_manager = Managers.state.main_path
	local spawn_points_initialized = main_path_manager:update_time_slice_spawn_points()

	if not spawn_points_initialized then
		return nil, 
	end

	local next_step_params = {
		shared_state = self._shared_state
	}

	return GameplayInitStepMainPathOcclusion, next_step_params
end

implements(GameplayInitStepNavSpawnPoints, GameplayInitStepInterface)

return GameplayInitStepNavSpawnPoints
