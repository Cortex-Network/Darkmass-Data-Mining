local PointOfInterestObserverExtension = class("PointOfInterestObserverExtension")

function PointOfInterestObserverExtension:init(extension_init_context, unit, extension_init_data, ...)
	local view_angle = extension_init_data.view_angle or math.pi / 2
	self._view_half_angle = view_angle * 0.5
	self._last_lookat_trigger = -math.huge
	self._first_person_component = nil
end

function PointOfInterestObserverExtension:extensions_ready(world, unit)
	local unit_data_extension = ScriptUnit.extension(unit, "unit_data_system")
	self._first_person_component = unit_data_extension:read_component("first_person")
end

function PointOfInterestObserverExtension:last_lookat_trigger()
	return self._last_lookat_trigger
end

function PointOfInterestObserverExtension:set_last_lookat_trigger(t)
	self._last_lookat_trigger = t
end

function PointOfInterestObserverExtension:first_person_position_rotation()
	local first_person_component = self._first_person_component
	local observer_position = first_person_component.position
	local observer_rotation = first_person_component.rotation

	return observer_position, observer_rotation
end

function PointOfInterestObserverExtension:view_half_angle()
	return self._view_half_angle
end

return PointOfInterestObserverExtension
