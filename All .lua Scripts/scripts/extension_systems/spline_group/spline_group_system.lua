require("scripts/extension_systems/spline_group/spline_group_extension")

local SplineGroupSystem = class("SplineGroupSystem", "ExtensionSystemBase")

function SplineGroupSystem:init(context, system_init_data, ...)
	SplineGroupSystem.super.init(self, context, system_init_data, ...)

	self._splines = {}
end

function SplineGroupSystem:spline_names()
	local splines = self._splines

	table.clear(splines)

	local unit_to_extension_map = self._unit_to_extension_map

	for unit, extension in pairs(unit_to_extension_map) do
		local objective_name = extension:objective_name()
		splines[objective_name] = extension:splines()
	end

	return splines
end

return SplineGroupSystem
