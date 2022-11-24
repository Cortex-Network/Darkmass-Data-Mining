local PresenceEntryInterface = require("scripts/managers/presence/presence_entry")
local PresenceSettings = require("scripts/settings/presence/presence_settings")
local Promise = require("scripts/foundation/utilities/promise")
local ProfileUtils = require("scripts/utilities/profile_utils")
local PresenceEntryImmaterium = class("PresenceEntryImmaterium")

function PresenceEntryImmaterium:init(my_own_platform, platform, platform_user_id)
	self._my_own_platform = my_own_platform
	local immaterium_entry = {
		account_name = "",
		platform = "",
		platform_user_id = "",
		status = "OFFLINE",
		last_update = -1,
		account_id = "",
		key_values = {}
	}

	if platform == "" then
		self._account_id = platform_user_id
		immaterium_entry.account_id = platform_user_id
	else
		self._platform = platform
		self._platform_user_id = platform_user_id
		immaterium_entry.platform = platform
		immaterium_entry.platform_user_id = platform_user_id
	end

	self._immaterium_entry = immaterium_entry
	self._alive_queried = true
	self._alive = true
	self._stream_first_update_promises = {}
	self._parsed_character_profile = nil
	self._started = false
	self._request_platform = nil
	self._request_id = nil
end

function PresenceEntryImmaterium:destroy()
	Managers.presence:_abort_batched_presence(self)

	if self._stream_first_update_promises then
		local error = {
			aborted = true
		}

		for _, promise in ipairs(self._stream_first_update_promises) do
			promise:reject(error)
		end

		self._stream_first_update_promises = nil
	end

	self._alive = false
end

function PresenceEntryImmaterium:update()
	if self._started then
		local new_immaterium_entry = Managers.presence:_get_batched_presence(self, self._request_platform, self._request_platform_user_id)

		if new_immaterium_entry then
			self:update_with(new_immaterium_entry)

			if self._stream_first_update_promises then
				for _, promise in ipairs(self._stream_first_update_promises) do
					promise:resolve(self)
				end

				self._stream_first_update_promises = nil
			end
		end
	end
end

function PresenceEntryImmaterium:first_update_promise()
	if self._stream_first_update_promises then
		local promise = Promise:new()

		table.insert(self._stream_first_update_promises, promise)

		return promise
	end

	return Promise.resolved(self)
end

function PresenceEntryImmaterium:start_stream()
	if self._account_id then
		self._request_platform = ""
		self._request_platform_user_id = self._account_id
	else
		self._request_platform = self._platform
		self._request_platform_user_id = self:_convert_platform_user_id_for_immaterium(self._platform, self._platform_user_id)
	end

	self._started = true
end

function PresenceEntryImmaterium:update_with(new_entry)
	if not self._immaterium_entry or self._immaterium_entry.last_update < new_entry.last_update then
		self._immaterium_entry = self:_process_platform_id_convert(new_entry)
		self._immaterium_entry = self:_process_character_profile_convert(new_entry)

		self:_update_from_platform()

		self._account_and_platform_composite_id = self:account_id() .. ":" .. self:platform() .. ":" .. self:platform_user_id()
	end
end

function PresenceEntryImmaterium:is_myself()
	return false
end

function PresenceEntryImmaterium:account_id()
	return self._immaterium_entry.account_id
end

function PresenceEntryImmaterium:account_and_platform_composite_id()
	return self._account_and_platform_composite_id
end

function PresenceEntryImmaterium:account_name()
	return self._immaterium_entry.account_name
end

function PresenceEntryImmaterium:activity_id()
	return self:_key_value_string("activity_id") or "splash_screen"
end

function PresenceEntryImmaterium:activity_localized()
	local hud_localization = PresenceSettings[self:activity_id()].hud_localization

	return Managers.localization:localize(hud_localization)
end

function PresenceEntryImmaterium:character_id()
	return self:character_profile() and self:character_profile().character_id or ""
