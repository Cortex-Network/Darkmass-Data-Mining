local ConnectionSingleplayer = require("scripts/multiplayer/connection/connection_singleplayer")
local MatchmakingConstants = require("scripts/settings/network/matchmaking_constants")
local SessionBootBase = require("scripts/multiplayer/session_boot_base")
local HOST_TYPES = MatchmakingConstants.HOST_TYPES
local STATES = table.enum("waiting_for_view", "creating_backend_session", "ready", "failed")
local SingleplayerBackendSessionBoot = class("SingleplayerBackendSessionBoot", "SessionBootBase")
SingleplayerBackendSessionBoot.SINGLEPLAYER_BACKEND_SESSION = true

function SingleplayerBackendSessionBoot:init(event_object, backend_mission_data, optional_starting_view_name)
	SingleplayerBackendSessionBoot.super.init(self, STATES, event_object)

	self._backend_mission_data = backend_mission_data

	if optional_starting_view_name and Managers.ui:is_view_closing(optional_starting_view_name) then
		self._starting_view_name = optional_starting_view_name

		self:_set_state(STATES.waiting_for_view)
	else
		self:_create_backend_session(backend_mission_data)
	end
end

function SingleplayerBackendSessionBoot:_create_backend_session()
	self:_set_state(STATES.creating_backend_session)

	local backend_mission_data = self._backend_mission_data
	local mission_id = backend_mission_data.id

	Managers.party_immaterium:create_single_player_game(mission_id):next(function (response)
		local session_id = response.game_session_id

		Log.info("SingleplayerBackendSessionBoot", "Created backend session %s", session_id)

		local event_delegate = Managers.connection:network_event_delegate()
		self._connection_singleplayer = ConnectionSingleplayer:new(event_delegate, HOST_TYPES.singleplay_backend_session, session_id, backend_mission_data)

		self:_set_state(STATES.ready)
	end):catch(function (error)
		local is_error = true

		self._event_object:failed_to_boot(is_error, "game", "FAILED_CREATING_BACKEND_SESSION", error)
		self:_set_state(STATES.failed)
	end)
end

function SingleplayerBackendSessionBoot:update(dt)
	SingleplayerBackendSessionBoot.super.update(self, dt)

	if self._state == STATES.waiting_for_view and not Managers.ui:is_view_closing(self._starting_view_name) then
		self:_create_backend_session()
	end
end

function SingleplayerBackendSessionBoot:result()
	self:_set_window_title("singleplayer %s", Network.peer_id())

	local connection_singleplayer = self._connection_singleplayer
	self._connection_singleplayer = nil

	return connection_singleplayer
end

function SingleplayerBackendSessionBoot:destroy()
	if self._connection_singleplayer then
		self._connection_singleplayer:delete()

		self._connection_singleplayer = nil
	end
end

implements(SingleplayerBackendSessionBoot, SessionBootBase.INTERFACE)

return SingleplayerBackendSessionBoot
