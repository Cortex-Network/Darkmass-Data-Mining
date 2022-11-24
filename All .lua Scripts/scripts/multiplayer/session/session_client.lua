local SessionLocalStateMachine = require("scripts/multiplayer/session/session_local_state_machine")
local EVENTS = {
	"rpc_peer_joined_session",
	"rpc_peer_left_session"
}
local SessionClient = class("SessionClient")

function SessionClient:init(network_delegate, engine_lobby, engine_gamesession, gameobject_callback_object, clock_handler_client)
	self._network_delegate = network_delegate
	self._engine_gamesession = engine_gamesession
	self._host_session = SessionLocalStateMachine:new(network_delegate, engine_lobby, self._engine_gamesession, gameobject_callback_object, clock_handler_client)
	self._remote_clients = {}
	self._events = {}

	network_delegate:register_session_events(self, unpack(EVENTS))
end

function SessionClient:destroy()
	self._network_delegate:unregister_events(unpack(EVENTS))
	self._host_session:delete()

	self._host_session = nil
	self._remote_clients = nil
end

function SessionClient:update(dt)
	self._host_session:update(dt)
end

function SessionClient:host()
	return self._host_session:host()
end

function SessionClient:host_channel()
	return self._host_session:host_channel()
end

function SessionClient:game_session()
	return self._engine_gamesession
end

function SessionClient:leave()
	self._host_session:leave()
end

function SessionClient:next_event()
	local event_list = self._events

	if not table.is_empty(event_list) then
		local event = event_list[1]

		table.remove(event_list, 1)

		if type(event) == "function" then
			event = event()
		end

		return event.name, event.parameters
	end

	local event, parameters = self._host_session:next_event()

	if event then
		return event, parameters
	end
end

function SessionClient:rpc_peer_joined_session(channel_id, peer_id)
	local remote_clients = self._remote_clients

	self._events[#self._events + 1] = function ()
		remote_clients[peer_id] = {}

		return {
			name = "session_joined",
			parameters = {
				peer_id = peer_id
			}
		}
	end
end

function SessionClient:rpc_peer_left_session(channel_id, peer_id)
	local remote_clients = self._remote_clients

	self._events[#self._events + 1] = function ()
		remote_clients[peer_id] = nil

		return {
			name = "session_left",
			parameters = {
				peer_id = peer_id
			}
		}
	end
end

return SessionClient
