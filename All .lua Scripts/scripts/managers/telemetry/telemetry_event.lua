local TelemetryEvent = class("TelemetryEvent")

function TelemetryEvent:init(source, subject, type, session)
	self._event = {
		specversion = "1.2",
		source = source,
		subject = subject,
		type = type,
		session = session
	}
end

function TelemetryEvent:set_revision(revision)
	self._event.revision = revision
end

function TelemetryEvent:set_data(data)
	self._event.data = data
end

function TelemetryEvent:raw()
	return self._event
end

function TelemetryEvent:__tostring()
	return table.tostring(self._event, math.huge)
end

return TelemetryEvent
