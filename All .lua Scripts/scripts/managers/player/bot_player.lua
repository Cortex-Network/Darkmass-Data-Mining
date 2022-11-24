require("scripts/managers/player/human_player")

local PlayerManager = require("scripts/foundation/managers/player/player_manager")
local BotPlayer = class("BotPlayer", "HumanPlayer")

function BotPlayer:init(unique_id, session_id, channel_id, peer_id, local_player_id, profile, slot, ...)
	BotPlayer.super.init(self, unique_id, session_id, channel_id, peer_id, local_player_id, profile, slot, ...)
end

function BotPlayer:type()
	return "BotPlayer"
end

function BotPlayer:is_human_controlled()
	return false
end

function BotPlayer:name()
	local display_name = self._profile.display_name or self._profile.name

	if display_name then
		return display_name
	end

	return self._debug_name
end

function BotPlayer:character_id()
	return self._local_player_id
end

implements(BotPlayer, PlayerManager.PLAYER_INTERFACE)

return BotPlayer
