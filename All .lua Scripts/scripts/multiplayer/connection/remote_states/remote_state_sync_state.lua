local RPCS = {
	"rpc_check_connected"
}
local RemoteStateSyncState = class("RemoteStateSyncState")

function RemoteStateSyncState:init(state_machine, shared_state)
	self._shared_state = shared_state
	self._request_has_arrived = false
	self._time = 0

	shared_state.event_delegate:register_connection_channel_events(self, shared_state.channel_id, unpack(RPCS))
end

function RemoteStateSyncState:destroy()
	local shared_state = self._shared_state

	shared_state.event_delegate:unregister_channel_events(shared_state.channel_id, unpack(RPCS))
end

function RemoteStateSyncState:update(dt)
	local shared_state = self._shared_state
	local state, reason = Network.channel_state(shared_state.channel_id)

	if state == "disconnected" then
		Log.info("RemoteConnectedState", "Connection channel disconnected %s", shared_state.peer_id)

		return "disconnected", {
			engine_reason = reason
		}
	end

	if self._request_has_arrived then
		Managers.mechanism:add_client(shared_state.channel_id)

		shared_state.is_state_synced = true

		return "state sync done"
	end

	self._time = self._time + dt

	if shared_state.timeout < self._time then
		Log.info("RemoteStateSyncState", "Timeout waiting for rpc_check_connected from %s", shared_state.peer_id)

		return "timeout", {
			game_reason = "timeout"
		}
	end
end

function RemoteStateSyncState:rpc_check_connected(channel_id)
	self._request_has_arrived = true
end

return RemoteStateSyncState
