local ChatManagerInterface = require("scripts/foundation/managers/chat/chat_manager_interface")
local ChatManagerConstants = require("scripts/foundation/managers/chat/chat_manager_constants")
local PrivilegesManager = require("scripts/managers/privileges/privileges_manager")
local VivoxManager = class("VivoxManager")
local SOUND_SETTING_OPTIONS_VOICE_CHAT = table.enum("muted", "voice_activated", "push_to_talk")

local function _sound_setting_option_voice_chat()
	if Application.user_setting and Application.user_setting("sound_settings") and Application.user_setting("sound_settings").voice_chat then
		local option = Application.user_setting and Application.user_setting("sound_settings") and Application.user_setting("sound_settings").voice_chat

		if option == 0 then
			return SOUND_SETTING_OPTIONS_VOICE_CHAT.muted
		elseif option == 1 then
			return SOUND_SETTING_OPTIONS_VOICE_CHAT.voice_activated
		elseif option == 2 then
			return SOUND_SETTING_OPTIONS_VOICE_CHAT.push_to_talk
		end
	end

	return SOUND_SETTING_OPTIONS_VOICE_CHAT.muted
end

function VivoxManager:init()
	self._initialized = false
	self._mute_list_has_changes = false
	self._account_handle = nil
	self._privileges_manager = nil
	self._sessions = {}
	self._join_queue = {}
	self._channel_tags = {}
	self._channel_host_peer_id = {}
	self._input_service = Managers.input:get_input_service("Ingame")
	self._time_since_mute_local_mic = nil
	self._delayed_participants_added = {}

	Managers.event:register(self, "player_mute_status_changed", "player_mute_status_changed")
end

function VivoxManager:destroy()
	Managers.event:unregister(self, "player_mute_status_changed")
end

function VivoxManager:split_displayname(input)
	if not input then
		return nil
	end

	local parts = string.split(input, "|")

	if #parts == 2 then
		return parts[1], parts[2]
	else
		return nil
	end
end

function VivoxManager:peer_id_from_session_handle(session_handle)
	return self._channel_host_peer_id[session_handle]
end

function VivoxManager:tag_from_session_handle(session_handle)
	return self._channel_tags[session_handle]
end

function VivoxManager:initialize()
	if rawget(_G, "Vivox") then
		local verbose_chat_log = false

		if Vivox.initialize(verbose_chat_log) then
			self._initialized = true
			self._privileges_manager = PrivilegesManager:new()

			Managers.backend:authenticate():next(function (auth_data)
				local domain = auth_data.vivox_domain
				local issuer = auth_data.vivox_issuer

				Vivox.create_connector(domain, issuer)
			end):catch(function (error)
				Log.error("VivoxManager", "Could not create connector: " .. tostring(error))
			end)
		end
	else
		Log.error("VivoxManager", "Vivox not available")
	end
end

function VivoxManager:is_initialized()
	return self._initialized
end

function VivoxManager:connection_state()
	return self._connection_state
end

function VivoxManager:is_connected()
	return self._connection_state == ChatManagerConstants.ConnectionState.CONNECTED or self._connection_state == ChatManagerConstants.ConnectionState.RECOVERED
end

function VivoxManager:login_state()
	return self._login_state
end

function VivoxManager:is_logged_in()
	return self:login_state() == ChatManagerConstants.LoginState.LOGGED_IN and self._account_handle ~= nil
end

function VivoxManager:login(peer_id, account_id, vivox_token)
	if not self._login_state or self._login_state == ChatManagerConstants.LoginState.LOGGED_OUT then
		if not peer_id then
			Log.warning("VivoxManager", "Could not login: missing peer_id.")

			return
		end

		if not account_id then
			Log.warning("VivoxManager", "Could not login: missing account_id.")

			return
		end

		if type(vivox_token) ~= "string" or #vivox_token <= 0 then
			Log.error("VivoxManager", "Could not login: missing vivox_token.")

			return
		end

		local login_name = string.format("%s|%s", peer_id, account_id)

		Vivox.login_with_access_token(login_name, account_id, vivox_token)
	else
		Log.warning("VivoxManager", "Already logged in.")
	end
