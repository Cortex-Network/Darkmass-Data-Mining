local AuthoritativePlayerInputHandler = require("scripts/managers/player/player_game_states/authoritative_player_input_handler")
local PlayerManager = require("scripts/foundation/managers/player/player_manager")
local RemotePlayer = class("RemotePlayer")

function RemotePlayer:init(unique_id, session_id, channel_id, peer_id, local_player_id, profile, slot, account_id, human_controlled, is_server, telemetry_game_session)
	self.player_unit = nil
	self.owned_units = {}
	self.is_server = is_server
	self.remote = true
	self._telemetry_game_session = telemetry_game_session
	self._unique_id = unique_id
	self._session_id = session_id
	self._connection_channel_id = channel_id
	self._session_channel_id = nil
	self._peer_id = peer_id
	self._local_player_id = local_player_id
	self._account_id = account_id
	self._slot = slot

	if human_controlled then
		self._debug_name = "Remote #" .. peer_id:sub(-3, -1)
	else
		self._debug_name = string.format("Bot Player %d", local_player_id)
	end

	self._cached_name = nil
	self._human_controlled = human_controlled
	self._game_state_object = nil

	self:set_profile(profile)
end

function RemotePlayer:type()
	return "RemotePlayer"
end

function RemotePlayer:set_slot(slot)
	self._slot = slot
end

function RemotePlayer:slot()
	return self._slot
end

function RemotePlayer:set_session_channel_id(channel_id)
	self._session_channel_id = channel_id
end

function RemotePlayer:connection_channel_id()
	return self._connection_channel_id
end

function RemotePlayer:channel_id()
	return self._session_channel_id
end

function RemotePlayer:session_id()
	return self._session_id
end

function RemotePlayer:unique_id()
	return self._unique_id
end

function RemotePlayer:peer_id()
	return self._peer_id
end

function RemotePlayer:local_player_id()
	return self._local_player_id
end

function RemotePlayer:account_id()
	return self._account_id
end

function RemotePlayer:character_id()
	return self._profile.character_id
end

function RemotePlayer:character_name()
	return self._profile.name
end

function RemotePlayer:is_human_controlled()
	return self._human_controlled
end

function RemotePlayer:name()
	if self._profile and self._profile.name then
		return self._profile.name
	elseif HAS_STEAM and self._human_controlled then
		local cached_name = self._cached_name

		if cached_name then
			return cached_name
		end

		cached_name = Steam.user_name(self._peer_id)
		self._cached_name = cached_name

		return cached_name
	else
		return self._debug_name
	end
end

function RemotePlayer:destroy()
	local player_unit_spawn_manager = Managers.state.player_unit_spawn

	if self.is_server and player_unit_spawn_manager then
		player_unit_spawn_manager:despawn(self)
	end
end

function RemotePlayer:lag_compensation_rewind_ms()
	local input_handler = self.input_handler

	if input_handler then
		return input_handler:rewind_ms()
	else
		return 0
	end
end

local MILLISECONDS_TO_SECONDS = 0.001

function RemotePlayer:lag_compensation_rewind_s()
	local ms = self:lag_compensation_rewind_ms()

	return ms and ms * MILLISECONDS_TO_SECONDS or nil
end

function RemotePlayer:create_input_handler()
	if self.is_server then
		self.input_handler = AuthoritativePlayerInputHandler:new(self, self.is_server)

		self.input_handler:create_clock()
	end
end

function RemotePlayer:destroy_input_handler()
	if self.is_server then
		self.input_handler:delete()

		self.input_handler = nil
	end
end

function RemotePlayer:set_profile(profile)
	self._profile = profile
	self._telemetry_subject = {
		account_id = self._account_id,
		character_id = profile.character_id
	}
end

function RemotePlayer:profile()
	return self._profile
end

function RemotePlayer:archetype_name()
	return self._profile.archetype.name
end

function RemotePlayer:breed_name()
	return self._profile.archetype.breed
end

function RemotePlayer:telemetry_game_session()
	return self._telemetry_game_session
end

function RemotePlayer:telemetry_subject()
	return self._telemetry_subject
end

function RemotePlayer:unit_is_alive()
	local player_unit = self.player_unit

	return player_unit and Unit.alive(player_unit)
end

implements(RemotePlayer, PlayerManager.PLAYER_INTERFACE)

return RemotePlayer
