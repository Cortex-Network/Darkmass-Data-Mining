local WwiseGameSyncSettings = require("scripts/settings/wwise_game_sync/wwise_game_sync_settings")
local MissionSoundEvents = require("scripts/settings/sound/mission_sound_events")
local MissionObjectiveBase = class("MissionObjectiveBase")
local last_activation_order = 1
local MUSIC_OBJECTIVE_NONE = WwiseGameSyncSettings.state_groups.music_game_state.none
local OBJECTIVE_EVENT_TYPES = table.enum("None", "mid_event", "end_event")

function MissionObjectiveBase:init()
	self._name = nil
	self._objective_type = nil
	self._peer_id = nil
	self._is_updated_externally = false
	self._order_of_activation = 0
	self._is_side_mission = false
	self._registered_units = {}
	self._objective_units = {}
	self._marked_units = {}
	self._synchronizer_extension = nil
	self._synchronizer_unit = nil
	self._paused = false
	self._stage = 1
	self._stage_count = 1
	self._progression = 0
	self._has_second_progression = false
	self._second_progression = 0
	self._incremented_progression = 0
	self._max_incremented_progression = 0
	self._ui_state = "default"
	self._header = ""
	self._description = ""
	self._override_header = nil
	self._override_description = nil
	self._music_objective = MUSIC_OBJECTIVE_NONE
	self._mission_giver_voice_profile = nil
	self._use_hud = true
	self._use_counter = true
	self._progress_bar = false
	self._icon = nil
	self._marker_type = nil
	self._show_progression_popup_on_update = true
	self._evaluate_at_level_end = false
	self._turn_off_backfill = false
	self._event_type = OBJECTIVE_EVENT_TYPES.None
	self._mission_objective_system = Managers.state.extension:system("mission_objective_system")
end

function MissionObjectiveBase:destroy()
end

function MissionObjectiveBase:start_objective(mission_objective_data, registered_units, synchronizer_unit)
	self._name = mission_objective_data.name
	self._objective_type = mission_objective_data.mission_objective_type
	self._order_of_activation = last_activation_order
	last_activation_order = last_activation_order + 1
	self._header = mission_objective_data.header and Localize(mission_objective_data.header) or ""
	self._description = mission_objective_data.description and Localize(mission_objective_data.description) or ""
	self._music_objective = mission_objective_data.use_music_event or MUSIC_OBJECTIVE_NONE
	self._music_ignore_start_event = mission_objective_data.music_ignore_start_event or false
	self._mission_giver_voice_profile = mission_objective_data.mission_giver_voice_profile
	self._use_hud = not mission_objective_data.hidden or true
	self._progress_bar = mission_objective_data.progress_bar or false
	self._is_side_mission = mission_objective_data.is_side_mission or false
	self._evaluate_at_level_end = mission_objective_data.evaluate_at_level_end or false
	self._event_type = mission_objective_data.event_type or OBJECTIVE_EVENT_TYPES.None
	self._icon = mission_objective_data.icon
	self._marker_type = mission_objective_data.marker_type or self._marker_type
	self._turn_off_backfill = mission_objective_data.turn_off_backfill == true
	self._locally_added = mission_objective_data.locally_added or false
	self._stage = 1
	self._stage_count = 1
	self._incremented_progression = 0
	self._max_incremented_progression = 0
	self._progression = 0
	self._has_second_progression = mission_objective_data.has_second_progression or false
	self._second_progression = 0

	if mission_objective_data.show_progression_popup_on_update == nil then
		self._show_progression_popup_on_update = true
	else
		self._show_progression_popup_on_update = mission_objective_data.show_progression_popup_on_update
	end

	self._registered_units = registered_units
	self._objective_units = {}
	self._marked_units = {}
	self._synchronizer_unit = synchronizer_unit

	if synchronizer_unit then
		local synchronizer_extension = ScriptUnit.extension(synchronizer_unit, "event_synchronizer_system")

		if synchronizer_extension:auto_start() then
			synchronizer_extension:start_event()
		end

		self._synchronizer_extension = synchronizer_extension
	end

	if self._music_objective ~= MUSIC_OBJECTIVE_NONE then
		local event = "objective_start_" .. self._objective_type

		if MissionSoundEvents[event] and not mission_objective_data.music_ignore_start_event then
			self._mission_objective_system:sound_event(MissionSoundEvents[event])
		end
	end
