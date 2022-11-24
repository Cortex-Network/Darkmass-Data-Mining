local GameplayInitStepInterface = require("scripts/game_states/game/gameplay_sub_states/gameplay_init_step_states/gameplay_init_step_state_interface")
local GameplayInitStepNvidiaAiAgent = require("scripts/game_states/game/gameplay_sub_states/gameplay_init_step_states/gameplay_init_step_nvidia_ai_agent")
local GameplayInitStepPresence = class("GameplayInitStepPresence")

function GameplayInitStepPresence:on_enter(parent, params)
	self._shared_state = params.shared_state

	self:_init_presence()
end

function GameplayInitStepPresence:update(main_dt, main_t)
	local next_step_params = {
		shared_state = self._shared_state
	}

	return GameplayInitStepNvidiaAiAgent, next_step_params
end

function GameplayInitStepPresence:_init_presence()
	local presence_name = Managers.state.game_mode:presence_name()

	if presence_name then
		Managers.presence:set_presence(presence_name)
	end
end

implements(GameplayInitStepPresence, GameplayInitStepInterface)

return GameplayInitStepPresence
