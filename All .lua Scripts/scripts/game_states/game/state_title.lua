local MainMenuLoader = require("scripts/loading/loaders/main_menu_loader")
local SigninLoader = require("scripts/loading/loaders/signin_loader")
local HumanPlayer = require("scripts/managers/player/human_player")
local StateMainMenu = require("scripts/game_states/game/state_main_menu")
local PlayerManager = require("scripts/foundation/managers/player/player_manager")
local SteamOfflineError = require("scripts/managers/error/errors/steam_offline_error")
local Promise = require("scripts/foundation/utilities/promise")
local StateTitle = class("StateTitle")
local STATES = table.enum("idle", "account_signin", "signing_in", "loading_packages", "authenticating_eos", "legal_verification", "done", "error")

local function _should_skip()
	if IS_XBS and BUILD == "release" then
		return false
	end

	local skip_title = LEVEL_EDITOR_TEST or GameParameters.mission or Managers.data_service.social:has_invite() or not Managers.ui

	return skip_title
end

local function _create_player(account_id, selected_profile)
	local local_player_id = 1
	local local_player = Managers.player:local_player(local_player_id)

	if not local_player then
		local telemetry_game_session = Managers.telemetry_events._session.game
		local slot = 0
		local_player = Managers.player:add_human_player(HumanPlayer, nil, Network.peer_id(), local_player_id, selected_profile, slot, account_id, "player1", telemetry_game_session)

		Managers.telemetry_events:local_player_spawned(local_player)
	end

	return local_player
end

function StateTitle:_check_start_requirements(is_booting)
	local can_continue = true

	if HAS_STEAM and not Steam.connected() then
		local err = SteamOfflineError:new(is_booting)

		Managers.error:report_error(err)

		can_continue = err:level() < Managers.error.ERROR_LEVEL.error
	end

	return can_continue
end

function StateTitle:on_enter(parent, params, creation_context)
	self._creation_context = creation_context
	self._next_state = StateMainMenu
	self._next_state_params = params
	self._is_booting = params.is_booting or false
	self._auth_queue_position = nil
	self._queue_update_time = 0
	self._queue_changed = false
	self._state = STATES.idle

	if self._is_booting and not self:_check_start_requirements(true) then
		return
	end

	Managers.account:reset()

	if IS_XBS then
		Managers.save:reset()
	end

	if _should_skip() then
		if IS_XBS or IS_GDK then
			local raw_input_device = nil

			if IS_XBS then
				raw_input_device = not GameParameters.testify and raw_input_device
			end

			self:_signin_profile(raw_input_device)
		else
			self:_signin()
		end
	else
		local context = {
			parent = self
		}
		local view_name = "title_view"

		Managers.ui:open_view(view_name, nil, , , , context)
		Managers.event:register(self, "event_state_title_continue", "_continue_cb")
	end

	Managers.presence:set_presence("title_screen")
end

function StateTitle:_set_state(state)
	Log.info("StateTitle", "Changing state %s -> %s", self._state, state)

	self._state = state
end

function StateTitle:state()
	return self._state
end

function StateTitle:_continue_cb(optional_input_device)
	Managers.event:unregister(self, "event_state_title_continue")

	if IS_XBS or IS_GDK then
		self:_signin_profile(optional_input_device)
	else
		self:_signin()
	end
end

function StateTitle:_signin_profile(optional_input_device)
	self:_set_state(STATES.account_signin)
	Managers.account:signin_profile(callback(self, "cb_profile_signed_in"), optional_input_device)
end

function StateTitle:cb_profile_signed_in()
	self:_signin()
end

local queue_loc_table = {}

function StateTitle:is_loading()
	local state = self._state
	local states = STATES

	if self._auth_queue_position and self._auth_queue_position > 0 then
		if self._queue_changed then
			queue_loc_table.position = self._auth_queue_position
		end

		return true, self._queue_changed, "loc_state_title_authenticating_queue", true, queue_loc_table
	elseif state == states.account_signin then
		return true, false, "loc_title_screen_signing_in"
	elseif state == states.signing_in then
		return true, false, "loc_title_screen_signing_in"
	elseif state == states.loading_packages then
		return true, false, "loc_title_screen_signing_in"
	elseif state == states.authenticating_eos then
		return true, false, "loc_title_screen_signing_in"
	end

	return false
end