end

function MissionObjectiveBase:start_stage(stage)
	self._stage = stage
	self._incremented_progression = 0
	self._max_incremented_progression = 0
	self._progression = 0
	self._second_progression = 0
	self._objective_units = {}
	local units = self:_get_active_units()
	local synchronizer_extension = self._synchronizer_extension

	if synchronizer_extension then
		synchronizer_extension:start_stage()
	end

	for _, unit in ipairs(units) do
		self:_init_objective_unit(unit)
	end

	self:stage_to_flow()
end

function MissionObjectiveBase:stage_done()
	local synchronizer_extension = self:synchronizer_extension()

	if synchronizer_extension then
		if self._stage < self._stage_count then
			synchronizer_extension:finished_stage()

			self._stage = self._stage + 1
			local mission_objective_system = Managers.state.extension:system("mission_objective_system")

			mission_objective_system:start_mission_objective_stage(self._name, self._stage)
		else
			if self._music_objective ~= MUSIC_OBJECTIVE_NONE then
				self._mission_objective_system:sound_event(MissionSoundEvents.objective_finished)
			end

			synchronizer_extension:finished_event()
		end
	end
end

function MissionObjectiveBase:_get_active_units()
	local registered_units = self._registered_units
	local registered_stage_units = {}

	if registered_units then
		registered_stage_units = registered_units[self._stage]
	end

	local units_sorted_by_id = self:_sort_units_by_id(registered_stage_units)
	local synchronizer_extension = self._synchronizer_extension

	if synchronizer_extension then
		units_sorted_by_id = synchronizer_extension:register_connected_units(units_sorted_by_id, registered_units, self._stage)
		self._synchronizer_extension = synchronizer_extension
	end

	return units_sorted_by_id
end

function MissionObjectiveBase:_sort_units_by_id(units)
	if #units == 0 then
		return units
	end

	local function sort_comp(unit_l, unit_r)
		local _, unit_id_l = Managers.state.unit_spawner:game_object_id_or_level_index(unit_l)
		local _, unit_id_r = Managers.state.unit_spawner:game_object_id_or_level_index(unit_r)

		return unit_id_l < unit_id_r
	end

	table.sort(units, sort_comp)

	return units
end

function MissionObjectiveBase:end_objective()
	local units = self._objective_units
	local ALIVE = ALIVE

	for unit, _ in pairs(units) do
		if ALIVE[unit] then
			self:_deinit_objective_unit(unit)
			Unit.flow_event(unit, "lua_objective_end")
		end
	end

	local synchronizer_unit = self._synchronizer_unit

	if synchronizer_unit and ALIVE[synchronizer_unit] then
		Unit.flow_event(synchronizer_unit, "lua_objective_end")
	end
end

function MissionObjectiveBase:update(dt)
end

function MissionObjectiveBase:update_increment(increment)
	self._incremented_progression = self._incremented_progression + increment
end

function MissionObjectiveBase:update_progression()
end

function MissionObjectiveBase:progression_to_flow()
	local units = self._objective_units
	local ALIVE = ALIVE

	for unit, _ in pairs(units) do
		if ALIVE[unit] then
			Unit.set_flow_variable(unit, "lua_var_objective_progression", self._progression)
			Unit.flow_event(unit, "lua_event_objective_progression")
		end
	end

	local synchronizer_unit = self._synchronizer_unit

	if synchronizer_unit and ALIVE[synchronizer_unit] then
		Unit.set_flow_variable(synchronizer_unit, "lua_var_objective_progression", self._progression)
		Unit.flow_event(synchronizer_unit, "lua_event_objective_progression")
	end
