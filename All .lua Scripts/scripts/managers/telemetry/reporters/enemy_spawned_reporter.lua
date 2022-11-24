local ReporterInterface = require("scripts/managers/telemetry/reporters/reporter_interface")
local EnemySpawnedReporter = class("EnemySpawnedReporter")

function EnemySpawnedReporter:init()
	self._report = {}
end

function EnemySpawnedReporter:update(dt, t)
end

function EnemySpawnedReporter:report()
	if table.is_empty(self._report) then
		return
	end

	Managers.telemetry_events:enemies_spawned_report(self._report)
end

function EnemySpawnedReporter:register_event(enemy)
	self._report[enemy.name] = (self._report[enemy.name] or 0) + 1
end

function EnemySpawnedReporter:destroy()
end

implements(EnemySpawnedReporter, ReporterInterface)

return EnemySpawnedReporter
