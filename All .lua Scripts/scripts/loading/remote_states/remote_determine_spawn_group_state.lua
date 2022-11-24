local RPCS = {
	"rpc_request_spawn_group"
}
local RemoteDetermineSpawnGroupState = class("RemoteDetermineSpawnGroupState")

function RemoteDetermineSpawnGroupState:init(state_machine, shared_state)
	self._shared_state = shared_state
	self._got_request = false
	self._time = 0

	Log.info("RemoteDetermineSpawnGroupState", "[init] LoadingTimes: Server started waiting for Spawn Group request from peer", shared_state.client_peer_id)
	shared_state.network_delegate:register_connection_channel_events(self, shared_state.client_channel_id, unpack(RPCS))
end

function RemoteDetermineSpawnGroupState:destroy()
	local shared_state = self._shared_state

	shared_state.network_delegate:unregister_channel_events(shared_state.client_channel_id, unpack(RPCS))
end

function RemoteDetermineSpawnGroupState:update(dt)
	local shared_state = self._shared_state

	if self._got_request and shared_state.spawn_group then
		RPC.rpc_request_spawn_group_reply(shared_state.client_channel_id, shared_state.spawn_group)

		return "spawn_group_done"
	end
end

function RemoteDetermineSpawnGroupState:rpc_request_spawn_group(channel_id)
	local shared_state = self._shared_state
	self._got_request = true

	local function callback(spawn_group)
		shared_state.spawn_group = spawn_group
	end

	shared_state.spawn_queue:place_in_queue(shared_state.client_peer_id, callback)
	Log.info("RemoteDetermineSpawnGroupState", "[rpc_request_spawn_group] LoadingTimes: Peer(%s) Requested and Added to Spawn Group", shared_state.client_peer_id)
end

return RemoteDetermineSpawnGroupState