end

function VivoxManager:join_chat_channel(channel, host_peer_id, voice, tag, vivox_token)
	if not self:is_logged_in() then
		return
	end

	self._privileges_manager:communications_privilege(false):next(function (results)
		if results.has_privilege == true then
			self._channel_tags[channel] = tag
			self._channel_host_peer_id[channel] = host_peer_id

			if self:is_logged_in() then
				Vivox.add_channel_session(self._account_handle, channel, true, voice, vivox_token)
			else
				table.insert(self._join_queue, {
					channel,
					true,
					voice,
					vivox_token
				})
			end
		else
			local error = string.format("Communications privilege denied: %s", results.deny_reason or "Unknown reason")

			Log.error("VivoxManager", "Error joining channel %s: %s", channel, error)
		end
	end):catch(function (error)
		Log.error("VivoxManager", "Error joining channel %s: %s", channel, error)
	end)
end

function VivoxManager:leave_channel(channel_handle)
	if self:is_logged_in() then
		Vivox.remove_session(channel_handle)

		self._sessions[channel_handle] = nil
		self._channel_tags[channel_handle] = nil
		self._channel_host_peer_id[channel_handle] = nil
	end
end

function VivoxManager:connected_chat_channels()
	local channels = {}

	for channel_handle, channel in pairs(self._sessions) do
		local session_text_state = channel.session_text_state

		if session_text_state and session_text_state == ChatManagerConstants.ChannelConnectionState.CONNECTED then
			channels[channel_handle] = channel
		end
	end

	return channels
end

function VivoxManager:connected_voip_channels()
	local channels = {}

	for channel_handle, channel in pairs(self._sessions) do
		local session_media_state = channel.session_media_state

		if session_media_state and session_media_state == ChatManagerConstants.ChannelConnectionState.CONNECTED then
			channels[channel_handle] = channel
		end
	end

	return channels
end

local function _update_local_render_volume(session_handle)
	local volume = 50

	if Application.user_setting and Application.user_setting("sound_settings") and Application.user_setting("sound_settings").options_voip_volume_slider ~= nil then
		local voip_volume = Application.user_setting("sound_settings").options_voip_volume_slider
		volume = voip_volume <= 0.01 and 0 or math.lerp(30, 60, voip_volume / 100)
	end

	Vivox.session_set_local_render_volume(session_handle, volume)
end

function VivoxManager:mic_volume_changed()
	for session_handle, channel in pairs(self._sessions) do
		_update_local_render_volume(session_handle)
	end
end

function VivoxManager:send_channel_message(channel_handle, message_body)
	Managers.telemetry_events:chat_message_sent(message_body)
	Vivox.send_session_message(channel_handle, message_body)
end

function VivoxManager:update(dt, t)
	if self._privileges_manager then
		self._privileges_manager:update(dt, t)
	end

	if self._time_since_mute_local_mic ~= nil then
		self._time_since_mute_local_mic = self._time_since_mute_local_mic + dt

		if self._time_since_mute_local_mic >= 0.5 then
			Vivox.get_local_audio_info()

			self._time_since_mute_local_mic = nil
		end
	end

	local muted_setting = _sound_setting_option_voice_chat()

	if muted_setting == SOUND_SETTING_OPTIONS_VOICE_CHAT.push_to_talk then
		local should_mute = true

		if self._input_service and self._input_service:get("voip_push_to_talk") then
			should_mute = false
		end

		if self._local_audio_info and self._local_audio_info.is_mic_muted ~= should_mute then
			self:mute_local_mic(should_mute)
		end
	end

	if not self._last_update then
		self._last_update = 0
	else
		self._last_update = self._last_update + dt
	end

	if self._last_update > 0.1 then
		self._last_update = 0

		if self._initialized then
			if self._mute_list_has_changes then
				self._mute_list_has_changes = false

				self:_update_mute_status()
			end

			local message = Vivox.get_message()

			if message then
				if message.type == Vivox.MessageType_EVENT then
					self:_handle_event(message)
				elseif message.type == Vivox.MessageType_RESPONSE then
					self:_handle_response(message)
				end
			end
		end

		for channel_handle, participants in pairs(self._delayed_participants_added) do
			local finalized_participants = {}

			for i, participant in ipairs(participants) do
				if participant.player_info then
					local displayname = self:_displayname_in_channel(participant, channel_handle)

					if displayname then
						participant.displayname = displayname
						participant.displayname_set = true

						table.insert(finalized_participants, i)
					end
				end
			end

			table.reverse(finalized_participants)

			for _, index in ipairs(finalized_participants) do
				local participant = participants[index]

				Managers.event:trigger("chat_manager_participant_added", channel_handle, participant)
				table.remove(participants, index)
			end
		end
	end
