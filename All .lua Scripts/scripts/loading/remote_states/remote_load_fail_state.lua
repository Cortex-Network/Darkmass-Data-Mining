local RemoteLoadFailState = class("RemoteLoadFailState")

function RemoteLoadFailState:init(state_machine, shared_state)
	shared_state.state = "failed"
end

return RemoteLoadFailState
