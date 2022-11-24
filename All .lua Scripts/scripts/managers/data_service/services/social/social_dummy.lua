local PlatformSocialInterface = require("scripts/managers/data_service/services/social/platform_social_interface")
local Promise = require("scripts/foundation/utilities/promise")
local SocialDummy = class("SocialDummy")

function SocialDummy:init()
end

function SocialDummy:destroy()
end

function SocialDummy:friends_list_has_changes()
	return false
end

local empty_list = {}

function SocialDummy:fetch_friends_list()
	local promise = Promise:new()

	promise:resolve(empty_list)

	return promise
end

function SocialDummy:blocked_list_has_changes()
	return false
end

function SocialDummy:fetch_blocked_list()
	local promise = Promise:new()

	promise:resolve(empty_list)

	return promise
end

function SocialDummy:fetch_blocked_list_ids_forced()
	local promise = Promise:new()

	promise:resolve(empty_list)

	return promise
end

function SocialDummy:update_recent_players(account_id)
end

implements(SocialDummy, PlatformSocialInterface)

return SocialDummy
