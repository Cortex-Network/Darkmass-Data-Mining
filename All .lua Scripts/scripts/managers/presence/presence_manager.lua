local PresenceEntryMyself = require("scripts/managers/presence/presence_entry_myself")
local PresenceEntryImmaterium = require("scripts/managers/presence/presence_entry_immaterium")
local PresenceManagerInterface = require("scripts/managers/presence/presence_manager_interface")
local LoggedInFromAnotherLocationError = require("scripts/managers/error/errors/logged_in_from_another_location_error")
local Promise = require("scripts/foundation/utilities/promise")
local XboxLiveUtilities = require("scripts/foundation/utilities/xbox_live")
local PresenceManager = class("PresenceManager")
local PRESENCE_UPDATE_INTERVAL = 30

local function _info(...)
	Log.info("PresenceManager", ...)
end

local function _error(...)
	Log.error("PresenceManager", ...)
end

local function remove_empty_values(t)
	if table.is_empty(t) then
		return t
	end

	local result = {}

	for k, v in pairs(t) do
		if v ~= nil then
			result[k] = v
		end
	end

	return result
end

function PresenceManager:init()
	self._myself = PresenceEntryMyself:new()
	self._presences_by_account_id = {}
	self._presences_by_platform_id = {}
	self._character_name_update_interval = 0
	self._update_interval = 0

	self:_init_immaterium_presence()
	self:_init_batched_get_presence()

	if IS_XBS or IS_GDK then
		self._load_buffer_in_flight = nil
		self._load_buffer_request_xbox_gamertag = {}
		self._load_buffer_request_xbox_gamertag_length = 0
		self._last_request_xbox_gamertag = 0
		self._loaded_xbox_gamertags = {}
	end
end

function PresenceManager:destroy()
end

function PresenceManager:presence()
	return self._myself:activity_id()
end

function PresenceManager:presence_entry_myself()
	return self._myself
end

function PresenceManager:set_party(party_id, num_party_members)
	self._myself:set_party_id(party_id)
	self._myself:set_num_party_members(num_party_members)
	self:_update_my_presence({
		party_id = true,
		num_party_members = true
	})

	if HAS_STEAM then
		Presence.advertise_immaterium_party(party_id)
	end

	if XboxLiveUtilities.available() then
		Managers.party_immaterium:get_your_standing_invite_code():next(function (party_id_with_invite_code)
			local num_mission_members = self._myself:num_mission_members()

			if num_mission_members > 0 then
				XboxLiveUtilities.set_activity(party_id_with_invite_code, party_id, num_mission_members - 1)
			else
				XboxLiveUtilities.set_activity(party_id_with_invite_code, party_id, num_party_members - 1)
			end
		end)
	end
end

function PresenceManager:set_num_mission_members(num_mission_members)
	self._myself:set_num_mission_members(num_mission_members)
	self:_update_my_presence({
		num_mission_members = true
	})

	if XboxLiveUtilities.available() then
		local party_id = self._myself:party_id()

		if party_id then
			Managers.party_immaterium:get_your_standing_invite_code():next(function (party_id_with_invite_code)
				if num_mission_members then
					XboxLiveUtilities.set_activity(party_id_with_invite_code, party_id, num_mission_members - 1)
				else
					XboxLiveUtilities.set_activity(party_id_with_invite_code, party_id, self._myself:num_party_members() - 1)
				end
			end)
		end
	end
end

function PresenceManager:set_character_profile(character_profile)
	self._myself:set_character_profile(character_profile)
	self:_update_my_presence({
		character_profile = true
	})
end

function PresenceManager:set_presence(activity_id)
	self._myself:set_activity_id(activity_id)
	self:_update_my_presence({
		activity_id = true
	})
end

function PresenceManager:get_presence(account_id)
	if account_id == gRPC.get_account_id() then
		local myself = self:presence_entry_myself()

		return myself, Promise.resolved(myself)
	end

	local presence_entry = self._presences_by_account_id[account_id]

	if not presence_entry then
		presence_entry = PresenceEntryImmaterium:new(self._myself:platform(), "", account_id)
		self._presences_by_account_id[account_id] = presence_entry

		presence_entry:start_stream()
	end

	return presence_entry, presence_entry:first_update_promise()
