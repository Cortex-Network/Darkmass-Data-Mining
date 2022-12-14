local RemoteDisconnectedState = class("RemoteDisconnectedState")

function RemoteDisconnectedState:init(state_machine, shared_state)
	self._shared_state = shared_state

	if shared_state.eac_client_added then
		Managers.eac_server:remove_peer(shared_state.channel_id)

		shared_state.eac_client_added = false
	end

	if shared_state.reserved_peers then
		shared_state.slot_reserver:free_slots(shared_state.reserved_peers)

		shared_state.reserved_peers = nil
	end

	if shared_state.claimed_peer then
		shared_state.slot_reserver:free_slot(shared_state.claimed_peer, shared_state.channel_id)

		shared_state.claimed_peer = nil
	end

	local reserved_player_slots = shared_state.reserved_player_slots

	if reserved_player_slots then
		for i = 1, #reserved_player_slots do
			local slot = reserved_player_slots[i]

			Managers.player:release_slot(slot)
		end

		shared_state.reserved_player_slots = nil
	end

	if shared_state.is_state_synced then
		Managers.mechanism:remove_client(shared_state.channel_id)
	end

	shared_state.engine_lobby:close_channel(shared_state.channel_id)
end

function RemoteDisconnectedState:enter(reason)
	local shared_state = self._shared_state
	reason.peer_id = shared_state.peer_id
	reason.channel_id = shared_state.channel_id

	Log.info("RemoteDisconnectedState", "[enter] LoadingTimes: Peer Disconnected", shared_state.peer_id)

	shared_state.event_list[#shared_state.event_list + 1] = {
		name = "disconnected",
		parameters = reason
	}
end

return RemoteDisconnectedState
