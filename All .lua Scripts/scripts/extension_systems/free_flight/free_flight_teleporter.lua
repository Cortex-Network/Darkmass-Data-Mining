local PlayerMovement = require("scripts/utilities/player_movement")
local FreeFlightTeleporter = class("FreeFlightTeleporter")
local SERVER_RPCS = {
	"rpc_debug_free_flight_teleport_client"
}

function FreeFlightTeleporter:init(is_server)
	self._is_server = is_server
	self._network_event_delegate = Managers.connection:network_event_delegate()

	if is_server then
		self._network_event_delegate:register_connection_events(self, unpack(SERVER_RPCS))
	end
end

function FreeFlightTeleporter:destroy()
	if self._is_server then
		self._network_event_delegate:unregister_events(unpack(SERVER_RPCS))
	end
end

function FreeFlightTeleporter:teleport_player_to_camera_position(position, rotation)
	local player = Managers.player:local_player(1)

	if self._is_server then
		self:_teleport_player(player, position, rotation)
	else
		local pitch = Quaternion.pitch(rotation)
		local yaw = Quaternion.yaw(rotation)

		player:set_orientation(yaw, pitch, 0)

		local player_id = player:local_player_id()
		local peer_id = player:peer_id()
		local channel = Managers.connection:host_channel()

		RPC.rpc_debug_free_flight_teleport_client(channel, player_id, peer_id, position)
	end
end

function FreeFlightTeleporter:_teleport_player(player, position, rotation)
	PlayerMovement.teleport(player, position, rotation)
end

function FreeFlightTeleporter:rpc_debug_free_flight_teleport_client(channel_id, player_id, peer_id, position)
	local player = Managers.player:player(peer_id, player_id)

	self:_teleport_player(player, position, nil)
end

return FreeFlightTeleporter