end

function PresenceEntryImmaterium:character_name()
	return self:character_profile() and self:character_profile().name or ""
end

function PresenceEntryImmaterium:character_profile()
	return self._parsed_character_profile
end

function PresenceEntryImmaterium:platform()
	return self._immaterium_entry.platform
end

function PresenceEntryImmaterium:platform_icon()
	local platform = self._immaterium_entry.platform
	local is_on_my_platform = self._my_own_platform == platform

	if is_on_my_platform then
		if platform == "steam" then
			return ""
		elseif platform == "xbox" then
			return ""
		end
	end

	return nil
end

function PresenceEntryImmaterium:platform_user_id()
	return self._immaterium_entry.platform_user_id
end

function PresenceEntryImmaterium:is_online()
	return self._immaterium_entry.status == "ONLINE"
end

function PresenceEntryImmaterium:platform_persona_name_or_account_name()
	local platform = self:platform()
	local platform_user_id = self:platform_user_id()

	if platform and platform_user_id then
		local platform_username = Managers.presence:get_requested_platform_username(platform, platform_user_id)

		if platform_username then
			return platform_username
		end
	end

	if self._immaterium_entry.account_name ~= "" then
		return self._immaterium_entry.account_name
	end

	return nil
end

function PresenceEntryImmaterium:num_party_members()
	return tonumber(self:_key_value_string("num_party_members")) or 0
end

function PresenceEntryImmaterium:num_mission_members()
	return tonumber(self:_key_value_string("num_mission_members")) or 0
end

function PresenceEntryImmaterium:party_id()
	return self:_key_value_string("party_id")
end

function PresenceEntryImmaterium:is_alive()
	if self._alive then
		self._alive_queried = true
	end

	return self._alive
end

function PresenceEntryImmaterium:reset_alive_queried()
	local alive_queried = self._alive_queried
	self._alive_queried = false

	return alive_queried
end

function PresenceEntryImmaterium:_process_platform_id_convert(new_entry)
	if new_entry.platform == "steam" or new_entry.platform == "xbox" then
		new_entry.platform_user_id = Application.dec64_to_hex(new_entry.platform_user_id)
	end

	return new_entry
end

function PresenceEntryImmaterium:_process_character_profile_convert(new_entry)
	local character_profile = new_entry.key_values.character_profile

	if character_profile then
		local parsed_character_profile = self._parsed_character_profile

		if character_profile.value == nil or character_profile.value == "" then
			self._parsed_character_profile = nil
		elseif not parsed_character_profile or parsed_character_profile.hash ~= character_profile.hash then
			parsed_character_profile = ProfileUtils.backend_profile_data_to_profile(ProfileUtils.process_backend_body(cjson.decode(character_profile.value)))

			if parsed_character_profile then
				parsed_character_profile.hash = character_profile.hash
				self._parsed_character_profile = parsed_character_profile

				Managers.event:trigger("event_player_profile_updated", nil, , parsed_character_profile)
			end
		end
	else
		self._parsed_character_profile = nil
	end

	return new_entry
end

function PresenceEntryImmaterium:_update_from_platform()
	local platform = self:platform()
	local platform_user_id = self:platform_user_id()

	if platform and platform_user_id then
		Managers.presence:request_platform_username_async(platform, platform_user_id)
	end
end

function PresenceEntryImmaterium:_convert_platform_user_id_for_immaterium(platform, platform_user_id)
	if (platform == "steam" or platform == "xbox") and platform_user_id then
		return Application.hex64_to_dec(platform_user_id)
	end

	return platform_user_id
end

function PresenceEntryImmaterium:_key_value_string(key)
	return self._immaterium_entry.key_values[key] and self._immaterium_entry.key_values[key].value or nil
end

implements(PresenceEntryImmaterium, PresenceEntryInterface)

return PresenceEntryImmaterium
