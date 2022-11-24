local Promise = require("scripts/foundation/utilities/promise")
local XAsyncManager = class("XAsyncManager")

function XAsyncManager:init()
	self._async_blocks = {}
end

function XAsyncManager:in_progress()
	return not table.is_empty(self._async_blocks)
end

function XAsyncManager:wrap(async_block, release_function, debug_name)
	local p = Promise:new()
	self._async_blocks[async_block] = {
		promise = p,
		release_function = release_function,
		debug_name = debug_name
	}

	return p
end

function XAsyncManager:release(async_block)
	local promise = self._async_blocks[async_block].promise
	local release_function = self._async_blocks[async_block].release_function
	local debug_name = self._async_blocks[async_block].debug_name

	if promise and promise:is_pending() then
		if debug_name then
			Log.error("XAsyncManager", "Aborted async_block with debug_name %s", debug_name)
		end

		promise:reject({
			HRESULT.E_ABORT
		})
	end

	release_function(async_block)

	self._async_blocks[async_block] = nil
end

function XAsyncManager:update(dt)
	for async_block, data in pairs(self._async_blocks) do
		if not data.promise:is_pending() then
			local release_function = data.release_function

			release_function(async_block)

			self._async_blocks[async_block] = nil
		end
	end

	for async_block, data in pairs(self._async_blocks) do
		local hr = XAsyncBlock.status(async_block)

		if hr == HRESULT.S_OK then
			data.promise:resolve(async_block)
		elseif hr ~= HRESULT.E_PENDING then
			if data.debug_name then
				Log.error("XAsyncManager", "Rejecting async_block with debug_name %s, error code 0x%x", data.debug_name, tostring(hr))
			end

			data.promise:reject({
				hr
			})
		end
	end
end

function XAsyncManager:destroy()
	for async_block, data in pairs(self._async_blocks) do
		if data.promise:is_pending() then
			if data.debug_name then
				Log.error("XAsyncManager", "Aborted async_block with debug_name %s", data.debug_name)
			end

			data.promise:reject({
				HRESULT.E_ABORT
			})
		end

		local release_function = data.release_function

		release_function(async_block)

		self._async_blocks[async_block] = nil
	end
end

return XAsyncManager