function StateTitle:_legal_verification()
	self:_set_state(STATES.legal_verification)

	local legal_promises = {
		Managers.backend.interfaces.account:get_data("legal", "eula"),
		Managers.backend.interfaces.account:get_data("legal", "privacy_policy")
	}

	Promise.all(unpack(legal_promises)):next(function (results)
		local eula_status, privacy_policy_status = unpack(results, 1, 2)

		if not privacy_policy_status then
			local options = {}

			if IS_XBS then
				options[#options + 1] = {
					text = "loc_privacy_policy_privacy_url",
					template_type = "text",
					margin_bottom = 20
				}
			else
				options[#options + 1] = {
					text = "loc_privacy_policy_read_privacy_policy",
					template_type = "url_button",
					margin_bottom = 20,
					callback = function ()
						Application.open_url_in_browser(Localize("loc_privacy_policy_privacy_url"))
					end
				}
			end

			options[#options + 1] = {
				text = "loc_privacy_policy_accept_button_label",
				close_on_pressed = true,
				callback = function ()
					Managers.backend.interfaces.account:set_data("legal", {
						privacy_policy = privacy_policy_status and privacy_policy_status + 1 or 1
					}):next(function ()
						self:_legal_verification()
					end)
				end
			}
			options[#options + 1] = {
				close_on_pressed = true,
				hotkey = "back",
				text = PLATFORM == "win32" and "loc_privacy_policy_decline_button_label" or "loc_privacy_policy_decline_button_console_label",
				callback = function ()
					if PLATFORM == "win32" then
						Application.quit()
					else
						self:_reset_state()
					end
				end
			}
			local context = {
				title_text = "loc_privacy_policy_title",
				description_text = "loc_privacy_policy_information_01b",
				options = options
			}

			Managers.event:trigger("event_show_ui_popup", context)
		elseif not eula_status and (not HAS_STEAM or not Steam.connected()) then
			local options = {}

			if IS_XBS then
				options[#options + 1] = {
					text = "loc_privacy_policy_eula_url",
					template_type = "text",
					margin_bottom = 20
				}
			else
				options[#options + 1] = {
					text = "loc_privacy_policy_read_eula",
					template_type = "url_button",
					margin_bottom = 20,
					callback = function ()
						Application.open_url_in_browser(Localize("loc_privacy_policy_eula_url"))
					end
				}
			end

			options[#options + 1] = {
				text = "loc_privacy_policy_accept_eula_button_label",
				close_on_pressed = true,
				callback = function ()
					Managers.backend.interfaces.account:set_data("legal", {
						eula = eula_status and eula_status + 1 or 1
					}):next(function ()
						self:_legal_verification()
					end)
				end
			}
			options[#options + 1] = {
				close_on_pressed = true,
				hotkey = "back",
				text = PLATFORM == "win32" and "loc_privacy_policy_decline_button_label" or "loc_privacy_policy_decline_button_console_label",
				callback = function ()
					if PLATFORM == "win32" then
						Application.quit()
					else
						self:_reset_state()
					end
				end
			}
			local context = {
				title_text = "loc_eula_title",
				description_text = "loc_privacy_policy_information_01c",
				options = options
			}

			Managers.event:trigger("event_show_ui_popup", context)
		else
			self:_set_state(STATES.done)
		end
	end):catch(function (error)
		self:_on_error()
	end)
end

function StateTitle:_on_error()
	self:_set_state(STATES.error)
	Managers.error:show_errors():next(function ()
		self:_reset_state()
	end)
end

function StateTitle:_reset_state()
	local next_state_params = self._next_state_params

	if next_state_params.main_menu_loader then
		next_state_params.main_menu_loader:delete()

		next_state_params.main_menu_loader = nil
	end

	next_state_params.profiles = nil
	next_state_params.selected_profile = nil
	next_state_params.has_created_first_character = nil

	if self._narrative_promise and self._narrative_promise:is_pending() then
		self._narrative_promise:cancel()

		self._narrative_promise = nil
	end

	self:_set_state(STATES.idle)
	Managers.event:register(self, "event_state_title_continue", "_continue_cb")
	Managers.event:trigger("event_state_title_reset")
	Managers.account:reset()

	if IS_XBS then
		Managers.save:reset()
	end
end

