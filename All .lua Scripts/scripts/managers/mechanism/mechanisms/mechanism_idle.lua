local MechanismBase = require("scripts/managers/mechanism/mechanisms/mechanism_base")
local MechanismIdle = class("MechanismIdle", "MechanismBase")

function MechanismIdle:init(...)
	MechanismIdle.super.init(self, ...)
end

function MechanismIdle:game_mode_end(outcome)
	ferror("Idle doesn't handle game_mode_end, need to choose new mechanism.")
end

function MechanismIdle:sync_data()
end

function MechanismIdle:wanted_transition()
	return false, false
end

function MechanismIdle:is_allowed_to_reserve_slots(peer_ids)
	return false
end

function MechanismIdle:peers_reserved_slots(peer_ids)
end

function MechanismIdle:peer_freed_slot(peer_id)
end

implements(MechanismIdle, MechanismBase.INTERFACE)

return MechanismIdle
