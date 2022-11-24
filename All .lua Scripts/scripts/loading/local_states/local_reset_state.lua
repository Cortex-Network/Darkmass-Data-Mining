local LocalResetState = class("LocalResetState")

function LocalResetState:init(state_machine, shared_state)
	self._shared_state = shared_state
	shared_state.state = "loading"
	self._mission_name = nil
end

function LocalResetState:destroy()
	self._mission_name = nil
end

function LocalResetState:update()
	if self._mission_name ~= nil then
		return "start_load"
	end
end

function LocalResetState:load_mission()
	local shared_state = self._shared_state
	local mission_name = shared_state.mission_name
	self._mission_name = mission_name
end

return LocalResetState
