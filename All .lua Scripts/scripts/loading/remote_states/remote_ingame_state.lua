local RemoteIngameState = class("RemoteIngameState")

function RemoteIngameState:init(state_machine, shared_state)
	self._shared_state = shared_state
	shared_state.state = "playing"
end

return RemoteIngameState
