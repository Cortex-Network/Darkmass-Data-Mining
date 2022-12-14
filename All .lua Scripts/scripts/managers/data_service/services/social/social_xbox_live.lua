local PlatformSocialInterface = require("scripts/managers/data_service/services/social/platform_social_interface")
local FriendXboxLive = require("scripts/managers/data_service/services/social/friend_xbox_live")
local PlayerManager = require("scripts/foundation/managers/player/player_manager")
local Promise = require("scripts/foundation/utilities/promise")
local XboxLiveUtils = require("scripts/foundation/utilities/xbox_live")
local SocialXboxLive = class("SocialXboxLive")

function SocialXboxLive:init()
	self._num_friends = 0
	self._num_blocked = 0
	self._friends_promise = nil
	self._blocked_promise = nil
	self._updated_recent_players = {}
end

function SocialXboxLive:destroy()
end

function SocialXboxLive:friends_list_has_changes()
	return Managers.account:friends_list_has_changes()
end

local function _process_relationships_page(user_id, page_handle, promise, xuids)
	local _, relationships, error = XSocial.relationships_result_get_relationships(user_id, page_handle)

	if error then
		XSocial.close_relationships_handle(page_handle)
		promise:reject({
			error
		})

		return
	end

	if relationships then
		for i = 1, #relationships do
			xuids[i] = relationships[i].xuid
		end
	end

	if not XSocial.relationships_result_has_next(page_handle) then
		XSocial.close_relationships_handle(page_handle)
		promise:resolve(xuids)

		return
	end

	local relationships_async, error = XSocial.relationships_result_get_next(user_id, page_handle, 100)

	XSocial.close_relationships_handle(page_handle)

	if error then
		promise:reject({
			error
		})

		return
	end

	Managers.xasync:wrap(relationships_async, XSocial.release_block):next(function (async_block)
		local next_page_handle, error = XSocial.get_relationships_result(async_block)

		if error then
			XSocial.close_relationships_handle(next_page_handle)
			promise:reject({
				error
			})
		else
			_process_relationships_page(user_id, next_page_handle, promise, xuids)
		end
	end)
end

function SocialXboxLive:fetch_friends_list()
	local friends_promise = self._friends_promise

	if friends_promise and friends_promise:is_pending() then
		return friends_promise
	end

	local profiles = {}
	self._friends_promise = Promise:new()
	local friends_list = Managers.account:get_friends()

	for i = 1, #friends_list do
		local friend_data = friends_list[i]
		profiles[#profiles + 1] = FriendXboxLive:new(friend_data)
	end

	self._num_friends = #profiles

	self._friends_promise:resolve(profiles)

	return self._friends_promise
end

function SocialXboxLive:blocked_list_has_changes()
	return false
end

function SocialXboxLive:fetch_blocked_list()
	local blocked_promise = self._blocked_promise

	if blocked_promise and blocked_promise:is_pending() then
		return blocked_promise
	end

	self._blocked_promise = Promise:new()

	XboxLiveUtils.get_avoid_list():next(function (xuids)
		if #xuids > 0 then
			return XboxLiveUtils.get_user_profiles(xuids)
		else
			return Promise.resolved({})
		end
	end):next(function (profiles)
		local is_blocked = true

		for i = 1, #profiles do
			local profile = profiles[i]
			profiles[i] = FriendXboxLive:new(profile.xuid, profile.gamertag, is_blocked)
		end

		self._num_blocked = #profiles

		self._blocked_promise:resolve(profiles)
	end):catch(function (error)
		self._blocked_promise:reject({
			error
		})
	end)

	return self._blocked_promise
end

function SocialXboxLive:fetch_blocked_list_ids_forced()
	return XboxLiveUtils.get_block_list()
end

function SocialXboxLive:update_recent_players(account_id)
	if self._updated_recent_players[account_id] then
		return
	end

	self._updated_recent_players[account_id] = true
	local _, promise = Managers.presence:get_presence(account_id)

	promise:next(function (presence)
		if presence and presence:platform() == "xbox" then
			local xuid = presence:platform_user_id()

			if xuid then
				Log.info("SocialXboxLive", "[XboxLive] Updating recent player (account_id: %s, xuid: %s)", account_id, xuid)
				XboxLiveUtils.update_recent_player_teammate(xuid)
			end
		end
	end):catch(function (err)
		Log.info("SocialXboxLive", "[XboxLive] Couldn't update recent player, presence error: %s", table.tostring(err))
	end)
end

implements(SocialXboxLive, PlatformSocialInterface)

return SocialXboxLive