end

function VivoxManager:_displayname_in_channel(participant, channel_handle)
	if not participant.player_info then
		return nil
	end

	local tag = self:tag_from_session_handle(channel_handle)

	if tag == ChatManagerConstants.ChannelTag.HUB or ChatManagerConstants.ChannelTag.MISSION then
		local displayname = participant.player_info:character_name()

		if displayname and displayname ~= "" and displayname ~= "N/A" then
			return displayname
		end
	else
		local displayname = participant.player_info:user_display_name()

		if displayname and displayname ~= "" and displayname ~= "N/A" then
			return displayname
		end
	end

	return nil
end

local function login_state_enum(vx_login_state_change_state)
	if vx_login_state_change_state == 0 then
		return ChatManagerConstants.LoginState.LOGGED_OUT
	elseif vx_login_state_change_state == 1 then
		return ChatManagerConstants.LoginState.LOGGED_IN
	elseif vx_login_state_change_state == 2 then
		return ChatManagerConstants.LoginState.LOGGING_IN
	elseif vx_login_state_change_state == 3 then
		return ChatManagerConstants.LoginState.LOGGING_OUT
	elseif vx_login_state_change_state == 4 then
		return ChatManagerConstants.LoginState.RESETTING
	else
		return ChatManagerConstants.LoginState.ERROR
	end
end

local function session_text_state_enum(vx_session_text_state)
	if vx_session_text_state == 0 then
		return ChatManagerConstants.ChannelConnectionState.DISCONNECTED
	elseif vx_session_text_state == 1 then
		return ChatManagerConstants.ChannelConnectionState.CONNECTED
	elseif vx_session_text_state == 2 then
		return ChatManagerConstants.ChannelConnectionState.CONNECTING
	elseif vx_session_text_state == 3 then
		return ChatManagerConstants.ChannelConnectionState.DISCONNECTING
	else
		return nil
	end
end

local function session_media_state_enum(vx_session_media_state)
	if vx_session_media_state == 1 then
		return ChatManagerConstants.ChannelConnectionState.DISCONNECTED
	elseif vx_session_media_state == 2 then
		return ChatManagerConstants.ChannelConnectionState.CONNECTED
	elseif vx_session_media_state == 3 then
		return ChatManagerConstants.ChannelConnectionState.RINGING
	elseif vx_session_media_state == 6 then
		return ChatManagerConstants.ChannelConnectionState.CONNECTING
	elseif vx_session_media_state == 7 then
		return ChatManagerConstants.ChannelConnectionState.DISCONNECTING
	else
		return nil
	end
end

local function connection_state_enum(vx_connection_state)
	if vx_connection_state == 0 then
		return ChatManagerConstants.ConnectionState.DISCONNECTED
	elseif vx_connection_state == 1 then
		return ChatManagerConstants.ConnectionState.CONNECTED
	elseif vx_connection_state == 3 then
		return ChatManagerConstants.ConnectionState.RECOVERING
	elseif vx_connection_state == 4 then
		return ChatManagerConstants.ConnectionState.FAILED_TO_RECOVER
	elseif vx_connection_state == 5 then
		return ChatManagerConstants.ConnectionState.RECOVERED
	else
		return nil
	end
end

function VivoxManager:is_mic_muted()
	return self:is_connected() and self._local_audio_info and self._local_audio_info.is_mic_muted
