local PresenceManagerDummy = class("PresenceManagerDummy")
local Promise = require("scripts/foundation/utilities/promise")
local PresenceEntryImmaterium = require("scripts/managers/presence/presence_entry_immaterium")
local PresenceManagerInterface = require("scripts/managers/presence/presence_manager_interface")
local PresenceEntryMyself = require("scripts/managers/presence/presence_entry_myself")

function PresenceManagerDummy:init()
	self._myself = PresenceEntryMyself:new()
end

function PresenceManagerDummy:set_presence(presence_name)
end

function PresenceManagerDummy:set_party(party_id, num_party_members)
end

function PresenceManagerDummy:set_num_mission_members(num_mission_members)
end

function PresenceManagerDummy:update(dt, t)
end

function PresenceManagerDummy:get_presence(account_id)
	if account_id == self._myself:account_id() then
		return self._myself
	end

	local presence_entry = PresenceEntryImmaterium:new(self._myself:platform(), "", account_id)

	return presence_entry, Promise.resolved(nil)
end

function PresenceManagerDummy:get_presence_by_platform(platform, platform_user_id)
	local presence_entry = PresenceEntryImmaterium:new(self._myself:platform(), platform, platform_user_id)

	return presence_entry, Promise.resolved(nil)
end

function PresenceManagerDummy:presence_entry_myself()
	return self._myself
end

function PresenceManagerDummy:get_requested_platform_username()
	return nil
end

implements(PresenceManagerDummy, PresenceManagerInterface)

return PresenceManagerDummy
