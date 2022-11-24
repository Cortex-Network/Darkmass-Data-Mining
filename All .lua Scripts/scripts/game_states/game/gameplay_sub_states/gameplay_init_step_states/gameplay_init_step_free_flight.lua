local GameplayInitStepInterface = require("scripts/game_states/game/gameplay_sub_states/gameplay_init_step_states/gameplay_init_step_state_interface")
local GameplayInitStepGameSession = require("scripts/game_states/game/gameplay_sub_states/gameplay_init_step_states/gameplay_init_step_game_session")
local GameplayInitStepFreeFlight = class("GameplayInitStepFreeFlight")

function GameplayInitStepFreeFlight:on_enter(parent, params)
	local shared_state = params.shared_state
	self._shared_state = shared_state
	local is_server = shared_state.is_server
end

function GameplayInitStepFreeFlight:update(main_dt, main_t)
	local next_step_params = {
		shared_state = self._shared_state
	}

	return GameplayInitStepGameSession, next_step_params
end

implements(GameplayInitStepFreeFlight, GameplayInitStepInterface)

return GameplayInitStepFreeFlight
