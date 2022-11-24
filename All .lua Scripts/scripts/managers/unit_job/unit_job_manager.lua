local JobInterface = require("scripts/managers/unit_job/job_interface")
local unit_alive = Unit.alive
local UnitJobManager = class("UnitJobManager")

function UnitJobManager:init(unit_spawner_manager)
	self._unit_spawner_manager = unit_spawner_manager
	self._units = {}
end

function UnitJobManager:destroy()
	self._unit_spawner_manager = nil
	self._units = nil
end

function UnitJobManager:delete_units()
	local unit_spawner_manager = self._unit_spawner_manager
	local units = self._units

	for unit, _ in pairs(units) do
		unit_spawner_manager:mark_for_deletion(unit)

		units[unit] = nil
	end
end

function UnitJobManager:register(unit, job_class)
	self._units[unit] = job_class
end

function UnitJobManager:update(dt, t)
	local unit_spawner_manager = self._unit_spawner_manager
	local units = self._units

	for unit, job_class in pairs(units) do
		if job_class:job_completed() or job_class:is_job_canceled() then
			unit_spawner_manager:mark_for_deletion(unit)

			units[unit] = nil
		end
	end
end

return UnitJobManager
