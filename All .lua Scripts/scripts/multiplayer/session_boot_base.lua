local function _info(...)
	Log.info("SessionBootBase", ...)
end

local SessionBootBase = class("SessionBootBase")
SessionBootBase.INTERFACE = {
	"result"
}

function SessionBootBase:init(states, event_object)
	self._event_object = event_object
end

function SessionBootBase:update(dt)
	local connection_client = self._connection_client

	if connection_client then
		connection_client:update(dt)

		if connection_client:has_disconnected() then
			self._event_object:failed_to_boot(true, "game", "DISCONNECTED_FROM_HOST")
			connection_client:delete()

			self._connection_client = nil

			self:_set_state("failed")
		end
	end

	local connection_host = self._connection_host

	if connection_host then
		connection_host:update(dt)
	end
end

function SessionBootBase:_set_state(new_state)
	_info("Changed state %s -> %s", self._state, new_state)

	self._state = new_state
end

function SessionBootBase:state()
	return self._state
end

function SessionBootBase:event_object()
	return self._event_object
end

function SessionBootBase:_set_window_title(...)
end

return SessionBootBase