end

function VivoxManager:mute_local_mic(mute)
	if not self:is_connected() then
		return
	end

	Vivox.mute_local_mic(mute)

	if self._local_audio_info then
		self._local_audio_info.is_mic_muted = mute
	end

	self._time_since_mute_local_mic = 0
end

function VivoxManager:channel_text_mute_participant(channel_handle, participant_uri, mute)
	Vivox.text_session_set_participant_mute_for_me(channel_handle, participant_uri, mute)
end

function VivoxManager:channel_voip_mute_participant(channel_handle, participant_uri, mute)
	Vivox.audio_session_set_participant_mute_for_me(channel_handle, participant_uri, mute)
end

function VivoxManager:player_mute_status_changed()
	self._mute_list_has_changes = true
end

function VivoxManager:_handle_event(message)
	if message.event == Vivox.EventType_LOGIN_STATE_CHANGE then
		local state = login_state_enum(message.state)
		self._login_state = state

		Managers.event:trigger("chat_manager_login_state_change", state)

		if state == ChatManagerConstants.LoginState.LOGGED_IN then
			for _, queued_channel in ipairs(self._join_queue) do
				local channel = queued_channel[1]
				local text = queued_channel[2]
				local voice = queued_channel[3]
				local vivox_token = queued_channel[4]

				Vivox.add_channel_session(self._account_handle, channel, text, voice, vivox_token)
			end

			Vivox.get_local_audio_info()

			local muted_setting = _sound_setting_option_voice_chat()

			if muted_setting == SOUND_SETTING_OPTIONS_VOICE_CHAT.voice_activated then
				self:mute_local_mic(false)
			else
				self:mute_local_mic(true)
			end
		end
	elseif message.event == Vivox.EventType_CONNECTION_STATE_CHANGE then
		local state = connection_state_enum(message.state)

		if self._connection_state ~= state then
			self._connection_state = state

			Managers.event:trigger("chat_manager_connection_state_change", state)
		end
	elseif message.event == Vivox.EventType_SESSION_ADDED then
		local tag = self:tag_from_session_handle(message.session_handle)
		local session = {
			participants = {},
			is_channel = message.is_channel,
			session_handle = message.session_handle,
			name = message.name,
			tag = tag
		}
		self._sessions[message.session_handle] = session

		Managers.event:trigger("chat_manager_added_channel", message.session_handle, session)
	elseif message.event == Vivox.EventType_SESSION_REMOVED then
		self._sessions[message.session_handle] = nil
		self._delayed_participants_added[message.session_handle] = nil

		Managers.event:trigger("chat_manager_removed_channel", message.session_handle)
	elseif message.event == Vivox.EventType_TEXT_STREAM_UPDATED then
		local state = session_text_state_enum(message.session_text_state)

		if self._sessions[message.session_handle] then
			self._sessions[message.session_handle].session_text_state = state

			Managers.event:trigger("chat_manager_updated_channel_state", message.session_handle, state)
		end
	elseif message.event == Vivox.EventType_MEDIA_STREAM_UPDATED then
		local state = session_media_state_enum(message.session_media_state)

		if self._sessions[message.session_handle] then
			self._sessions[message.session_handle].session_media_state = state
			self._sessions[message.session_handle].incoming = message.incoming

			Managers.event:trigger("voip_manager_updated_channel_state", message.session_handle, state, message.incoming)
		end

		if state == ChatManagerConstants.ChannelConnectionState.CONNECTED then
			Vivox.get_local_audio_info()
			_update_local_render_volume(message.session_handle)
		end
	elseif message.event == Vivox.EventType_MESSAGE then
		if not self._sessions[message.session_handle] then
			return
		end

		local participant = self._sessions[message.session_handle].participants[message.participant_uri]

		if participant.is_mute_status_set == true then
			if participant.displayname_set ~= true and participant.player_info then
				local displayname = self:_displayname_in_channel(participant, message.session_handle)

				if displayname then
					participant.displayname = displayname
					participant.displayname_set = true
				end
			end

			if participant.displayname_set == true then
				Managers.event:trigger("chat_manager_message_recieved", message.session_handle, participant, message)
			end
		end
	elseif message.event == Vivox.EventType_PARTICIPANT_ADDED then
		if not self._sessions[message.session_handle] then
			return
		end

		local peer_id, account_id = self:split_displayname(message.displayname)
		local participant = {
			is_speaking = false,
			displayname_set = false,
			is_muted_for_me = false,
			is_moderator_muted = false,
			is_text_muted_for_me = false,
			is_moderator_text_muted = false,
			is_mute_status_set = false,
			account_name = message.account_name,
			participant_uri = message.participant_uri,
			packed_displayname = message.displayname,
			peer_id = peer_id,
			account_id = account_id,
			is_current_user = message.is_current_user
		}
		self._sessions[message.session_handle].participants[message.participant_uri] = participant
		self._mute_list_has_changes = true

		if not self._delayed_participants_added[message.session_handle] then
			self._delayed_participants_added[message.session_handle] = {}
		end

		table.insert(self._delayed_participants_added[message.session_handle], participant)
		Managers.account:refresh_communcation_restrictions()
	elseif message.event == Vivox.EventType_PARTICIPANT_UPDATED then
		if not self._sessions[message.session_handle] then
			return
		end

		local participant = self._sessions[message.session_handle].participants[message.participant_uri]
		participant.is_speaking = message.is_speaking
		participant.is_moderator_muted = message.is_moderator_muted
		participant.is_moderator_text_muted = message.is_moderator_text_muted
		participant.is_muted_for_me = message.is_muted_for_me
		participant.is_text_muted_for_me = message.is_text_muted_for_me

		Managers.event:trigger("chat_manager_participant_update", message.session_handle, participant)
	elseif message.event == Vivox.EventType_PARTICIPANT_REMOVED then
		if not self._sessions[message.session_handle] then
			return
		end

		local session = self._sessions[message.session_handle]
		local participant = session.participants[message.participant_uri]
		session.participants[message.participant_uri] = nil

		if self._delayed_participants_added[message.session_handle] then
			local found = nil

			for i, p in ipairs(self._delayed_participants_added[message.session_handle]) do
				if p == message.participant_uri then
					found = i

					break
				end
			end

			if found then
				table.remove(self._delayed_participants_added[message.session_handle], i)
			end
		end

		Managers.event:trigger("chat_manager_participant_removed", message.session_handle, message.participant_uri, participant)
	end
