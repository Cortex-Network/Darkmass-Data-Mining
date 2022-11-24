local FriendInterface = require("scripts/managers/data_service/services/social/friend_interface")
local SocialConstants = require("scripts/managers/data_service/services/social/social_constants")
local FriendSteam = class("FriendsSteam")

function FriendSteam:init(id, app_id)
	self._id = id
	self._app_id = app_id
end

function FriendSteam:id()
	return self._id
end

function FriendSteam:platform()
	return "steam"
end

function FriendSteam:platform_icon()
	return ""
end

function FriendSteam:name()
	return Friends.name(self._id)
end

function FriendSteam:is_friend()
	return Friends.relationship(self._id) == Friends.FRIEND
end

function FriendSteam:is_blocked()
	return Friends.relationship(self._id) == Friends.IGNORED_FRIEND
end

function FriendSteam:online_status()
	local status = Friends.status(self._id)

	if status and (status == Friends.ONLINE or status == Friends.LOOKING_TO_PLAY) then
		return SocialConstants.OnlineStatus.platform_online
	end

	return SocialConstants.OnlineStatus.offline
end

implements(FriendSteam, FriendInterface)

return FriendSteam
