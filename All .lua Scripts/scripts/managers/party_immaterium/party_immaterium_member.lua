local PartyMemberInterface = require("scripts/managers/party_immaterium/party_member_interface")
local PartyImmateriumMember = class("PartyImmateriumMember")

function PartyImmateriumMember:init(account_id)
	self._account_id = account_id
	self._peer_id = account_id
	self._unique_id = account_id
	self._name = account_id

	self:_update_presence()
end

function PartyImmateriumMember:_get_presence()
	local presence = self._presence

	if presence and presence:is_alive() then
		return presence
	else
		self._presence = nil

		self:_update_presence()

		return self._presence
	end
end

function PartyImmateriumMember:_update_presence()
	if not self._presence then
		self._presence = Managers.presence:get_presence(self._account_id)
	end
end

function PartyImmateriumMember:update_immaterium_entry(immaterium_entry)
	self._immaterium_entry = immaterium_entry
end

function PartyImmateriumMember:is_online()
	return self:_get_presence():is_online()
end

function PartyImmateriumMember:is_connected()
	return self._immaterium_entry.status == "CONNECTED"
end

function PartyImmateriumMember:invite_expires()
	return self._immaterium_entry.invite_expires
end

function PartyImmateriumMember:platform()
	return self:_get_presence():platform()
end

function PartyImmateriumMember:platform_user_id()
	return self:_get_presence():platform_user_id()
end

function PartyImmateriumMember:presence()
	return self:_get_presence()
end

function PartyImmateriumMember:presence_name()
	return self:_get_presence():activity_id()
end

function PartyImmateriumMember:presence_id()
	return self:_get_presence():activity_id()
end

function PartyImmateriumMember:presence_hud_text()
	return self:_get_presence():activity_localized()
end

function PartyImmateriumMember:peer_id()
	return self._peer_id
end

function PartyImmateriumMember:unique_id()
	return self._unique_id
end

function PartyImmateriumMember:name()
	local presence = self:_get_presence()

	return presence:character_name()
end

function PartyImmateriumMember:account_id()
	return self._account_id
end

function PartyImmateriumMember:profile()
	local presence = self:_get_presence()

	return presence:character_profile()
end

function PartyImmateriumMember:destroy()
end

function PartyImmateriumMember:is_human_controlled()
	return true
end

function PartyImmateriumMember:unit_is_alive()
	return false
end

function PartyImmateriumMember:is_party_player()
	return true
end

implements(PartyImmateriumMember, PartyMemberInterface)

return PartyImmateriumMember
