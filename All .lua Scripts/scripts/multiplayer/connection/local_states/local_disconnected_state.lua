local LocalDisconnectedState = class("LocalDisconnectedState")

function LocalDisconnectedState:init(state_machine, shared_state)
	self._shared_state = shared_state
	local has_eac = false

	if has_eac and Managers.eac_client:in_session() then
		Managers.eac_client:end_session()
	end

	if shared_state.started_state_sync then
		Managers.mechanism:disconnect(shared_state.channel_id)
	end

	shared_state.engine_lobby:close_channel(shared_state.channel_id)
end

function LocalDisconnectedState:enter(reason)
	local shared_state = self._shared_state
	reason.peer_id = shared_state.host_peer_id
	reason.channel_id = shared_state.channel_id
	shared_state.event_list[#shared_state.event_list + 1] = {
		name = "disconnected",
		parameters = reason
	}
end

return LocalDisconnectedState
