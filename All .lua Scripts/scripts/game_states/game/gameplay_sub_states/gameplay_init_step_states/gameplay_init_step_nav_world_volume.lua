local GameplayInitStepInterface = require("scripts/game_states/game/gameplay_sub_states/gameplay_init_step_states/gameplay_init_step_state_interface")
local GameplayInitStepNavSpawnPoints = require("scripts/game_states/game/gameplay_sub_states/gameplay_init_step_states/gameplay_init_step_nav_spawn_points")
local GameplayInitStepNavWorldVolume = class("GameplayInitStepNavWorldVolume")

function GameplayInitStepNavWorldVolume:init()
	self._skipped_first_update = false
end

function GameplayInitStepNavWorldVolume:on_enter(parent, params)
	self._shared_state = params.shared_state
end

function GameplayInitStepNavWorldVolume:update(main_dt, main_t)
	if not self._skipped_first_update then
		self._skipped_first_update = true

		return nil, 
	end

	local nav_mesh_manager = Managers.state.nav_mesh
	local is_navmesh_post_initialized = nav_mesh_manager:update_time_slice_volumes_integration()

	if not is_navmesh_post_initialized then
		return nil, 
	else
		nav_mesh_manager:on_gameplay_post_init()
	end

	local next_step_params = {
		shared_state = self._shared_state
	}

	return GameplayInitStepNavSpawnPoints, next_step_params
end

implements(GameplayInitStepNavWorldVolume, GameplayInitStepInterface)

return GameplayInitStepNavWorldVolume
