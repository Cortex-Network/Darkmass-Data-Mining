local LocalLoadFailState = class("LocalLoadFailState")

function LocalLoadFailState:init(state_machine, shared_state)
	shared_state.state = "failed"
end

return LocalLoadFailState
