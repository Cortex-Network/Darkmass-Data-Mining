require("scripts/extension_systems/event_synchronizer/event_synchronizer_base_extension")
require("scripts/extension_systems/event_synchronizer/decoder_synchronizer_extension")
require("scripts/extension_systems/event_synchronizer/demolition_synchronizer_extension")
require("scripts/extension_systems/event_synchronizer/kill_synchronizer_extension")
require("scripts/extension_systems/event_synchronizer/luggable_synchronizer_extension")
require("scripts/extension_systems/event_synchronizer/mission_objective_zone_synchronizer_extension")
require("scripts/extension_systems/event_synchronizer/side_mission_pickup_synchronizer_extension")

local EventSynchronizerSystem = class("EventSynchronizerSystem", "ExtensionSystemBase")
local RPCS = {
	"rpc_event_synchronizer_started",
	"rpc_event_synchronizer_paused",
	"rpc_event_synchronizer_finished",
	"rpc_event_synchronizer_spline_travel_finished",
	"rpc_event_synchronizer_scanning_finished",
	"rpc_event_synchronizer_mission_objective_zone_follow_spline",
	"rpc_event_synchronizer_mission_objective_zone_at_end_of_spline",
	"rpc_event_synchronizer_distribute_seeds",
	"rpc_event_synchronizer_luggable_hide_luggable",
	"rpc_event_synchronizer_demolition_target_override"
}

function EventSynchronizerSystem:init(context, system_init_data, ...)
	EventSynchronizerSystem.super.init(self, context, system_init_data, ...)

	self._network_event_delegate = context.network_event_delegate

	self._network_event_delegate:register_session_events(self, unpack(RPCS))

	self._mission_objective_zone_synchronizers = {}
end

function EventSynchronizerSystem:on_gameplay_post_init(level)
	local unit_to_extension_map = self._unit_to_extension_map

	for unit, extension in pairs(unit_to_extension_map) do
		if extension.on_gameplay_post_init then
			extension:on_gameplay_post_init(level)
		end
	end
end

function EventSynchronizerSystem:destroy()
	self._network_event_delegate:unregister_events(unpack(RPCS))
	EventSynchronizerSystem.super.destroy(self)
end

function EventSynchronizerSystem:hot_join_sync(sender, channel)
	local unit_to_extension_map = self._unit_to_extension_map

	for unit, extension in pairs(unit_to_extension_map) do
		if extension.seeds then
			local setup_seed, seed = extension:seeds()
			local level_unit_id = Managers.state.unit_spawner:level_index(unit)

			if level_unit_id then
				RPC.rpc_event_synchronizer_distribute_seeds(channel, level_unit_id, setup_seed, seed)
			end
		end

		if extension.hot_join_sync then
			extension:hot_join_sync(sender, channel)
		end
	end
end

function EventSynchronizerSystem:rpc_event_synchronizer_started(channel_id, unit_id)
	local is_level_unit = true
	local unit = Managers.state.unit_spawner:unit(unit_id, is_level_unit)

	self._unit_to_extension_map[unit]:start_event()
end

function EventSynchronizerSystem:rpc_event_synchronizer_paused(channel_id, unit_id)
	local is_level_unit = true
	local unit = Managers.state.unit_spawner:unit(unit_id, is_level_unit)

	self._unit_to_extension_map[unit]:pause_event()
end

function EventSynchronizerSystem:rpc_event_synchronizer_finished(channel_id, unit_id)
	local is_level_unit = true
	local unit = Managers.state.unit_spawner:unit(unit_id, is_level_unit)

	self._unit_to_extension_map[unit]:finished_event()
end

function EventSynchronizerSystem:rpc_event_synchronizer_spline_travel_finished(channel_id, unit_id)
	local is_level_unit = true
	local unit = Managers.state.unit_spawner:unit(unit_id, is_level_unit)

	self._unit_to_extension_map[unit]:spline_travel_finished()
end

function EventSynchronizerSystem:rpc_event_synchronizer_scanning_finished(channel_id, unit_id)
	local is_level_unit = true
	local unit = Managers.state.unit_spawner:unit(unit_id, is_level_unit)

	self._unit_to_extension_map[unit]:scanning_finished()
end

function EventSynchronizerSystem:rpc_event_synchronizer_mission_objective_zone_follow_spline(channel_id, level_unit_id)
	local unit_spawner_manager = Managers.state.unit_spawner
	local is_level_unit = true
	local synchronizer_unit = unit_spawner_manager:unit(level_unit_id, is_level_unit)

	self._unit_to_extension_map[synchronizer_unit]:follow_spline()
end

function EventSynchronizerSystem:rpc_event_synchronizer_mission_objective_zone_at_end_of_spline(channel_id, level_unit_id)
	local unit_spawner_manager = Managers.state.unit_spawner
	local is_level_unit = true
	local synchronizer_unit = unit_spawner_manager:unit(level_unit_id, is_level_unit)

	self._unit_to_extension_map[synchronizer_unit]:at_end_of_spline()
end

function EventSynchronizerSystem:rpc_event_synchronizer_distribute_seeds(channel_id, unit_id, setup_seed, seed)
	local is_level_unit = true
	local unit = Managers.state.unit_spawner:unit(unit_id, is_level_unit)

	self._unit_to_extension_map[unit]:distribute_seeds(setup_seed, seed)
end

function EventSynchronizerSystem:rpc_event_synchronizer_luggable_hide_luggable(channel_id, unit_id, luggable_unit_ids)
	local unit = Managers.state.unit_spawner:unit(unit_id, true)
	local is_luggable_level_unit = false

	for _, luggable_unit_id in ipairs(luggable_unit_ids) do
		local luggable_unit = Managers.state.unit_spawner:unit(luggable_unit_id, is_luggable_level_unit)

		self._unit_to_extension_map[unit]:hide_luggable(luggable_unit)
	end
end

function EventSynchronizerSystem:rpc_event_synchronizer_demolition_target_override(channel_id, unit_id, override)
	local is_level_unit = true
	local unit = Managers.state.unit_spawner:unit(unit_id, is_level_unit)

	self._unit_to_extension_map[unit]:set_override_objective_markers(override)
end

return EventSynchronizerSystem
