local GameplayInitStepInterface = require("scripts/game_states/game/gameplay_sub_states/gameplay_init_step_states/gameplay_init_step_state_interface")
local GameplayInitStepMissionServer = require("scripts/game_states/game/gameplay_sub_states/gameplay_init_step_states/gameplay_init_step_mission_server")
local GameplayInitStepBreedTester = class("GameplayInitStepBreedTester")

function GameplayInitStepBreedTester:init()
	self._skipped_first_update = false
end

function GameplayInitStepBreedTester:on_enter(parent, params)
	local shared_state = params.shared_state
	self._shared_state = shared_state
end

function GameplayInitStepBreedTester:update(main_dt, main_t)
	if not self._skipped_first_update then
		self._skipped_first_update = true

		return nil, 
	end

	local shared_state = self._shared_state
	local is_breed_unit_tester_init = true

	if not is_breed_unit_tester_init then
		return nil, 
	end

	local next_step_params = {
		shared_state = shared_state
	}

	return GameplayInitStepMissionServer, next_step_params
end

implements(GameplayInitStepBreedTester, GameplayInitStepInterface)

return GameplayInitStepBreedTester
