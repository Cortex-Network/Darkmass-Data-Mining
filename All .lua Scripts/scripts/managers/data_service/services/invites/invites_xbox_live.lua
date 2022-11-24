local InvitesXboxLive = class("InviteInvitesXboxLivesSteam")

local function _error_report(error)
	Log.error("InvitesXboxLive", tostring(error))
end

function InvitesXboxLive:init()
	self._has_invite = false
	self._invites = {}
end

function InvitesXboxLive:update()
	local invites = XboxLiveMPA.invites()

	for i = 1, #invites do
		local invite = invites[i]

		table.insert(self._invites, invite.connection_string)

		self._has_invite = true
	end
end

function InvitesXboxLive:has_invite()
	return self._has_invite
end

function InvitesXboxLive:get_invite()
	if self._has_invite then
		local address = table.remove(self._invites)
		self._has_invite = #self._invites > 0

		return address
	end

	return nil
end

function InvitesXboxLive:send_invite(xuid, invite_address)
	if not Managers.account:user_detached() then
		local user_id = Managers.account:user_id()
		local async_block, error_code = XboxLiveMPA.send_invites(user_id, {
			xuid
		}, true, invite_address)

		if async_block then
			Managers.xasync:wrap(async_block, XboxLiveMPA.release_block):catch(_error_report)
		else
			_error_report(error_code)
		end
	end
end

function InvitesXboxLive:destroy()
end

return InvitesXboxLive
