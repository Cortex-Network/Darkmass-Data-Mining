local ReporterInterface = require("scripts/managers/telemetry/reporters/reporter_interface")
local ComWheelReporter = class("ComWheelReporter")

function ComWheelReporter:init()
	self._report = {}
end

function ComWheelReporter:update(dt, t)
end

function ComWheelReporter:report()
	if table.is_empty(self._report) then
		return
	end

	Managers.telemetry_events:com_wheel_report(self._report)
end

function ComWheelReporter:register_event(option_name)
	self._report[option_name] = (self._report[option_name] or 0) + 1
end

function ComWheelReporter:destroy()
end

implements(ComWheelReporter, ReporterInterface)

return ComWheelReporter
