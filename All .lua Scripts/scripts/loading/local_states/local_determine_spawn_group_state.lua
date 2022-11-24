local MissionTemplates = require("scripts/settings/mission/mission_templates")
local RPCS = {
	"rpc_request_spawn_group_reply"
}
local LocalDetermineSpawnGroupState = class("LocalDetermineSpawnGroupState")

function LocalDetermineSpawnGroupState:init(state_machine, shared_state)
	self._shared_state = shared_state
	self._got_response = false

	shared_state.network_delegate:register_connection_channel_events(self, shared_state.host_channel_id, unpack(RPCS))
	RPC.rpc_request_spawn_group(shared_state.host_channel_id)
end

function LocalDetermineSpawnGroupState:destroy()
	local shared_state = self._shared_state

	shared_state.network_delegate:unregister_channel_events(shared_state.host_channel_id, unpack(RPCS))
end

function LocalDetermineSpawnGroupState:update(dt)
	if self._got_response then
		local shared_state = self._shared_state
		local mission_name = shared_state.mission_name
		local mission_template = MissionTemplates[mission_name]
		local is_hub = mission_template.is_hub

		if is_hub then
			return "spawn_group_set_hub"
		else
			return "spawn_group_set_mission"
		end
	end
end

function LocalDetermineSpawnGroupState:rpc_request_spawn_group_reply(channel_id, group)
	self._shared_state.spawn_group = group
	self._got_response = true
end

return LocalDetermineSpawnGroupState
