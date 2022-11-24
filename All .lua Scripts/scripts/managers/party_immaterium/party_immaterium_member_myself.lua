local PartyMemberInterface = require("scripts/managers/party_immaterium/party_member_interface")
local PartyImmateriumMemberMyself = class("PartyImmateriumMemberMyself")

function PartyImmateriumMemberMyself:init(account_id)
	self._account_id = account_id
	self._peer_id = account_id
	self._unique_id = account_id
	self._presence_entry = Managers.presence:presence_entry_myself()
end

function PartyImmateriumMemberMyself:update_account_id(account_id)
	self._account_id = account_id
	self._peer_id = account_id
	self._unique_id = account_id
end

function PartyImmateriumMemberMyself:is_online()
	return true
end

function PartyImmateriumMemberMyself:platform()
	return self._platform
end

function PartyImmateriumMemberMyself:presence_name()
	return self._presence_entry:activity_id()
end

function PartyImmateriumMemberMyself:presence_id()
	return self._presence_entry:activity_id()
end

function PartyImmateriumMemberMyself:presence_hud_text()
	return self._presence_entry:activity_localized()
end

function PartyImmateriumMemberMyself:peer_id()
	return self._peer_id
end

function PartyImmateriumMemberMyself:unique_id()
	return self._unique_id
end

function PartyImmateriumMemberMyself:name()
	return self._presence_entry:character_name()
end

function PartyImmateriumMemberMyself:profile()
	return self._presence_entry:character_profile()
end

function PartyImmateriumMemberMyself:account_id()
	return self._account_id
end

function PartyImmateriumMemberMyself:destroy()
end

function PartyImmateriumMemberMyself:is_human_controlled()
	return true
end

function PartyImmateriumMemberMyself:unit_is_alive()
	return false
end

function PartyImmateriumMemberMyself:is_party_player()
	return true
end

implements(PartyImmateriumMemberMyself, PartyMemberInterface)

return PartyImmateriumMemberMyself
