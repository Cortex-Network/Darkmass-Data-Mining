local BackendUtilities = require("scripts/foundation/managers/backend/utilities/backend_utilities")
local Interface = {}
local Account = class("Account")

function Account:init()
end

function Account:get_boon_inventory()
	return BackendUtilities.make_account_title_request("account", BackendUtilities.url_builder("boons")):next(function (data)
		return data.body
	end)
end

function Account:set_has_created_first_character(value)
	return self:set_data("core", {
		has_created_first_character = value
	})
end

function Account:get_has_created_first_character()
	return self:get_data("core", "has_created_first_character")
end

function Account:set_has_completed_onboarding(value)
	return self:set_data("core", {
		has_completed_onboarding = value
	})
end

function Account:get_has_completed_onboarding()
	return self:get_data("core", "has_completed_onboarding")
end

function Account:set_selected_character(character_id)
	return self:set_data("core", {
		selected_character = character_id
	})
end

function Account:get_selected_character()
	return self:get_data("core", "selected_character")
end

function Account:set_data(section, data)
	return BackendUtilities.make_account_title_request("account", BackendUtilities.url_builder("/data/"):path(section), {
		method = "PUT",
		body = {
			data = data
		}
	}):next(function (data)
		return nil
	end)
end

function Account:get_data(section, part)
	return BackendUtilities.make_account_title_request("account", BackendUtilities.url_builder("/data/"):path(section)):next(function (data)
		if part then
			if #data.body.data > 0 then
				return data.body.data[1].value[part]
			else
				return nil
			end
		else
			return data
		end
	end)
end

implements(Account, Interface)

return Account
