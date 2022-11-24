local interface = {
	"delete",
	"destroy",
	"do_re_signin",
	"gamertag",
	"get_privilege",
	"init",
	"is_guest",
	"leaving_game",
	"new",
	"reset",
	"show_profile_picker",
	"signin_profile",
	"signin_state",
	"update",
	"user_detached",
	"user_id",
	"wanted_transition",
	"get_friends",
	"friends_list_has_changes",
	"xuid",
	"refresh_communcation_restrictions",
	"is_muted",
	"is_blocked",
	"fetch_crossplay_restrictions",
	"has_crossplay_restriction",
	"verify_gdk_store_account",
	"verify_user_restriction",
	"user_has_restriction",
	"user_restriction_verified",
	"verify_connection",
	"user_restriction_updated"
}
local NullAccountManager = class("NullAccountManager")

function NullAccountManager:init()
end

function NullAccountManager:reset()
end

function NullAccountManager:wanted_transition()
end

function NullAccountManager:do_re_signin()
	return false
end

function NullAccountManager:signin_profile()
end

function NullAccountManager:user_detached()
	return false
end

function NullAccountManager:leaving_game()
	return false
end

function NullAccountManager:user_id()
	return nil
end

function NullAccountManager:is_guest()
	return false
end

function NullAccountManager:gamertag()
	return ""
end

function NullAccountManager:signin_state()
	return ""
end

function NullAccountManager:update(dt, t)
end

function NullAccountManager:destroy()
end

function NullAccountManager:get_privilege()
end

function NullAccountManager:show_profile_picker()
end

function NullAccountManager:get_friends()
end

function NullAccountManager:friends_list_has_changes()
end

function NullAccountManager:xuid()
end

function NullAccountManager:refresh_communcation_restrictions()
end

function NullAccountManager:is_muted()
	return false
end

function NullAccountManager:is_blocked()
	return false
end

function NullAccountManager:fetch_crossplay_restrictions()
end

function NullAccountManager:has_crossplay_restriction()
	return false
end

function NullAccountManager:verify_gdk_store_account()
	return true
end

function NullAccountManager:verify_user_restriction()
end

function NullAccountManager:user_has_restriction()
	return false
end

function NullAccountManager:user_restriction_verified()
	return true
end

function NullAccountManager:verify_connection()
	return true
end

function NullAccountManager:user_restriction_updated()
end

local AccountManager = {
	new = function (self)
		local instance = nil

		if IS_XBS then
			instance = require("scripts/managers/account/account_manager_xbox_live"):new()

			Log.info("AccountManager", "Using Xbox Live account manager")
		elseif IS_GDK then
			instance = require("scripts/managers/account/account_manager_win_gdk"):new()

			Log.info("AccountManager", "Using Win GDK account manager")
		else
			instance = NullAccountManager:new()

			Log.info("AccountManager", "Using base account manager")
		end

		if rawget(_G, "implements") then
			implements(instance, interface)
		end

		return instance
	end
}

return AccountManager
