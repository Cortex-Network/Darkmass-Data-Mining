local BackendUtilities = require("scripts/foundation/managers/backend/utilities/backend_utilities")
local Promise = require("scripts/foundation/utilities/promise")
local Interface = {}
local Progression = class("Progression")

function Progression:init()
end

function Progression:get_xp_table(entity_type)
	return Managers.backend:title_request(BackendUtilities.url_builder("/data/experience-table/"):path(entity_type):to_string()):next(function (data)
		return data.body.levelCurve
	end)
end

function Progression:get_account_progression()
	return Managers.backend:authenticate():next(function (account)
		return self:get_progression("account", account.sub)
	end)
end

function Progression:get_progression(entity_type, id)
	local url = BackendUtilities.url_builder(entity_type):path("/"):path(id)
	local account_id = entity_type == "account" and id or nil

	return BackendUtilities.make_account_title_request("progression", url, nil, account_id):next(function (data)
		return data.body
	end):catch(function (error)
		if error.status == 404 then
			return nil
		else
			local p = Promise:new()

			p:reject(error)

			return p
		end
	end)
end

function Progression:get_entity_type_progression(entity_type)
	return BackendUtilities.make_account_title_request("progression", BackendUtilities.url_builder()):next(function (data)
		local progression_info = data.body.progressionInfo
		local result = {}

		for i = 1, #progression_info do
			local info = progression_info[i]

			if info.type == entity_type then
				result[#result + 1] = info
			end
		end

		return result
	end)
end

function Progression:get_all_progression()
	return BackendUtilities.make_account_title_request("progression", BackendUtilities.url_builder()):next(function (data)
		return data.body.progressionInfo
	end)
end

function Progression:level_up(entity_type, id, to_level)
	local url = BackendUtilities.url_builder(entity_type):path("/"):path(id):path("/level/"):path(to_level)
	local options = {
		method = "PUT",
		body = {
			placeHolder = "might need something"
		}
	}
	local account_id = entity_type == "account" and id or nil

	return BackendUtilities.make_account_title_request("progression", url, options, account_id):next(function (data)
		return data.body
	end)
end

function Progression:level_up_character(character_id, to_level)
	return self:level_up("character", character_id, to_level)
end

function Progression:level_up_account(account_id, to_level)
	return self:level_up("account", account_id, to_level)
end

implements(Progression, Interface)

return Progression
