local HudElementMissionObjective = class("HudElementMissionObjective")

function HudElementMissionObjective:init(objective)
	self._objective_name = objective:name()
	self._state = "default"
	self._header = ""
	self._description = ""
	self._progression = 0
	self._stage = 0
	self._use_counter = true
	self._current_counter_amount = 0
	self._max_counter_amount = 0
	self._icon = nil
	self._progress_bar = false
	self._marked_units = {}
	self._marker_ids = {}
	self._distance = 0
	self._marker_distances = {}
	self._is_side_mission = objective:is_side_mission()
	self._locally_added = objective:locally_added()
	local game_mode_name = Managers.state.game_mode:game_mode_name()
	local is_in_hub = game_mode_name == "hub" or game_mode_name == "prologue_hub"
	self._default_marker_type = is_in_hub and "hub_objective" or "objective"

	self:synchronize_objective(objective)
	self:_init_markers()
end

function HudElementMissionObjective:destroy()
	self:_destroy_markers()
end

function HudElementMissionObjective:is_synchronized_with_objective(objective)
	if self._stage ~= objective:stage() then
		return false
	end

	if self._progression ~= objective:progression() or self._has_second_progression and self._second_progression ~= objective:second_progression() then
		return false
	end

	if self._max_counter_amount ~= objective:max_incremented_progression() then
		return false
	end

	if self._current_counter_amount ~= objective:incremented_progression() then
		return false
	end

	if self._state ~= objective:ui_state() then
		return false
	end

	if self._use_counter ~= objective:use_counter() then
		return false
	end

	if self._description ~= objective:description() then
		return false
	end

	if self._header ~= objective:header() then
		return false
	end

	if self._marked_units ~= objective:marked_units() then
		return false
	end

	if self._marker_type ~= objective:marker_type() then
		return false
	end

	return true
end

function HudElementMissionObjective:synchronize_objective(objective)
	self._header = objective:header()
	self._description = objective:description()
	self._stage = objective:stage()
	self._progression = objective:progression()
	self._state = objective:ui_state()
	self._has_second_progression = objective:has_second_progression()
	self._second_progression = objective:second_progression()
	self._current_counter_amount = objective:incremented_progression()
	self._max_counter_amount = objective:max_incremented_progression()
	self._icon = objective:icon()
	self._use_counter = objective:use_counter()
	self._progress_bar = objective:progress_bar()
	self._marked_units = objective:marked_units()
	self._marker_type = objective:marker_type()
end

function HudElementMissionObjective:update_markers()
	local marker_ids = self._marker_ids
	local marked_units = self._marked_units

	for unit, _ in pairs(marked_units) do
		if marker_ids[unit] == nil then
			self:_add_unit_marker(unit)
		end
	end

	for marked_unit, _ in pairs(marker_ids) do
		if marked_units[marked_unit] == nil then
			self:_remove_unit_markers(marked_unit)
		end
	end
end

function HudElementMissionObjective:_init_markers()
	local marked_units = self._marked_units

	for unit, _ in pairs(marked_units) do
		self:_add_unit_marker(unit)
	end
end

function HudElementMissionObjective:_destroy_markers()
	local marker_ids = self._marker_ids

	for _, marker_id in pairs(marker_ids) do
		Managers.event:trigger("remove_world_marker", marker_id)
	end

	self._marker_ids = nil
end

function HudElementMissionObjective:_add_unit_marker(unit)
	local marker_callback = callback(self, "_cb_on_marker_spawned", unit)
	local marker_type = self._marker_type or self._default_marker_type
	local extension = ScriptUnit.has_extension(unit, "mission_objective_target_system")
	local ui_target_type = extension and extension:ui_target_type() or "default"
	local data = {
		hud_element = self,
		ui_target_type = ui_target_type,
		extension = extension
	}

	Managers.event:trigger("add_world_marker_unit", marker_type, unit, marker_callback, data)
end

function HudElementMissionObjective:_cb_on_marker_spawned(unit, id)
	local marker_ids = self._marker_ids

	if marker_ids[unit] then
		Log.warning("HudElementMissionObjective", "[_cb_on_marker_spawned] Unit marker already registered. Replacing id(%d) with id(%d)", marker_ids[unit], id)
		self:_remove_unit_markers(unit)
	end

	marker_ids[unit] = id
end

function HudElementMissionObjective:_remove_unit_markers(unit)
	local marker_ids = self._marker_ids

	if marker_ids[unit] then
		local marker_id = marker_ids[unit]

		Managers.event:trigger("remove_world_marker", marker_id)

		marker_ids[unit] = nil
	end
end

function HudElementMissionObjective:objective_name()
	return self._objective_name
end

function HudElementMissionObjective:state()
	return self._state
end

function HudElementMissionObjective:header()
	return self._header
end

function HudElementMissionObjective:description()
	return self._description
end

function HudElementMissionObjective:use_counter()
	return self._use_counter
end

function HudElementMissionObjective:current_counter_amount()
	return self._current_counter_amount
end

function HudElementMissionObjective:max_counter_amount()
	return self._max_counter_amount
end

function HudElementMissionObjective:progress_bar()
	return self._progress_bar
end

function HudElementMissionObjective:progression()
	return self._progression
end

function HudElementMissionObjective:has_second_progression()
	return self._has_second_progression
end

function HudElementMissionObjective:second_progression()
	return self._second_progression
end

function HudElementMissionObjective:icon()
	return self._icon
end

function HudElementMissionObjective:is_side_mission()
	return self._is_side_mission
end

function HudElementMissionObjective:locally_added()
	return self._locally_added
end

return HudElementMissionObjective