end

function MissionObjectiveBase:stage_to_flow()
	local synchronizer_unit = self._synchronizer_unit

	if synchronizer_unit and ALIVE[synchronizer_unit] then
		Unit.set_flow_variable(synchronizer_unit, "lua_var_objective_stage", self._stage)
		Unit.flow_event(synchronizer_unit, "lua_event_objective_stage")
	end
end

local function _owned_by_death_manager(hit_unit)
	local unit_data_ext = ScriptUnit.has_extension(hit_unit, "unit_data_system")

	if not unit_data_ext then
		return false
	end

	local owned_by_death_manager = unit_data_ext:is_owned_by_death_manager()

	return owned_by_death_manager
end

function MissionObjectiveBase:clear_invalid_units()
	local objective_units = self._objective_units
	local ALIVE = ALIVE

	for unit, _ in pairs(objective_units) do
		local owned_by_death_manager = _owned_by_death_manager(unit)

		if not ALIVE[unit] or owned_by_death_manager then
			objective_units[unit] = nil
		end
	end

	local marked_units = self._marked_units

	for unit, _ in pairs(marked_units) do
		local owned_by_death_manager = _owned_by_death_manager(unit)

		if not ALIVE[unit] or owned_by_death_manager then
			marked_units[unit] = nil
		end
	end
end

function MissionObjectiveBase:_init_objective_unit(unit)
	local mission_objective_target_extension = ScriptUnit.extension(unit, "mission_objective_target_system")

	if mission_objective_target_extension:enabled_only_during_mission() and self._name == mission_objective_target_extension:objective_name() then
		mission_objective_target_extension:enable_unit(self._peer_id)
	end

	if mission_objective_target_extension:should_add_marker_on_objective_start() then
		mission_objective_target_extension:add_unit_marker(self._peer_id)
	end

	self:register_unit(unit)
end

function MissionObjectiveBase:_deinit_objective_unit(unit)
	self:unregister_unit(unit)

	local mission_objective_target_extension = ScriptUnit.has_extension(unit, "mission_objective_target_system")

	if mission_objective_target_extension and mission_objective_target_extension:should_add_marker_on_objective_start() then
		mission_objective_target_extension:remove_unit_marker(self._peer_id)
	end

	if mission_objective_target_extension and mission_objective_target_extension:enabled_only_during_mission() and self._name == mission_objective_target_extension:objective_name() then
		mission_objective_target_extension:disable_unit(self._peer_id)
	end
end

function MissionObjectiveBase:register_unit(unit)
	self._objective_units[unit] = true
end

function MissionObjectiveBase:unregister_unit(unit)
	self._objective_units[unit] = nil
end

function MissionObjectiveBase:unit_registered(unit)
	return self._objective_units[unit] ~= nil
end

function MissionObjectiveBase:add_marker(unit)
	self._marked_units[unit] = true
end

function MissionObjectiveBase:remove_marker(unit)
	self._marked_units[unit] = nil
end

function MissionObjectiveBase:has_marker(unit)
	return self._marked_units[unit] ~= nil
end

function MissionObjectiveBase:add_marker_on_hot_join(unit)
	return self:has_marker(unit)
end

function MissionObjectiveBase:objective_units()
	return self._objective_units
end

function MissionObjectiveBase:marked_units()
	return self._marked_units
end

function MissionObjectiveBase:synchronizer_extension()
	return self._synchronizer_extension
end

function MissionObjectiveBase:synchronizer_unit()
	return self._synchronizer_unit
end

function MissionObjectiveBase:peer_id()
	return self._peer_id
end

function MissionObjectiveBase:set_peer_id(peer_id)
	self._peer_id = peer_id
end

