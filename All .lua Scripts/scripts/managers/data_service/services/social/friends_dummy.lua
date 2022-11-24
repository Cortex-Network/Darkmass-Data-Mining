local FriendsInterface = require("scripts/managers/data_service/services/friends/friends_interface")
local FriendsDummy = class("FriendsDummy")

function FriendsDummy:init()
end

function FriendsDummy:destroy()
end

local temp_friend_data = {}

function FriendsDummy:fetch()
	return temp_friend_data
end

implements(FriendsDummy, FriendsInterface)

return FriendsDummy