function StateTitle:update(main_dt, main_t)
	local context = self._creation_context

	context.network_receive_function(main_dt)
	context.network_transmit_function()

	local state = self._state
	local states = STATES

	if state == states.error then
		return
	end

	local error_state, _ = Managers.error:wanted_transition()

	if error_state then
		self:_on_error()

		return
	elseif IS_XBS or IS_GDK then
		local error_state, error_state_params = Managers.account:wanted_transition()

		if error_state then
			error_state_params.is_booting = self._is_booting

			return error_state, error_state_params
		end
	end

	if state == states.idle then
		return
	elseif state == states.account_signin then
		self:_update_queue_position(main_t)
		Managers.ui:render_loading_icon()
		Managers.ui:render_black_background()
	elseif state == states.signing_in then
		self:_update_queue_position(main_t)
		Managers.ui:render_loading_icon()
		Managers.ui:render_black_background()
	elseif state == states.legal_verification then
		self:_update_queue_position(main_t)
		Managers.ui:render_loading_icon()
		Managers.ui:render_black_background()
	elseif state == states.loading_packages then
		Managers.ui:render_loading_icon()
		Managers.ui:render_black_background()

		local loading_done = true

		if self._signin_loader and not self._signin_loader:is_loading_done() then
			loading_done = false
		end

		local main_menu_loader = self._next_state_params.main_menu_loader

		if main_menu_loader and not main_menu_loader:is_loading_done() then
			loading_done = false
		end

		if self._narrative_promise and not self._narrative_promise:is_fulfilled() then
			loading_done = false
		end

		if loading_done then
			local has_eac = false

			if has_eac then
				self:_set_state(states.authenticating_eos)
			else
				self:_legal_verification()
			end
		end
	elseif state == states.authenticating_eos then
		Managers.ui:render_loading_icon()

		local authenticated = Managers.eac_client:authenticated()

		if authenticated then
			self:_legal_verification()
		end
	elseif state == states.done then
		return self._next_state, self._next_state_params
	end
end

local UPDATE_QUEUE_POSITION_INTERVAL = 5

function StateTitle:_update_queue_position(main_t)
	self._queue_changed = false

	if self._queue_update_time <= main_t then
		self._auth_queue_position = Backend.get_auth_queue_position()
		self._queue_update_time = main_t + UPDATE_QUEUE_POSITION_INTERVAL
		self._queue_changed = true
	end
end

function StateTitle:on_exit()
	local view_name = "title_view"
	local ui_manager = Managers.ui

	if ui_manager then
		local leaving_game = Managers.account:leaving_game()

		if leaving_game then
			local active_views = ui_manager:active_views()
			local force_close = true

			while not table.is_empty(active_views) do
				local view_name = active_views[1]

				ui_manager:close_view(view_name, force_close)
			end
		elseif ui_manager:view_active(view_name) then
			ui_manager:close_view(view_name)
		end
	end

	Managers.event:unregister(self, "event_state_title_continue")
end

function StateTitle:_signin()
	if not self:_check_start_requirements(false) then
		return
	end

	self:_set_state(STATES.signing_in)

	if self._is_booting then
		self._signin_loader = SigninLoader:new()

		self._signin_loader:start_loading()

		self._is_booting = false
	end

	local has_eac = false

	if has_eac then
		Log.info("StateTitle", "Managers.eac_client:authenticate()")
		Managers.eac_client:authenticate()
	end

	Managers.narrative:reset()
	Managers.data_service.account:signin():next(function (result)
		if not result then
			return
		end

		local account_id = result.account_id
		local profiles = result.profiles
		local gear = result.gear
		local selected_profile = result.selected_profile
		local has_created_first_character = result.has_created_first_character
		local save_manager = Managers.save

		save_manager:set_save_data_account_id(account_id)

		local account_data = save_manager:account_data()
		local input_layout = account_data and account_data.input_settings.controller_layout or "default"

		Managers.input:change_input_layout(input_layout)
		Managers.input:load_settings()
		_create_player(account_id, selected_profile)

		if selected_profile then
			local character_id = selected_profile.character_id
			self._narrative_promise = Managers.narrative:load_character_narrative(character_id)
		end

		local main_menu_loader = MainMenuLoader:new()

		main_menu_loader:start_loading()

		local next_state_params = self._next_state_params
		next_state_params.main_menu_loader = main_menu_loader
		next_state_params.profiles = profiles
		next_state_params.gear = gear
		next_state_params.selected_profile = selected_profile
		next_state_params.has_created_first_character = has_created_first_character

		self:_set_state(STATES.loading_packages)

		if Managers.chat and not Managers.chat:is_initialized() then
			Managers.chat:initialize()
		end

		if GameParameters.prod_like_backend and result.account_id ~= PlayerManager.NO_ACCOUNT_ID then
			Managers.party_immaterium:start()
		end

		if not DEDICATED_SERVER then
			Managers.dlc:initialize()
		end

		Managers.account:refresh_communcation_restrictions()
		Managers.account:fetch_crossplay_restrictions()
	end)
end

return StateTitle
