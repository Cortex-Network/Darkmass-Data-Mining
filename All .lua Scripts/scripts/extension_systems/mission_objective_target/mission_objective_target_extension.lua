local MissionObjectiveTargetExtension = class("MissionObjectiveTargetExtension")

function MissionObjectiveTargetExtension:init(extension_init_context, unit, extension_init_data, ...)
	self._is_server = extension_init_context.is_server
	self._unit = unit
	self._objective_name = "default"
	self._ui_target_type = "default"
	self._objective_stage = 1
	self._add_marker_on_registration = false
	self._add_marker_on_objective_start = true
	self._enabled_only_during_mission = false
	self._registered_objective = nil
	self._registered_peer_id = {}
	self._mission_objective_system = Managers.state.extension:system("mission_objective_system")
end

function MissionObjectiveTargetExtension:setup_from_component(objective_name, ui_target_type, objective_stage, register_self, add_marker_on_registration, add_marker_on_objective_start, enabled_only_during_mission)
	self._objective_name = objective_name
	self._ui_target_type = ui_target_type
	self._objective_stage = objective_stage
	self._add_marker_on_registration = add_marker_on_registration
	self._add_marker_on_objective_start = add_marker_on_objective_start
	self._enabled_only_during_mission = enabled_only_during_mission

	if register_self then
		self:_setup()
	end
end

function MissionObjectiveTargetExtension:setup_from_external(objective_name, ui_target_type, objective_stage, add_marker_on_registration, add_marker_on_objective_start, enabled_only_during_mission, sync_to_clients, peer_id)
	self._objective_name = objective_name or self._objective_name
	self._ui_target_type = ui_target_type or self._ui_target_type
	self._objective_stage = objective_stage or self._objective_stage

	if add_marker_on_registration ~= nil then
		self._add_marker_on_registration = add_marker_on_registration
	end

	if add_marker_on_objective_start ~= nil then
		self._add_marker_on_objective_start = add_marker_on_objective_start
	end

	if enabled_only_during_mission ~= nil then
		self._enabled_only_during_mission = enabled_only_during_mission
	end

	self:_setup(peer_id)

	if self._is_server and sync_to_clients then
		local unit = self._unit
		local unit_spawner_manager = Managers.state.unit_spawner
		local unit_is_level_unit, unit_id = unit_spawner_manager:game_object_id_or_level_index(unit)
		local objective_name_id = NetworkLookup.mission_objective_names[objective_name]
		local ui_target_type_id = NetworkLookup.mission_objective_target_ui_types[ui_target_type]

		Managers.state.game_session:send_rpc_clients("rpc_mission_objective_target_setup", unit_id, unit_is_level_unit, objective_name_id, ui_target_type_id, objective_stage, add_marker_on_registration, add_marker_on_objective_start, enabled_only_during_mission)
	end
end

function MissionObjectiveTargetExtension:_setup(peer_id)
	local objective_name = self._objective_name
	local objective_stage = self._objective_stage

	if objective_name ~= "default" and (not self._registered_objective or self._registered_objective == objective_name) then
		if self._registered_peer_id[peer_id or -1] ~= nil then
			Log.warning("MissionObjectiveTargetExtension", "Trying to registering peer %s when it's already registered.", peer_id)

			return
		end

		local unit = self._unit
		self._registered_objective = objective_name
		self._registered_peer_id[peer_id or -1] = true

		self._mission_objective_system:register_objective_unit(objective_name, unit, objective_stage, peer_id)

		if self._is_server and self._add_marker_on_registration then
			self:add_unit_marker(peer_id)
		end

		if self._enabled_only_during_mission then
			self:disable_unit(peer_id)
		end
	end
end

function MissionObjectiveTargetExtension:add_unit_marker(peer_id)
	local objective_name = self._objective_name
	local unit = self._unit

	self._mission_objective_system:add_marker(objective_name, unit, peer_id)
end

function MissionObjectiveTargetExtension:remove_unit_marker(peer_id)
	local objective_name = self._objective_name
	local unit = self._unit

	self._mission_objective_system:remove_marker(objective_name, unit, peer_id)
end

function MissionObjectiveTargetExtension:enable_unit(peer_id)
	local objective_name = self._objective_name
	local unit = self._unit
	local stage = self._objective_stage

	self._mission_objective_system:enable_unit(objective_name, unit, stage, peer_id)
end

function MissionObjectiveTargetExtension:disable_unit(peer_id)
	local objective_name = self._objective_name
	local unit = self._unit
	local stage = self._objective_stage

	self._mission_objective_system:disable_unit(objective_name, unit, stage, peer_id)
end

function MissionObjectiveTargetExtension:set_objective_name(objective_name, sync)
	self._objective_name = objective_name

	if self._is_server and sync then
		local unit = self._unit
		local unit_spawner_manager = Managers.state.unit_spawner
		local unit_is_level_unit, unit_id = unit_spawner_manager:game_object_id_or_level_index(unit)
		local objective_name_id = NetworkLookup.mission_objective_names[objective_name]

		Managers.state.game_session:send_rpc_clients("rpc_mission_objective_target_set_objective_name", unit_id, unit_is_level_unit, objective_name_id)
	end
end

function MissionObjectiveTargetExtension:objective_name()
	return self._objective_name
end

function MissionObjectiveTargetExtension:set_ui_target_type(ui_target_type)
	self._ui_target_type = ui_target_type
end

function MissionObjectiveTargetExtension:ui_target_type()
	return self._ui_target_type
end

function MissionObjectiveTargetExtension:objective_stage()
	return self._objective_stage
end

function MissionObjectiveTargetExtension:channel_registered(channel_id)
	if self._registered_peer_id[-1] then
		return true
	end

	local peer_id = Managers.state.game_session:channel_to_peer(channel_id)

	if self._registered_peer_id[peer_id] then
		return true
	end
end

function MissionObjectiveTargetExtension:should_add_marker_on_registration()
	return self._add_marker_on_registration
end

function MissionObjectiveTargetExtension:set_add_marker_on_objective_start(state)
	self._add_marker_on_objective_start = state
end

function MissionObjectiveTargetExtension:should_add_marker_on_objective_start()
	return self._add_marker_on_objective_start
end

function MissionObjectiveTargetExtension:enabled_only_during_mission()
	return self._enabled_only_during_mission
end

return MissionObjectiveTargetExtension
