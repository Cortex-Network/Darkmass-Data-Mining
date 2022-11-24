local ReporterInterface = require("scripts/managers/telemetry/reporters/reporter_interface")
local HeartbeatReporter = class("HeartbeatReporter")
local SAMPLE_INTERVAL = 300

function HeartbeatReporter:init()
	self._last_sample_time = 0
end

function HeartbeatReporter:destroy()
end

function HeartbeatReporter:update(dt, t)
	if SAMPLE_INTERVAL < t - self._last_sample_time then
		Managers.telemetry_events:heartbeat()

		self._last_sample_time = math.floor(t)
	end
end

function HeartbeatReporter:report()
end

implements(HeartbeatReporter, ReporterInterface)

return HeartbeatReporter
