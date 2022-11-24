local BackendUtilities = require("scripts/foundation/managers/backend/utilities/backend_utilities")
local Wintracks = class("Wintracks")

local function _patch_wintrack(character_id, wintrack_id, body)
	return BackendUtilities.make_account_title_request("characters", BackendUtilities.url_builder(character_id):path("/wintracks/"):path(wintrack_id), {
		method = "PATCH",
		body = body
	}):next(function (data)
		return true
	end)
end

function Wintracks:set_wintrack_active_state(character_id, wintrack_id, active)
	return _patch_wintrack(character_id, wintrack_id, {
		active = active or false
	})
end

local function _map_to_id(wintracks)
	local mapped = {}
	local len = #wintracks

	for i = 1, len do
		local wintrack = wintracks[i]
		mapped[wintrack.id] = wintrack
	end

	return mapped
end

function Wintracks:get_wintracks_state(include_info)
	return Managers.backend:authenticate():next(function (account)
		local path = BackendUtilities.url_builder():path("/data/"):path(account.sub):path("/wintrackstate"):to_string()

		return Managers.backend:title_request(path)
	end):next(function (data)
		local wintracks = data.body.wintracks
		local mapped = _map_to_id(wintracks)

		if include_info then
			return BackendUtilities.fetch_embedded_links(data.body):next(function (items)
				local infos = {}
				local len = #items

				for i = 1, len do
					local item = items[i]
					local data = item.body
					data._links = nil
					local state = mapped[data.id]
					state.info = data
				end

				return mapped
			end)
		else
			return mapped
		end
	end)
end

function Wintracks:get_wintrack(wintrack_id)
	local path = BackendUtilities.url_builder():path("/wintracks/"):path(wintrack_id):to_string()

	return Managers.backend:title_request(path):next(function (data)
		return data.body
	end)
end

return Wintracks
