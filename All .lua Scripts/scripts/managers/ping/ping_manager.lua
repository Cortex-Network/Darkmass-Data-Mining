local Promise = require("scripts/foundation/utilities/promise")
local PingManager = class("PingManager")

function PingManager:init()
	self._ping_operation_promises = {}
end

function PingManager:ping(timeout, targets)
	local id, error = Ping.ping(2, unpack(targets))

	if error then
		return Promise.rejected(error)
	end

	local promise = Promise:new()
	self._ping_operation_promises[id] = promise

	return promise
end

function PingManager:update(dt)
	local done_operations = Ping.update()

	if done_operations then
		for _, operation in ipairs(done_operations) do
			local promise = self._ping_operation_promises[operation.id]

			if promise then
				promise:resolve(operation.results)
			end
		end
	end
end

return PingManager
