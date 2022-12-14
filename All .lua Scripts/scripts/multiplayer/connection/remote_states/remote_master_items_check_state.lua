local MasterItems = require("scripts/backend/master_items")
local RPCS = {
	"rpc_request_master_items_version"
}
local RemoteMasterItemsCheckState = class("RemoteMasterItemsCheckState")

function RemoteMasterItemsCheckState:init(state_machine, shared_state)
	self._shared_state = shared_state
	self._time = 0
	self._got_request = false

	shared_state.event_delegate:register_connection_channel_events(self, shared_state.channel_id, unpack(RPCS))
end

function RemoteMasterItemsCheckState:destroy()
	local shared_state = self._shared_state

	shared_state.event_delegate:unregister_channel_events(shared_state.channel_id, unpack(RPCS))
end

function RemoteMasterItemsCheckState:update(dt)
	local shared_state = self._shared_state
	self._time = self._time + dt

	if shared_state.timeout < self._time then
		Log.info("RemoteMasterItemsCheckState", "Timeout waiting for rpc_request_master_items_version %s", shared_state.peer_id)

		return "timeout", {
			game_reason = "timeout"
		}
	end

	local state, reason = Network.channel_state(shared_state.channel_id)

	if state == "disconnected" then
		Log.info("RemoteMasterItemsCheckState", "Connection channel disconnect %s", shared_state.peer_id)

		return "disconnected", {
			engine_reason = reason
		}
	end

	if self._got_request then
		local items_metadata = MasterItems.get_cached_metadata()
		local version = items_metadata.version

		if not version then
			return "missing version", {
				game_reason = "missing_master_items_version"
			}
		end

		local url = nil

		if version == 0 then
			url = "no_url"
		else
			url = items_metadata.url
		end

		Log.info("RemoteMasterItemsCheckState", "Replying peer %s with master items version %s, %s", shared_state.peer_id, version, url)
		RPC.rpc_master_items_version_reply(shared_state.channel_id, tostring(version), url)

		return "version replied"
	end
end

function RemoteMasterItemsCheckState:rpc_request_master_items_version(channel_id)
	self._got_request = true
end

return RemoteMasterItemsCheckState
