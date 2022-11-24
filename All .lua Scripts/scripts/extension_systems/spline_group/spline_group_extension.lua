local SplineGroupExtension = class("SplineGroupExtension")

function SplineGroupExtension:init(extension_init_context, unit)
	self._unit = unit
end

function SplineGroupExtension:setup_from_component(objective_name, spline_names)
	local mission_objective_system = Managers.state.extension:system("mission_objective_system")
	local mission_exists = mission_objective_system:objective_definition(objective_name)
	self._objective_name = objective_name
	self._spline_names = spline_names
end

function SplineGroupExtension:objective_name()
	return self._objective_name
end

function SplineGroupExtension:splines()
	return self._spline_names
end

return SplineGroupExtension
