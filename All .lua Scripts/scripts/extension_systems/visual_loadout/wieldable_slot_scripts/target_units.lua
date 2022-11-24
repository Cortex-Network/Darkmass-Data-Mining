local TargetUnits = class("TargetUnits")

function TargetUnits:init(context, slot, weapon_template, fx_sources)
	if DEDICATED_SERVER then
		return
	end

	local wwise_world = context.wwise_world
	self._world = context.world
	self._wwise_world = wwise_world
	self._weapon_actions = weapon_template.actions
	self._is_husk = context.is_husk
	self._is_local_unit = context.is_local_unit
	self._outline_system = Managers.state.extension:system("outline_system")
	local owner_unit = context.owner_unit
	local unit_data_extension = ScriptUnit.extension(owner_unit, "unit_data_system")
	self._action_module_targeting_component = unit_data_extension:read_component("action_module_targeting")
end

function TargetUnits:fixed_update(unit, dt, t, frame)
end

function TargetUnits:update(unit, dt, t)
	if DEDICATED_SERVER then
		return
	end

	self:_update_outlines()
end

function TargetUnits:update_first_person_mode(first_person_mode)
end

function TargetUnits:wield()
	if DEDICATED_SERVER then
		return
	end

	self:_update_outlines()
end

function TargetUnits:unwield()
	if DEDICATED_SERVER then
		return
	end

	self:_remove_outlines()
end

function TargetUnits:destroy()
	if DEDICATED_SERVER then
		return
	end

	self:_remove_outlines()
end

function TargetUnits:_update_outlines()
	local new_unit_1 = self._action_module_targeting_component.target_unit_1
	local old_unit_1 = self._target_unit_1

	if new_unit_1 ~= old_unit_1 then
		self:_set_outline(old_unit_1, false)
		self:_set_outline(new_unit_1, true)
	end

	self._target_unit_1 = new_unit_1
	local new_unit_2 = self._action_module_targeting_component.target_unit_2
	local old_unit_2 = self._target_unit_2

	if new_unit_2 ~= old_unit_2 then
		self:_set_outline(old_unit_2, false)
		self:_set_outline(new_unit_2, true)
	end

	self._target_unit_2 = new_unit_2
	local new_unit_3 = self._action_module_targeting_component.target_unit_3
	local old_unit_3 = self._target_unit_3

	if new_unit_3 ~= old_unit_3 then
		self:_set_outline(old_unit_3, false)
		self:_set_outline(new_unit_3, true)
	end

	self._target_unit_3 = new_unit_3
end

function TargetUnits:_remove_outlines()
	self:_set_outline(self._target_unit_1, false)

	self._target_unit_1 = nil

	self:_set_outline(self._target_unit_2, false)

	self._target_unit_2 = nil

	self:_set_outline(self._target_unit_3, false)

	self._target_unit_4 = nil
end

function TargetUnits:_set_outline(unit, enabled)
	if not unit then
		return
	end

	if enabled then
		self._outline_system:add_outline(unit, "buff")
	else
		self._outline_system:remove_outline(unit, "buff")
	end
end

return TargetUnits