end

function PresenceManager:get_presence_by_platform(platform, platform_user_id)
	local platform_table = self._presences_by_platform_id[platform]

	if not platform_table then
		platform_table = {}
		self._presences_by_platform_id[platform] = platform_table
	end

	local presence_entry = platform_table[platform_user_id]

	if not presence_entry then
		presence_entry = PresenceEntryImmaterium:new(self._myself:platform(), platform, platform_user_id)
		platform_table[platform_user_id] = presence_entry

		presence_entry:start_stream()
	end

	return presence_entry, presence_entry:first_update_promise()
end

function PresenceManager:_init_immaterium_presence()
	local promise, id = Managers.grpc:start_presence(self._myself:create_key_values())
	self._immaterium_presence_operation_id = id

	promise:next(function ()
		self._immaterium_presence_operation_id = nil

		self:_init_immaterium_presence()
	end):catch(function (error)
		self._immaterium_presence_operation_id = nil

		if error.error_code == 10 then
			_info("Logged in from another location, sending fatal error...")
			Managers.error:report_error(LoggedInFromAnotherLocationError:new())
		else
			_error("Disconnected from presence - %s", table.tostring(error, 3))
			Managers.grpc:delay_with_jitter_and_backoff("my_presence_stream"):next(function ()
				self:_init_immaterium_presence()
			end)
		end
	end)
end

function PresenceManager:_init_batched_get_presence()
	local promise, id = Managers.grpc:get_batched_presence_stream()
	self._batched_get_presence_operation_id = id
	self._batched_get_presence_request_id_to_entry = {}

	promise:next(function ()
		self._batched_get_presence_operation_id = nil

		self:_init_batched_get_presence()
	end):catch(function (error)
		self._batched_get_presence_operation_id = nil

		_info("Disconnected from batched get presence - %s", table.tostring(error, 3))
		Managers.grpc:delay_with_jitter_and_backoff("batched_get_presence"):next(function ()
			self:_init_batched_get_presence()
		end)
	end)
end

function PresenceManager:_get_batched_presence(entry, platform, id)
	local operation_id = self._batched_get_presence_operation_id

	if not operation_id then
		return nil
	end

	local request_id = self._batched_get_presence_request_id_to_entry[entry]

	if not request_id then
		request_id = Managers.grpc:request_presence_from_batched_stream(operation_id, platform, id)
		self._batched_get_presence_request_id_to_entry[entry] = request_id
	end

	return Managers.grpc:get_latest_presence_from_batched_stream(operation_id, request_id)
end

function PresenceManager:_abort_batched_presence(entry)
	local operation_id = self._batched_get_presence_operation_id

	if not operation_id then
		return
	end

	local request_id = self._batched_get_presence_request_id_to_entry[entry]

	if request_id then
		Managers.grpc:abort_presence_from_batched_stream(operation_id, request_id)

		self._batched_get_presence_request_id_to_entry[entry] = nil
		self._batched_get_presence_request_id_to_entry = remove_empty_values(self._batched_get_presence_request_id_to_entry)
	end
end

function PresenceManager:_update_immaterium()
	local entry_remove = false

	for id, presence in pairs(self._presences_by_account_id) do
		if presence and not presence:reset_alive_queried() then
			presence:destroy()

			entry_remove = true
			self._presences_by_account_id[id] = nil
		end
	end

	if entry_remove then
		self._presences_by_account_id = remove_empty_values(self._presences_by_account_id)
	end

	for platform, platform_table in pairs(self._presences_by_platform_id) do
		entry_remove = false

		for id, presence in pairs(platform_table) do
			if presence and not presence:reset_alive_queried() then
				presence:destroy()

				entry_remove = true
				platform_table[id] = nil
			end
		end

		if entry_remove then
			self._presences_by_platform_id[platform] = remove_empty_values(platform_table)
		end
	end

	self._update_interval = PRESENCE_UPDATE_INTERVAL