end

function VivoxManager:_handle_response(message)
	if message.response == Vivox.ResponseType_CONNECTOR_CREATE then
		if self._connection_state ~= ChatManagerConstants.ChannelConnectionState.CONNECTED then
			self._connection_state = ChatManagerConstants.ChannelConnectionState.CONNECTED

			Managers.event:trigger("chat_manager_connection_state_change", self._connection_state)
		end
	elseif message.response == Vivox.ResponseType_ACCOUNT_ANONYMOUS_LOGIN then
		self._account_handle = message.account_handle
	elseif message.response == Vivox.ResponseType_GET_LOCAL_AUDIO_INFO then
		if self._local_audio_info and self._local_audio_info.is_mic_muted ~= message.is_mic_muted then
			local assumed_muted = self._local_audio_info.is_mic_muted and "muted" or "unmuted"
			local got_muted = message.is_mic_muted and "muted" or "unmuted"

			Log.warning("VivoxManager", "Assumed our local mic was %s but local audio info says it was %s.", assumed_muted, got_muted)
			self:mute_local_mic(message.is_mic_muted)
		end

		self._local_audio_info = {
			is_mic_muted = message.is_mic_muted,
			is_speaker_muted = message.is_speaker_muted,
			mic_volume = message.mic_volume,
			speaker_volume = message.speaker_volume
		}
	end
end

