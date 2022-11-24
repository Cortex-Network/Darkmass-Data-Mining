local ConnectionSingleplayer = class("ConnectionSingleplayer")
local MatchmakingConstants = require("scripts/settings/network/matchmaking_constants")
local ProfileSynchronizerHost = require("scripts/loading/profile_synchronizer_host")
local SingleplayerLobby = require("scripts/multiplayer/connection/singleplayer_lobby")
local HOST_TYPES = MatchmakingConstants.HOST_TYPES

function ConnectionSingleplayer:init(event_delegate, host_type, optional_backend_session_id, optional_backend_mission_data)
	self._event_delegate = event_delegate
	self._host_type = host_type
	self._session_id = optional_backend_session_id
	self._mission_data = optional_backend_mission_data
	self._peer_id = Network.peer_id()
	self._lobby = SingleplayerLobby:new()
	self._profile_synchronizer_host = ProfileSynchronizerHost:new(event_delegate)
	self._session_seed = math.random_seed()

	Log.info("ConnectionSingleplayer", "session_seed created %s", self._session_seed)

	if host_type == HOST_TYPES.singleplay_backend_session then
		Managers.event:register(self, "event_mission_server_initialized", "event_mission_server_initialized")
	end
end

function ConnectionSingleplayer:destroy()
	Managers.event:unregister(self, "event_mission_server_initialized")
end

function ConnectionSingleplayer:event_mission_server_initialized()
	Managers.event:unregister(self, "event_mission_server_initialized")
	Managers.mission_server:allocate_session(self._session_id, self._mission_data)
	Managers.mechanism:trigger_event("all_players_ready")
end

function ConnectionSingleplayer:register_profile_synchronizer()
	local profile_synchronizer_host = self._profile_synchronizer_host

	Managers.profile_synchronization:set_profile_synchroniser_host(profile_synchronizer_host)
end

function ConnectionSingleplayer:unregister_profile_synchronizer()
	if Managers.profile_synchronization then
		Managers.profile_synchronization:set_profile_synchroniser_host(nil)
	end
end

function ConnectionSingleplayer:allocation_state()
	return 1
end

function ConnectionSingleplayer:disconnect(channel_id)
end

function ConnectionSingleplayer:kick(channel_id, reason, option_details)
end

function ConnectionSingleplayer:host()
	return self._peer_id
end

function ConnectionSingleplayer:engine_lobby()
	return self._lobby
end

function ConnectionSingleplayer:engine_lobby_id()
	return self._lobby:id()
end

function ConnectionSingleplayer:host_is_dedicated_server()
	return false
end

function ConnectionSingleplayer:host_type()
	return self._host_type
end

function ConnectionSingleplayer:max_members()
	return 1
end

function ConnectionSingleplayer:remove(channel_id)
end

function ConnectionSingleplayer:connecting_peers()
	return {}
end

function ConnectionSingleplayer:update(dt)
end

function ConnectionSingleplayer:next_event()
end

function ConnectionSingleplayer:server_name()
	return "Singleplayer"
end

function ConnectionSingleplayer:session_seed()
	return self._session_seed
end

function ConnectionSingleplayer:session_id()
	return self._session_id
end

return ConnectionSingleplayer
