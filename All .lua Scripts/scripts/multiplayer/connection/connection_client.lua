local RPCS = {
	"rpc_player_connected",
	"rpc_player_disconnected",
	"rpc_sync_host_local_players",
	"rpc_kicked"
}
local ConnectionLocalStateMachine = require("scripts/multiplayer/connection/connection_local_state_machine")
local JWTTicketUtils = require("scripts/multiplayer/utilities/jwt_ticket_utils")
local ProfileSynchronizerClient = require("scripts/loading/profile_synchronizer_client")
local EACError = require("scripts/managers/error/errors/eac_error")
local ConnectionClient = class("ConnectionClient")

function ConnectionClient:init(event_delegate, engine_lobby, destroy_lobby_function, network_hash, host_type, optional_reservations, jwt_ticket, optional_matched_game_session_id, optional_accelerated_endpoint)
	self._event_delegate = event_delegate
	self._engine_lobby = engine_lobby
	self._destroy_lobby_function = destroy_lobby_function
	self._host_type = host_type
	self._matched_game_session_id = optional_matched_game_session_id
	self._accelerated_endpoint = optional_accelerated_endpoint
	local profile_synchronizer_client = ProfileSynchronizerClient:new(event_delegate)
	self._profile_synchronizer_client = profile_synchronizer_client
	self._region = nil
	self._deployment_id = nil
	self._unique_instance_id = nil

	if jwt_ticket then
		local jwt_header, jwt_payload = JWTTicketUtils.decode_jwt_ticket(jwt_ticket)
		local instance_id_split = string.double_dash_split(jwt_payload.instanceId)

		if #instance_id_split == 5 then
			self._region = instance_id_split[2]
			self._deployment_id = instance_id_split[3]
			self._unique_instance_id = instance_id_split[4] .. "--" .. instance_id_split[5]
		end

		local instance_id = jwt_payload.instanceId
		local session_id = jwt_payload.sessionId
		local mission_data = jwt_payload.sessionSettings.missionJson
		local mission_id = mission_data and mission_data.id

		Crashify.print_property("instance_id", instance_id)
		Crashify.print_property("session_id", session_id)

		if mission_id then
			Crashify.print_property("mission_id", mission_id)
		end

		self._session_id = session_id
	end

	self._host_peer_id = engine_lobby:lobby_host()
	self._host_connection = ConnectionLocalStateMachine:new(event_delegate, engine_lobby, self._host_peer_id, network_hash, host_type, profile_synchronizer_client, optional_reservations, jwt_ticket)
	self._host_channel_id = self._host_connection:channel_id()
	self._observers = {}
	self._observer_connections = {}
	self._events = {}

	self._event_delegate:register_connection_channel_events(self, self._host_channel_id, unpack(RPCS))
end

function ConnectionClient:destroy()
	self._observers = nil

	for _, connection in pairs(self._observer_connections) do
		connection:delete()
	end

	self._observer_connections = nil

	self._host_connection:delete()

	self._host_connection = nil

	self._destroy_lobby_function(self._engine_lobby)

	self._destroy_lobby_function = nil
	self._engine_lobby = nil

	self._profile_synchronizer_client:delete()
	self._event_delegate:unregister_channel_events(self._host_channel_id, unpack(RPCS))
end

function ConnectionClient:register_profile_synchronizer()
	local profile_synchronizer_client = self._profile_synchronizer_client

	Managers.profile_synchronization:set_profile_synchroniser_client(profile_synchronizer_client)
end

function ConnectionClient:unregister_profile_synchronizer()
	if Managers.profile_synchronization then
		Managers.profile_synchronization:set_profile_synchroniser_client(nil)
	end
end

function ConnectionClient:host()
	return self._host_peer_id
end

function ConnectionClient:unique_instance_id()
	return self._unique_instance_id
end

function ConnectionClient:region()
	return self._region
end

function ConnectionClient:deployment_id()
	return self._deployment_id
end

function ConnectionClient:session_id()
	return self._session_id
end

function ConnectionClient:accelerated_endpoint()
	return self._accelerated_endpoint
end

function ConnectionClient:host_is_dedicated_server()
	return self._host_connection:host_is_dedicated_server()
end

function ConnectionClient:host_type()
	return self._host_type
end