function VivoxManager:_update_mute_status()
	for channel_handle, channel in pairs(self._sessions) do
		local tag = self:tag_from_session_handle(channel_handle)
		local player_promise = nil

		if tag == ChatManagerConstants.ChannelTag.HUB then
			player_promise = Managers.data_service.social:fetch_players_on_server()
		elseif tag == ChatManagerConstants.ChannelTag.MISSION then
			player_promise = Managers.data_service.social:fetch_party_members()
		elseif tag == ChatManagerConstants.ChannelTag.PARTY then
			player_promise = Managers.data_service.social:fetch_party_members()
		else
			Log.error("VivoxManager", "Unsupported channel tag %s", tostring(tag))

			local channel_participants = channel.participants

			for participant_uri, participant in pairs(channel_participants) do
				participant.is_text_muted_for_me = true
				participant.is_muted_for_me = true

				self:channel_text_mute_participant(participant_uri, true)
				self:channel_voip_mute_participant(channel_handle, participant_uri, true)
			end
		end

		if player_promise then
			player_promise:next(function (player_infos)
				local channel_participants = channel.participants

				self:_update_mute_status_for_participants(channel_handle, channel_participants, player_infos)
			end)
		end
	end
end

local _participants_by_account_id = {}

function VivoxManager:_update_mute_status_for_participants(channel_handle, participants, player_infos)
	local participants_by_account_id = _participants_by_account_id
	local my_platform = Managers.data_service.social:platform()

	table.clear(participants_by_account_id)

	for _, participant in pairs(participants) do
		participant.is_mute_status_set = false
		local account_id = participant.account_id

		if account_id then
			participants_by_account_id[account_id] = participant
		elseif not participant.is_muted_for_me then
			Log.warning("VivoxManager", "Participant %s missing account_id.", participant.participant_uri)

			participant.is_text_muted_for_me = true
			participant.is_muted_for_me = true

			self:channel_voip_mute_participant(channel_handle, participant.participant_uri, true)
		end
	end

	for _, player_info in pairs(player_infos) do
		local account_id = player_info:account_id()
		local participant = account_id and participants_by_account_id[account_id]

		if participant and participant.is_current_user then
			participant.player_info = player_info
			local displayname = self:_displayname_in_channel(participant, channel_handle)

			if displayname then
				participant.displayname = displayname
				participant.displayname_set = true
			end

			participant.player_info = player_info
			participant.is_mute_status_set = true

			if participant.is_mute_status_set and not participant.has_notified_participant_added then
				Managers.event:trigger("chat_manager_participant_added", channel_handle, participant)
			end
		elseif participant then
			participant.player_info = player_info
			local text_mute = player_info:is_text_muted()
			local voice_mute = player_info:is_voice_muted()
			local displayname = self:_displayname_in_channel(participant, channel_handle)

			if IS_GDK or IS_XBS then
				local platform = player_info:platform()
				local platform_user_id = player_info:platform_user_id()

				if platform ~= my_platform then
					local relation = player_info:is_friend() and XblAnonymousUserType.CrossNetworkFriend or XblAnonymousUserType.CrossNetworkUser
					text_mute = Managers.account:has_crossplay_restriction(relation, XblPermission.CommunicateUsingText) or text_mute
					voice_mute = Managers.account:has_crossplay_restriction(relation, XblPermission.CommunicateUsingVoice) or voice_mute
				else
					local platform_muted = Managers.account:is_muted(platform_user_id)
					text_mute = platform_muted or text_mute
					voice_mute = platform_muted or voice_mute

					if not Managers.account:user_restriction_verified(platform_user_id, XblPermission.CommunicateUsingVoice) then
						Managers.account:verify_user_restriction(platform_user_id, XblPermission.CommunicateUsingVoice)
					end
				end
			end

			if text_mute ~= participant.is_text_muted_for_me then
				self:channel_text_mute_participant(channel_handle, participant.participant_uri, text_mute)
			end

			if voice_mute ~= participant.is_muted_for_me then
				self:channel_voip_mute_participant(channel_handle, participant.participant_uri, voice_mute)
			end

			if displayname then
				participant.displayname = displayname
				participant.displayname_set = true
			end

			participant.is_mute_status_set = true
		end
	end
end

implements(VivoxManager, ChatManagerInterface)

return VivoxManager
