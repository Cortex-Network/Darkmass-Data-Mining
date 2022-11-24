local InvitesSteam = class("InvitesSteam")

function InvitesSteam:init()
	self._has_invite = false
	self._invite_address = nil
	local invite_type, lobby_address = Friends.boot_invite()

	if invite_type == Friends.INVITE_LOBBY then
		self._has_invite = true
		self._invite_address = lobby_address
	end

	if invite_type == Friends.INVITE_IMMATERIUM_PARTY then
		self._has_invite = true
		self._invite_address = lobby_address
	end
end

function InvitesSteam:update()
	local invite_type, lobby_address, params, invitee = Friends.next_invite()

	if GameParameters.prod_like_backend and invite_type == Friends.INVITE_IMMATERIUM_PARTY then
		self._has_invite = true
		self._invite_address = lobby_address
	end
end

function InvitesSteam:has_invite()
	return self._has_invite
end

function InvitesSteam:get_invite()
	if self._has_invite then
		local address = self._invite_address
		self._invite_address = nil
		self._has_invite = false

		return address
	end

	return nil
end

function InvitesSteam:send_invite(invitee_id, immaterium_party_id)
	Friends.invite_immaterium_party(invitee_id, immaterium_party_id)
end

function InvitesSteam:destroy()
end

return InvitesSteam
