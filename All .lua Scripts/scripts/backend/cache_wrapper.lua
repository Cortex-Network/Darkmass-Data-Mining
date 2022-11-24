local Promise = require("scripts/foundation/utilities/promise")
local CacheWrapper = class("CacheWrapper")
local Interface = {
	"refresh",
	"get_cached",
	"has_data",
	"add_listener",
	"remove_listener"
}

function CacheWrapper:init(metadata_fn, refresh_fn, fallback_fn)
	self._metadata_fn = metadata_fn
	self._refresh_fn = refresh_fn
	self._fallback_fn = fallback_fn
	self._current_metadata = {}
	self._current_value = nil
	self._listeners = {}
end

function CacheWrapper:add_listener(callback_fn)
	self._listeners[callback_fn] = true
end

function CacheWrapper:remove_listener(callback_fn)
	self._listeners[callback_fn] = nil
end

function CacheWrapper:refresh(version, url)
	local promise = nil

	if version ~= nil and url ~= nil then
		promise = Promise.resolved({
			version = version,
			url = url
		})
	else
		promise = self._metadata_fn()
	end

	return promise:next(function (metadata)
		Log.debug("CacheWrapper", "Got meta data with version: %s", metadata.version)

		if self._current_metadata.version ~= metadata.version then
			return self._refresh_fn(metadata.version, metadata.url):next(function (v)
				self._current_metadata = metadata
				self._current_value = v

				for k, _ in pairs(self._listeners) do
					local success, reason = pcall(function ()
						k(metadata.version, v)
					end)

					if not success then
						Log.error("CacheWrapper", "Unexpected error when calling cache listener: %s", reason)
					end
				end

				return v
			end)
		else
			return self._current_value
		end
	end):catch(function (e)
		Log.warning("CacheWrapper", "Error refreshing data for cached value \n%s", tostring(e))

		if self._current_value then
			return self._current_value
		else
			Log.warning("CacheWrapper", "No already cached value, using fallback")

			return self._fallback_fn():next(function (v)
				self._current_value = v

				return v
			end)
		end
	end)
end

function CacheWrapper:get_version()
	return self._current_metadata and self._current_metadata.version
end

function CacheWrapper:get_metadata()
	return self._current_metadata or {}
end

function CacheWrapper:get_cached()
	return self._current_value
end

function CacheWrapper:has_data()
	return self._current_value ~= nil
end

implements(CacheWrapper, Interface)

return CacheWrapper
