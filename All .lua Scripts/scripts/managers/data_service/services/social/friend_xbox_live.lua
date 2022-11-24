local FriendInterface = require("scripts/managers/data_service/services/social/friend_interface")
local SocialConstants = require("scripts/managers/data_service/services/social/social_constants")
local FriendXboxLive = class("FriendXboxLive")

function FriendXboxLive:init(friend_data, is_blocked)
	self._id = friend_data.xuid
	self._name = friend_data.gamertag
	self._is_blocked = is_blocked
	self._friend_data = friend_data

	if friend_data.is_online then
		self._online_state = SocialConstants.OnlineStatus.platform_online
	else
		self._online_state = SocialConstants.OnlineStatus.offline
	end
end

function FriendXboxLive:id()
	return self._id
end

function FriendXboxLive:platform()
	return SocialConstants.Platforms.xbox
end

function FriendXboxLive:platform_icon()
	return ""
end

function FriendXboxLive:name()
	return self._name
end

function FriendXboxLive:is_friend()
	return not self._is_blocked
end

function FriendXboxLive:is_blocked()
	return self._is_blocked or Managers.account:is_blocked(self._id)
end

function FriendXboxLive:online_status()
	return self._online_state
end

implements(FriendXboxLive, FriendInterface)

return FriendXboxLive
