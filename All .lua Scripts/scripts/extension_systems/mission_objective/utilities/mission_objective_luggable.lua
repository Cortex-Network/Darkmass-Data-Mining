require("scripts/extension_systems/mission_objective/utilities/mission_objective_base")

local MissionObjectiveLuggable = class("MissionObjectiveLuggable", "MissionObjectiveBase")

function MissionObjectiveLuggable:init()
	MissionObjectiveLuggable.super.init(self)

	self._override_marked_units = nil

	self:set_updated_externally(true)
end

function MissionObjectiveLuggable:start_objective(mission_objective_data, registered_units, synchronizer_unit)
	MissionObjectiveLuggable.super.start_objective(self, mission_objective_data, registered_units, synchronizer_unit)

	local luggable_synchronizer_extension = self:synchronizer_extension()
	local stages = luggable_synchronizer_extension:get_objective_stages()

	self:set_stage_count(stages)
end

function MissionObjectiveLuggable:start_stage(stage)
	MissionObjectiveLuggable.super.start_stage(self, stage)

	local luggable_synchronizer_extension = self:synchronizer_extension()

	self:set_max_increment(luggable_synchronizer_extension:sockets_to_fill())
end

function MissionObjectiveLuggable:update_progression()
	MissionObjectiveLuggable.super.update_progression(self)

	local socket_targets = self:max_incremented_progression()

	if socket_targets > 0 then
		local current_amount = self:incremented_progression()
		local progression = current_amount / socket_targets
		progression = math.clamp(progression, 0, 1)

		self:set_progression(progression)

		if self:max_progression_achieved() then
			self:stage_done()
		end
	end
end

function MissionObjectiveLuggable:luggable_picked_up()
	Unit.flow_event(self._synchronizer_unit, "lua_event_luggable_picked_up")
end

function MissionObjectiveLuggable:display_socket_markers(show_markers)
	if show_markers then
		local luggable_synchronizer_extension = self:synchronizer_extension()
		local socket_units = luggable_synchronizer_extension:active_socket_units()
		self._override_marked_units = {}

		for i = 1, #socket_units do
			local socket_unit = socket_units[i]
			local socket_extension = ScriptUnit.extension(socket_unit, "luggable_socket_system")

			if not socket_extension:is_occupied() then
				self._override_marked_units[socket_units[i]] = true
			end
		end
	else
		self._override_marked_units = nil
	end
end

function MissionObjectiveLuggable:add_marker_on_hot_join(unit)
	if ScriptUnit.has_extension(unit, "luggable_socket_system") then
		return false
	end

	return MissionObjectiveLuggable.super.add_marker_on_hot_join(self, unit)
end

function MissionObjectiveLuggable:marked_units()
	if self._override_marked_units then
		return self._override_marked_units
	end

	return MissionObjectiveLuggable.super.marked_units(self)
end

return MissionObjectiveLuggable
