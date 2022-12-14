local TrainingGroundsDirectionalUnitExtension = class("TrainingGroundsDirectionalUnitExtension")
TrainingGroundsDirectionalUnitExtension.UPDATE_DISABLED_BY_DEFAULT = true

function TrainingGroundsDirectionalUnitExtension:init(extension_init_context, unit, extension_init_data, ...)
	self._unit = unit
	self._spawn_group = Unit.get_data(unit, "attached_unit.spawn_group")
	self._identifier = Unit.get_data(unit, "directional_unit_identifier")
	local attached_unit = Unit.flow_variable(self._unit, "attached_unit")
	self._attached_unit = Unit.alive(attached_unit) and attached_unit or nil
end

function TrainingGroundsDirectionalUnitExtension:unit()
	return self._unit
end

function TrainingGroundsDirectionalUnitExtension:spawn_attached_unit()
	Unit.flow_event(self._unit, "spawn_attached_unit")

	self._attached_unit = Unit.flow_variable(self._unit, "attached_unit")

	return self._attached_unit
end

function TrainingGroundsDirectionalUnitExtension:unspawn_attached_unit()
	Unit.flow_event(self._unit, "unspawn_attached_unit")

	self._attached_unit = nil
end

function TrainingGroundsDirectionalUnitExtension:attached_unit()
	return self._attached_unit
end

function TrainingGroundsDirectionalUnitExtension:spawn_group()
	return self._spawn_group
end

function TrainingGroundsDirectionalUnitExtension:identifier()
	return self._identifier
end

function TrainingGroundsDirectionalUnitExtension:update(unit, dt, t)
end

function TrainingGroundsDirectionalUnitExtension:destroy()
	self._unit = nil
end

return TrainingGroundsDirectionalUnitExtension
