local KillSynchronizerExtension = class("KillSynchronizerExtension", "EventSynchronizerBaseExtension")

function KillSynchronizerExtension:init(extension_init_context, unit, extension_init_data, ...)
	KillSynchronizerExtension.super.init(self, extension_init_context, unit, extension_init_data, ...)

	self._objective_name = "default"
	self._automatic_start = false
	self._progression = 0
	self._registered_units = {}
	self._num_registered_units = 0
	self._check_unit_condition_timer = 0
	self._check_unit_condition_interval = 0.2
end

function KillSynchronizerExtension:setup_from_component(objective_name, automatic_start)
	self._objective_name = objective_name
	self._automatic_start = automatic_start

	self._mission_objective_system:register_objective_synchronizer(objective_name, self._unit)
end

function KillSynchronizerExtension:fixed_update(unit, dt, t)
	if self._mission_active and self._is_server and self._num_registered_units > 0 then
		local check_unit_condition_timer = self._check_unit_condition_timer

		if check_unit_condition_timer > 0 then
			check_unit_condition_timer = math.max(check_unit_condition_timer - dt, 0)
		else
			local registered_units = self._registered_units
			local health_progress = 0

			for minion_unit, _ in pairs(registered_units) do
				local health_extension = ScriptUnit.has_extension(minion_unit, "health_system")

				if health_extension then
					health_progress = health_progress + health_extension:current_health_percent()
				end
			end

			health_progress = 1 - health_progress / self._num_registered_units
			health_progress = math.clamp(health_progress, 0, 1)
			self._progression = health_progress
			check_unit_condition_timer = self._check_unit_condition_interval
		end

		self._check_unit_condition_timer = check_unit_condition_timer
	end
end

function KillSynchronizerExtension:register_minion_unit(unit)
	local registered_units = self._registered_units
	registered_units[unit] = true
	self._registered_units = registered_units
	self._num_registered_units = self._num_registered_units + 1
end

function KillSynchronizerExtension:progression()
	return self._progression
end

function KillSynchronizerExtension:auto_start()
	return self._automatic_start
end

return KillSynchronizerExtension
