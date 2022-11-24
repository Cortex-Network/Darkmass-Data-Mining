local PointOfInterestSettings = require("scripts/settings/point_of_interest/point_of_interest_settings")
local PointOfInterestTargetExtension = class("PointOfInterestTargetExtension")

function PointOfInterestTargetExtension:init(extension_init_context, unit, extension_init_data, ...)
	local tag = extension_init_data.tag or ""
	local view_distance = extension_init_data.view_distance or PointOfInterestSettings.default_view_distance
	local is_dynamic = extension_init_data.is_dynamic or false
	self._unit = unit
	self._is_server = extension_init_context.is_server
	self._view_distance_sq = view_distance
	self._is_dynamic = is_dynamic
	self._tag = tag
	self._faction_event = nil
	self._faction_breed_name = ""
	self._unit_node = nil
	self._has_been_seen = false
	self._collision_filter = "filter_look_at_object_ray"
	self._disabled = false

	if Unit.has_node(unit, "j_spine") then
		Unit.node(unit, "j_spine")
	end
end

function PointOfInterestTargetExtension:setup_from_component(view_distance, is_dynamic, tag, faction_event, dialogue_target_filter, faction_breed_name, mission_giver_selected_voice, disabled)
	self._view_distance_sq = view_distance * view_distance
	self._is_dynamic = is_dynamic
	self._tag = tag

	if faction_event ~= "" then
		self._faction_event = faction_event
	end

	self._faction_breed_name = faction_breed_name
	self._dialogue_target_filter = dialogue_target_filter or "none"
	self._mission_giver_selected_voice = mission_giver_selected_voice
	self._disabled = disabled
end

function PointOfInterestTargetExtension:is_dynamic()
	return self._is_dynamic
end

function PointOfInterestTargetExtension:center_position()
	local target_center = nil
	local node = self._unit_node
	local unit = self._unit

	if node then
		target_center = Unit.world_position(unit, node)
	else
		local target_center_matrix = Unit.box(unit)
		target_center = Matrix4x4.translation(target_center_matrix)
	end

	return target_center
end

function PointOfInterestTargetExtension:view_distance_sq()
	return self._view_distance_sq
end

function PointOfInterestTargetExtension:tag()
	return self._tag
end

function PointOfInterestTargetExtension:faction_event()
	return self._faction_event
end

function PointOfInterestTargetExtension:faction_breed_name()
	return self._faction_breed_name
end

function PointOfInterestTargetExtension:dialogue_target_filter()
	return self._dialogue_target_filter
end

function PointOfInterestTargetExtension:mission_giver_selected_voice()
	return self._mission_giver_selected_voice
end

function PointOfInterestTargetExtension:set_has_been_seen()
	self._has_been_seen = true
end

function PointOfInterestTargetExtension:set_tag(tag)
	self._tag = tag
end

function PointOfInterestTargetExtension:set_disabled()
	self._disabled = true
end

function PointOfInterestTargetExtension:disabled()
	return self._disabled
end

function PointOfInterestTargetExtension:collision_filter()
	return self._collision_filter
end

return PointOfInterestTargetExtension
