local PlatformSocialInterface = require("scripts/managers/data_service/services/social/platform_social_interface")
local FriendSteam = require("scripts/managers/data_service/services/social/friend_steam")
local Promise = require("scripts/foundation/utilities/promise")
local SocialSteam = class("SocialSteam")

function SocialSteam:init()
	self._num_friends = 0
	self._num_blocked = 0
end

function SocialSteam:destroy()
end

function SocialSteam:friends_list_has_changes()
	local num_friends = Friends.num_friends(Friends.FRIEND_FLAG)

	return self._num_friends ~= num_friends
end

function SocialSteam:fetch_friends_list()
	local friend_list = {}
	local promise = Promise:new()
	local app_id = Steam.app_id()
	local num_friends = Friends.num_friends(Friends.FRIEND_FLAG)

	for i = 1, num_friends do
		local id = Friends.id(i)
		local friend = FriendSteam:new(id, app_id)
		friend_list[i] = friend
	end

	promise:resolve(friend_list)

	self._num_friends = num_friends

	return promise
end

function SocialSteam:blocked_list_has_changes()
	local num_blocked = Friends.num_friends(Friends.IGNORED_FRIEND_FLAG)

	return self._num_blocked ~= num_blocked
end

function SocialSteam:fetch_blocked_list()
	local blocked_list = {}
	local app_id = Steam.app_id()
	local promise = Promise:new()
	local num_blocked = Friends.num_friends(Friends.IGNORED_FRIEND_FLAG)

	for i = 1, num_blocked do
		local id = Friends.id(i)
		local blocked = FriendSteam:new(id, app_id)
		blocked_list[i] = blocked
	end

	promise:resolve(blocked_list)

	self._num_blocked = num_blocked

	return promise
end

function SocialSteam:fetch_blocked_list_ids_forced()
	local blocked_list = {}
	local promise = Promise:new()
	local num_blocked = Friends.num_friends(Friends.IGNORED_FRIEND_FLAG)

	for i = 1, num_blocked do
		local id = Friends.id(i)
		blocked_list[i] = id
	end

	promise:resolve(blocked_list)

	return promise
end

function SocialSteam:update_recent_players(account_id)
end

implements(SocialSteam, PlatformSocialInterface)

return SocialSteam