function MissionObjectiveBase:name()
	return self._name
end

function MissionObjectiveBase:objective_type()
	return self._objective_type
end

function MissionObjectiveBase:ui_state()
	return self._ui_state
end

function MissionObjectiveBase:set_ui_state(ui_state)
	return self._ui_state
end

function MissionObjectiveBase:order_of_activation()
	return self._order_of_activation
end

function MissionObjectiveBase:is_paused()
	return self._paused
end

function MissionObjectiveBase:pause()
	self._paused = true
end

function MissionObjectiveBase:resume()
	self._paused = false
end

function MissionObjectiveBase:max_progression_achieved()
	return self._progression == 1 and not self._paused
end

function MissionObjectiveBase:evaluate_at_level_end()
	return self._evaluate_at_level_end
end

function MissionObjectiveBase:is_done()
	return self:max_progression_achieved()
end

function MissionObjectiveBase:event_type()
	return self._event_type
end

function MissionObjectiveBase:set_stage(value)
	self._stage = value
end

function MissionObjectiveBase:stage()
	return self._stage
end

function MissionObjectiveBase:set_stage_count(value)
	self._stage_count = value
end

function MissionObjectiveBase:stage_count()
	return self._stage_count
end

function MissionObjectiveBase:progression()
	return self._progression
end

function MissionObjectiveBase:total_progression()
	return (self:stage() - 1 + self:progression()) / self:stage_count()
end

function MissionObjectiveBase:has_second_progression()
	return self._has_second_progression
end

function MissionObjectiveBase:second_progression()
	return self._second_progression
end

function MissionObjectiveBase:set_increment(amount)
	self._incremented_progression = amount
end

function MissionObjectiveBase:incremented_progression()
	return self._incremented_progression
end

function MissionObjectiveBase:turn_off_backfill()
	return self._turn_off_backfill
end

function MissionObjectiveBase:set_max_increment(max_amount)
	self._max_incremented_progression = max_amount
end

function MissionObjectiveBase:max_incremented_progression()
	return self._max_incremented_progression
end

function MissionObjectiveBase:show_progression_popup_on_update()
	return self._show_progression_popup_on_update
end

function MissionObjectiveBase:music_objective()
	return self._music_objective
end

function MissionObjectiveBase:mission_giver_voice_profile()
	return self._mission_giver_voice_profile
end

function MissionObjectiveBase:set_updated_externally(val)
	self._is_updated_externally = val
end

function MissionObjectiveBase:is_updated_externally()
	return self._is_updated_externally
end

function MissionObjectiveBase:set_progression(progression)
	self._progression = progression
end

function MissionObjectiveBase:set_second_progression(progression)
	self._second_progression = progression
end

function MissionObjectiveBase:use_hud()
	return self._use_hud
end

function MissionObjectiveBase:locally_added()
	return self._locally_added
end

function MissionObjectiveBase:use_counter()
	return self._use_counter and self:max_incremented_progression() > 0
end

function MissionObjectiveBase:use_counter_raw()
	return self._use_counter
end

function MissionObjectiveBase:set_use_counter(use)
	self._use_counter = use
end

function MissionObjectiveBase:progress_bar()
	return self._progress_bar
end

function MissionObjectiveBase:header()
	if self._override_header then
		return self._override_header
	end

	return self._header
end

function MissionObjectiveBase:set_header(header)
	self._override_header = header
end

function MissionObjectiveBase:description()
	if self._override_description then
		return self._override_description
	end

	return self._description
end

function MissionObjectiveBase:set_description(description)
	self._override_description = description
end

function MissionObjectiveBase:icon()
	return self._icon
end

function MissionObjectiveBase:is_side_mission()
	return self._is_side_mission
end

function MissionObjectiveBase:marker_type()
	return self._marker_type
end

function MissionObjectiveBase:set_marker_type(marker_type)
	self._marker_type = marker_type
end

return MissionObjectiveBase
