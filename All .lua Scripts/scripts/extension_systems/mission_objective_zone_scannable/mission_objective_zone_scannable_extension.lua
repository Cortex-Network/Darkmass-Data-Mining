local LevelEventSettings = require("scripts/settings/level_event/level_event_settings")
local MissionObjectiveZoneScannableExtension = class("MissionObjectiveZoneScannableExtension")

function MissionObjectiveZoneScannableExtension:init(extension_init_context, unit, extension_init_data)
	self._unit = unit
	self._is_server = extension_init_context.is_server
	self._is_active = false
	self._world = extension_init_context.world
	local box = Unit.box(unit, false)
	local center_position = Matrix4x4.translation(box)
	self._center_poisition_box = Vector3Box(center_position)
end

function MissionObjectiveZoneScannableExtension:on_gameplay_post_init(level)
	if self._is_server then
		local mission_objective_zone_system = Managers.state.extension:system("mission_objective_zone_system")

		mission_objective_zone_system:register_scannable_unit(self._unit)
	end
end

function MissionObjectiveZoneScannableExtension:hot_join_sync(unit, sender, channel)
	local active = self._is_active
	local level_unit_id = Managers.state.unit_spawner:level_index(self._unit)

	RPC.rpc_mission_objective_zone_scannable_hot_join_sync(channel, level_unit_id, active)
end

function MissionObjectiveZoneScannableExtension:set_active(active)
	self._is_active = active

	if self._is_server then
		local level_unit_id = Managers.state.unit_spawner:level_index(self._unit)

		Managers.state.game_session:send_rpc_clients("rpc_mission_objective_zone_scannable_set_active", level_unit_id, active)
	end
end

function MissionObjectiveZoneScannableExtension:set_scanning_highlight(active)
	local has_outline_system = Managers.state.extension:has_system("outline_system")

	if has_outline_system then
		local outline_system = Managers.state.extension:system("outline_system")

		if active then
			outline_system:add_outline(self._unit, "scanning_confirm")
		else
			outline_system:remove_outline(self._unit, "scanning_confirm")
		end
	end
end

function MissionObjectiveZoneScannableExtension:set_scanning_outline(active)
	local has_outline_system = Managers.state.extension:has_system("outline_system")

	if has_outline_system then
		local outline_system = Managers.state.extension:system("outline_system")

		if active then
			outline_system:add_outline(self._unit, "scanning")
		else
			outline_system:remove_outline(self._unit, "scanning")
		end
	end
end

function MissionObjectiveZoneScannableExtension:is_active()
	return self._is_active
end

function MissionObjectiveZoneScannableExtension:center_poisition()
	local center_poisition_box = self._center_poisition_box

	return center_poisition_box and center_poisition_box:unbox()
end

return MissionObjectiveZoneScannableExtension
