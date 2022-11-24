require("scripts/extension_systems/networked_timer/networked_timer_extension")

local NetworkedTimerSystem = class("NetworkedTimerSystem", "ExtensionSystemBase")
local RPCS = {
	"rpc_networked_timer_sync_state",
	"rpc_networked_timer_start",
	"rpc_networked_timer_pause",
	"rpc_networked_timer_stop",
	"rpc_networked_timer_fast_forward",
	"rpc_networked_timer_rewind",
	"rpc_networked_timer_finished"
}

function NetworkedTimerSystem:init(context, system_init_data, ...)
	NetworkedTimerSystem.super.init(self, context, system_init_data, ...)

	self._network_event_delegate = context.network_event_delegate

	self._network_event_delegate:register_session_events(self, unpack(RPCS))
end

function NetworkedTimerSystem:destroy()
	self._network_event_delegate:unregister_events(unpack(RPCS))
	NetworkedTimerSystem.super.destroy(self)
end

function NetworkedTimerSystem:rpc_networked_timer_sync_state(channel_id, unit_id, active, counting, total_timer, speed_modifier)
	local is_level_unit = true
	local unit = Managers.state.unit_spawner:unit(unit_id, is_level_unit)
	local extension = ScriptUnit.extension(unit, "networked_timer_system")

	extension:sync_state(active, counting, total_timer, speed_modifier)
end

function NetworkedTimerSystem:rpc_networked_timer_start(channel_id, unit_id)
	local is_level_unit = true
	local unit = Managers.state.unit_spawner:unit(unit_id, is_level_unit)
	local extension = ScriptUnit.extension(unit, "networked_timer_system")

	extension:start()
end

function NetworkedTimerSystem:rpc_networked_timer_pause(channel_id, unit_id)
	local is_level_unit = true
	local unit = Managers.state.unit_spawner:unit(unit_id, is_level_unit)
	local extension = ScriptUnit.extension(unit, "networked_timer_system")

	extension:pause()
end

function NetworkedTimerSystem:rpc_networked_timer_stop(channel_id, unit_id)
	local is_level_unit = true
	local unit = Managers.state.unit_spawner:unit(unit_id, is_level_unit)
	local extension = ScriptUnit.extension(unit, "networked_timer_system")

	extension:stop()
end

function NetworkedTimerSystem:rpc_networked_timer_fast_forward(channel_id, unit_id)
	local is_level_unit = true
	local unit = Managers.state.unit_spawner:unit(unit_id, is_level_unit)
	local extension = ScriptUnit.extension(unit, "networked_timer_system")

	extension:fast_forward()
end

function NetworkedTimerSystem:rpc_networked_timer_rewind(channel_id, unit_id)
	local is_level_unit = true
	local unit = Managers.state.unit_spawner:unit(unit_id, is_level_unit)
	local extension = ScriptUnit.extension(unit, "networked_timer_system")

	extension:rewind()
end

function NetworkedTimerSystem:rpc_networked_timer_finished(channel_id, unit_id)
	local is_level_unit = true
	local unit = Managers.state.unit_spawner:unit(unit_id, is_level_unit)
	local extension = ScriptUnit.extension(unit, "networked_timer_system")

	extension:finished()
end

return NetworkedTimerSystem
