local PresenceSettings = require("scripts/settings/presence/presence_settings")
local VotingNetworkInterface = require("scripts/managers/voting/voting_network_interface")

local function _info(...)
	Log.info("PartyManagerDummy", ...)
end

local PartyManagerDummy = class("PartyManagerDummy")

function PartyManagerDummy:init(network_hash, platform, event_delegate, approve_channel_delegate, initial_presence_name)
	self:set_presence(initial_presence_name)
end

function PartyManagerDummy:destroy()
end

function PartyManagerDummy:leave()
end

function PartyManagerDummy:is_host()
	return true
end

function PartyManagerDummy:is_client()
	return false
end

function PartyManagerDummy:is_booting()
	return false
end

function PartyManagerDummy:state()
	return "host"
end

function PartyManagerDummy:member_peers()
	return {}
end

function PartyManagerDummy:num_other_members()
	return 0
end

function PartyManagerDummy:members()
	return {}
end

function PartyManagerDummy:member_including_local()
	return nil
end

function PartyManagerDummy:member_from_unique_id(unique_id)
	return nil
end

function PartyManagerDummy:peer_to_channel(peer_id)
	return nil
end

function PartyManagerDummy:channel_to_peer(peer_id)
	return nil
end

function PartyManagerDummy:host_peer()
	return nil
end

function PartyManagerDummy:host_channel()
	return nil
end

function PartyManagerDummy:member(peer_id)
	return nil
end

function PartyManagerDummy:local_member()
	return nil
end

function PartyManagerDummy:engine_lobby_id()
	return nil
end

function PartyManagerDummy:network_event_delegate()
	return nil
end

function PartyManagerDummy:send_rpc_host(rpc_name, ...)
end

function PartyManagerDummy:send_rpc_clients(rpc_name, ...)
end

function PartyManagerDummy:send_rpc_clients_except(rpc_name, except_channel_id, ...)
end

function PartyManagerDummy:register_event_listener(object, event_name, func)
end

function PartyManagerDummy:unregister_event_listener(object, event_name)
end

function PartyManagerDummy:allow_new_members()
	return false, ""
end

function PartyManagerDummy:update(dt, t)
end

function PartyManagerDummy:wanted_mission_selected(backend_mission_id)
	if Managers.multiplayer_session:is_booting_session() then
		_info("Wanted mission rejected, already in process of booting a multiplayer session")
	else
		local initiator_peer = Network.peer_id()

		Managers.multiplayer_session:party_host_join_mission_server(backend_mission_id, initiator_peer)
	end
end

function PartyManagerDummy:set_current_server(host_type, lobby_id, matched_game_session_id)
end

function PartyManagerDummy:follow_party()
	return false
end

function PartyManagerDummy:can_follow_party()
	return false
end

function PartyManagerDummy:mission_matchmaking_started(mission_id)
	if not Managers.ui:view_active("lobby_view") then
		local transition_time = nil
		local close_previous = false
		local close_all = true
		local close_transition_time = nil
		local mission_name = NetworkLookup.missions[mission_id]
		local view_context = {
			preview = true,
			mission_data = {
				circumstance_name = "default",
				mission_name = mission_name
			}
		}

		Managers.ui:open_view("lobby_view", transition_time, close_previous, close_all, close_transition_time, view_context)
	end
end

function PartyManagerDummy:mission_matchmaking_completed()
end

function PartyManagerDummy:mission_matchmaking_aborted()
	if Managers.ui:view_active("lobby_view") then
		Managers.ui:close_view("lobby_view")
	end
end

function PartyManagerDummy:ready_voting_completed()
	if Managers.ui:view_active("lobby_view") then
		Managers.ui:close_view("lobby_view")
	end
end

function PartyManagerDummy:set_presence(presence_name)
	if presence_name == self._presence_name then
		return
	end

	local settings = PresenceSettings[presence_name]
	self._presence_name = presence_name
	self._presence_id = NetworkLookup.presence_names[presence_name]
	local hud_localization = settings.hud_localization
	self._presence_hud_text = Managers.localization:localize(hud_localization)
end

function PartyManagerDummy:presence_name()
	return self._presence_name
end

function PartyManagerDummy:presence_id()
	return self._presence_id
end

function PartyManagerDummy:presence_hud_text()
	return self._presence_hud_text
end

function PartyManagerDummy:are_all_members_in_hub()
	if self._presence_name ~= "hub" then
		return false
	end

	return true
end

implements(PartyManagerDummy, VotingNetworkInterface)

return PartyManagerDummy