function ConnectionClient:max_members()
	return self._host_connection:max_members()
end

function ConnectionClient:host_channel()
	return self._host_channel_id
end

function ConnectionClient:engine_lobby()
	return self._engine_lobby
end

function ConnectionClient:engine_lobby_id()
	return self._engine_lobby:id()
end

function ConnectionClient:matched_game_session_id()
	return self._matched_game_session_id
end

function ConnectionClient:has_disconnected()
	return self._host_connection:has_disconnected()
end

function ConnectionClient:has_reserved()
	return self._host_connection:has_reserved()
end

function ConnectionClient:ready_to_join()
	self._host_connection:ready_to_join()
end

function ConnectionClient:boot_complete()
	self._host_connection:boot_complete()
end

function ConnectionClient:disconnect(channel_id)
	self._engine_lobby:close_channel(channel_id)
end

function ConnectionClient:remove(channel_id)
	local connection = self._observer_connections[channel_id]

	if connection then
		connection:delete()

		self._observer_connections[channel_id] = nil
	end
end

function ConnectionClient:server_name()
	local engine_lobby = self._engine_lobby
	local server_name = nil

	if engine_lobby.server_name then
		server_name = engine_lobby:server_name()
	else
		server_name = engine_lobby:data("server_name")
	end

	return server_name
end

function ConnectionClient:session_seed()
	local host_connection = self._host_connection
	local session_seed = host_connection:session_seed()

	return session_seed
end

function ConnectionClient:update(dt)
	self._host_connection:update(dt)
end

function ConnectionClient:next_event()
	if not table.is_empty(self._events) then
		local event = self._events[1]

		table.remove(self._events, 1)

		if type(event) == "function" then
			event = event()
		end

		return event.name, event.parameters
	end

	local event, parameters = self._host_connection:next_event()

	if event then
		return event, parameters
	end

	for _, connection in pairs(self._observer_connections) do
		event, parameters = connection:next_event()

		if event then
			return event, parameters
		end
	end
end

function ConnectionClient:rpc_player_connected(channel_id, peer_id, local_player_id_array, is_human_controlled_array, account_id_array, player_session_id_array, slot_array)
	local observers = self._observers
	local profile_chunks_array = self._profile_synchronizer_client:peer_profile_chunks_array(peer_id, local_player_id_array)

	self._events[#self._events + 1] = function ()
		observers[#observers + 1] = {
			peer_id = peer_id
		}

		return {
			name = "player_connected",
			parameters = {
				peer_id = peer_id,
				player_sync_data = {
					local_player_id_array = local_player_id_array,
					is_human_controlled_array = is_human_controlled_array,
					account_id_array = account_id_array,
					profile_chunks_array = profile_chunks_array,
					player_session_id_array = player_session_id_array,
					slot_array = slot_array
				}
			}
		}
	end
end

function ConnectionClient:rpc_player_disconnected(channel_id, peer_id)
	local observers = self._observers

	self._events[#self._events + 1] = function ()
		for i, observer in ipairs(observers) do
			if observer.peer_id == peer_id then
				table.remove(observers, i)

				break
			end
		end

		return {
			name = "player_disconnected",
			parameters = {
				peer_id = peer_id
			}
		}
	end
end

function ConnectionClient:rpc_sync_host_local_players(channel_id, local_player_id_array, is_human_controlled_array, account_id_array, player_session_id_array, slot_array)
	local peer_id = Network.peer_id(channel_id)
	local is_server = false
	local RemotePlayer = require("scripts/managers/player/remote_player")
	local profile_chunks_array = self._profile_synchronizer_client:peer_profile_chunks_array(peer_id, local_player_id_array)

	Managers.player:create_players_from_sync_data(RemotePlayer, channel_id, peer_id, is_server, local_player_id_array, is_human_controlled_array, account_id_array, profile_chunks_array, player_session_id_array, slot_array)

	local package_synchronizer_client = Managers.package_synchronization:synchronizer_client()

	package_synchronizer_client:add_peer(peer_id)
end

function ConnectionClient:rpc_kicked(channel_id, reason, optional_details)
	self._host_connection:disconnect(reason, optional_details)

	if reason == "EAC_KICK" then
		Managers.error:report_error(EACError:new("loc_popup_description_eac_kick", optional_info))
	end
end

return ConnectionClient
