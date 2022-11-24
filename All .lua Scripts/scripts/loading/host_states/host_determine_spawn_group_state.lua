local HostDetermineSpawnGroupState = class("HostDetermineSpawnGroupState")

function HostDetermineSpawnGroupState:init(state_machine, shared_state)
	self._shared_state = shared_state

	local function callback(spawn_group)
		shared_state.spawn_group = spawn_group
	end

	shared_state.spawn_queue:place_in_queue(Network.peer_id(), callback)
end

function HostDetermineSpawnGroupState:update(dt)
	if self._shared_state.spawn_group then
		return "spawn_group_done"
	end
end

return HostDetermineSpawnGroupState