end

function PresenceManager:_update_my_presence(...)
	if self._immaterium_presence_operation_id then
		Managers.grpc:update_presence(self._immaterium_presence_operation_id, self._myself:create_key_values(...))
	end
end

function PresenceManager:_run_update_on_entries()
	for id, presence in pairs(self._presences_by_account_id) do
		presence:update()
	end

	for platform, platform_table in pairs(self._presences_by_platform_id) do
		for id, presence in pairs(platform_table) do
			presence:update()
		end
	end
end

function PresenceManager:request_platform_username_async(platform, platform_user_id)
	if HAS_STEAM and platform == "steam" then
		Steam.request_user_name_async(platform_user_id)
	elseif (IS_XBS or IS_GDK) and platform == "xbox" then
		if self._load_buffer_in_flight and self._load_buffer_in_flight[platform_user_id] then
			return
		end

		if self._loaded_xbox_gamertags[platform_user_id] or self._load_buffer_request_xbox_gamertag[platform_user_id] then
			return
		end

		self._load_buffer_request_xbox_gamertag[platform_user_id] = true
		self._load_buffer_request_xbox_gamertag_length = self._load_buffer_request_xbox_gamertag_length + 1
	end
end

function PresenceManager:get_requested_platform_username(platform, platform_user_id)
	if HAS_STEAM and platform == "steam" then
		return Steam.user_name(platform_user_id)
	elseif (IS_XBS or IS_GDK) and platform == "xbox" then
		return self._loaded_xbox_gamertags[platform_user_id]
	end
end

function PresenceManager:update(dt, t)
	self._character_name_update_interval = self._character_name_update_interval - dt

	if self._character_name_update_interval <= 0 then
		local profile = Managers.player:local_player_backend_profile()
		self._character_name_update_interval = 1
		local prev_character_profile = self._myself:character_profile()

		if profile and (not prev_character_profile or prev_character_profile ~= profile) then
			self:set_character_profile(profile)
		end
	end

	self._update_interval = self._update_interval - dt

	if self._update_interval <= 0 then
		self:_update_immaterium()
	end

	self:_run_update_on_entries()

	if self._immaterium_presence_operation_id then
		local push_messages = Managers.grpc:get_push_messages(self._immaterium_presence_operation_id)

		if push_messages then
			for i, push_message in ipairs(push_messages) do
				_info("received push message=%s", table.tostring(push_message, 3))

				if push_message.type == "event_trigger" then
					local payload = cjson.decode(push_message.payload)

					Managers.event:trigger("backend_" .. payload.event_name, unpack(payload.args))
				end
			end
		end
	end

	if self._load_buffer_request_xbox_gamertag_length and self._load_buffer_request_xbox_gamertag_length > 0 then
		self._last_request_xbox_gamertag = self._last_request_xbox_gamertag + dt

		if self._last_request_xbox_gamertag > 0.2 then
			local buffer = {}
			self._load_buffer_in_flight = {}

			for id, _ in pairs(self._load_buffer_request_xbox_gamertag) do
				table.insert(buffer, id)

				self._load_buffer_in_flight[id] = true
			end

			self._load_buffer_request_xbox_gamertag_length = 0
			self._load_buffer_request_xbox_gamertag = {}

			Log.info("PresenceManager", "Doing batched call to get_user_profiles with %s xuids", tostring(#buffer))
			XboxLiveUtilities.get_user_profiles(buffer):next(function (profiles)
				self._load_buffer_in_flight = nil

				for i, profile in ipairs(profiles) do
					self._loaded_xbox_gamertags[profile.xuid] = profile.gamertag
				end
			end):catch(function (error)
				self._load_buffer_in_flight = nil

				_error("error when getting gamertags for xuids", table.tostring(buffer, 2))

				self._last_request_xbox_gamertag = -10
			end)

			self._last_request_xbox_gamertag = 0
		end
	end
end

implements(PresenceManager, PresenceManagerInterface)

return PresenceManager
