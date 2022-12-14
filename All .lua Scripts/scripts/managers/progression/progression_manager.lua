local BackendInterface = require("scripts/backend/backend_interface")
local EndViewSettings = require("scripts/ui/views/end_view/end_view_settings")
local EndPlayerViewAnimations = require("scripts/ui/views/end_player_view/end_player_view_animations")
local EndPlayerViewSettings = require("scripts/ui/views/end_player_view/end_player_view_settings")
local MatchmakingConstants = require("scripts/settings/network/matchmaking_constants")
local DummySessionReport = require("scripts/managers/progression/dummy_session_report")
local Progression = require("scripts/backend/progression")
local MasterItems = require("scripts/backend/master_items")
local Promise = require("scripts/foundation/utilities/promise")
local PlayerSpecializationUtils = require("scripts/utilities/player_specialization/player_specialization")
local WeaponUnlockSettings = require("scripts/settings/weapon_unlock_settings")
local ItemUtils = require("scripts/utilities/items")

local function _info(...)
	Log.info("ProgressManager", ...)
end

local HOST_TYPES = MatchmakingConstants.HOST_TYPES
local ProgressionManager = class("ProgressionManager")
local FETCH_DUMMY_SESSION_REPORT = false
local FETCH_DUMMY_SESSION_REPORT_DELAY = {
	max = 5,
	min = 0
}
local SESSION_REPORT_STATES = table.enum("none", "fetching", "success", "fail")
local SET_TRAITS_STATES = table.enum("none", "updating", "success", "fail")
local FAILED_FETCHING_SESSION_REPORT = false

function ProgressionManager:init()
	self._backend_interface = BackendInterface:new()
	self._progression = Progression:new()
	self._session_report_state = SESSION_REPORT_STATES.none
	self._set_traits_state = SET_TRAITS_STATES.none
end

function ProgressionManager:destroy()
end

function ProgressionManager:clear_session_report()
	self._session_report_state = SESSION_REPORT_STATES.none
	self._set_traits_state = SET_TRAITS_STATES.none
	self._session_report = {}
	self._game_score_end_time = nil
end

function ProgressionManager:fetching_session_report_not_started()
	return self._session_report_state == SESSION_REPORT_STATES.none
end

function ProgressionManager:is_fetching_session_report()
	return self._session_report_state == SESSION_REPORT_STATES.fetching
end

function ProgressionManager:session_report_success()
	return self._session_report_state == SESSION_REPORT_STATES.success
end

function ProgressionManager:session_report_fail()
	return self._session_report_state == SESSION_REPORT_STATES.fail
end

function ProgressionManager:is_using_dummy_report()
	return self._session_report_is_dummy
end

function ProgressionManager:fetch_session_report(session_id)
	self._session_report = {
		team = {},
		character = {}
	}
	self._session_report.character.rewards = {}
	self._session_report.account = {
		rewards = {}
	}
	self._session_report.weapon = {}
	self._game_score_end_time = nil
	self._session_report_is_dummy = false
	self._session_report_state = SESSION_REPORT_STATES.fetching

	if self:_should_use_dummy_session_report(session_id) then
		return self:_use_dummy_session_report()
	end

	local profile = self:_get_profile()
	local player = Managers.player:player(Network.peer_id(), 1)
	local participant = player:account_id() .. "|" .. profile.character_id
	local session_report_promise = self._backend_interface.gameplay_session:poll_for_end_of_round(session_id, participant)
	local character_xp_settings_promise = self._progression:get_xp_table("character")
	local account_xp_settings_promise = self._progression:get_xp_table("account")

	_info("Fetching session report for session %s...", session_id)
	Promise.all(session_report_promise, character_xp_settings_promise, account_xp_settings_promise):next(function (results)
		local session_report, character_xp_settings, account_xp_settings = unpack(results, 1, 3)
		local eor = session_report.eor
		self._session_report.eor = eor

		_info("Got session report, parsing it...")

		self._session_report.character.experience_settings = self:_parse_experience_settings(character_xp_settings)
		self._session_report.account.experience_settings = self:_parse_experience_settings(account_xp_settings)
		self._session_report.character.experience_settings_unparsed = character_xp_settings
		self._session_report.account.experience_settings_unparsed = account_xp_settings

		self:_parse_report(eor)

		return self._backend_interface.wallet:combined_wallets(player:character_id())
	end):next(function (wallets)
		self._session_report.character.wallets = wallets

		self:_parse_wallets(wallets)
	end):catch(function (errors)
		local error_string = nil

		if type(errors) == "table" then
			local session_report_error, character_xp_error, account_xp_error = unpack(errors)
			error_string = tostring(session_report_error) .. tostring(character_xp_error) .. tostring(account_xp_error)
		else
			error_string = errors
		end

		Log.error("ProgressionManager", "Error fetching session_report: %s", error_string)

		self._session_report_state = SESSION_REPORT_STATES.fail

		Managers.mechanism:trigger_event("failed_fetching_session_report", Network.peer_id(), FAILED_FETCHING_SESSION_REPORT)
		Managers.multiplayer_session:leave("failed_fetching_session_report")
	end)
end

function ProgressionManager:fetch_session_report_server(session_id)
	self._session_report = {}
	self._game_score_end_time = nil
	self._session_report_state = SESSION_REPORT_STATES.fetching

	if self:_should_use_dummy_session_report(session_id) then
		self:_use_dummy_session_report_server()
		self:_calculate_game_score_end()
		self:_sync_game_score_end_time()

		return
	end

	_info("Fetching session report server...")
	self._backend_interface.gameplay_session:poll_for_end_of_round(session_id):next(function (session_report)
		local eor = session_report.eor
		self._session_report.eor = eor

		_info("Got session report, parsing it...")
		_info("full_session_report: %s", table.tostring(eor, 9))

		self._session_report_state = SESSION_REPORT_STATES.success

		self:_calculate_and_sync_game_score_end()
	end):catch(function (error)
		Log.error("ProgressionManager", "Error fetching session_report_server: %s", error)

		self._session_report_state = SESSION_REPORT_STATES.fail
		self._game_score_end_time = EndViewSettings.max_duration

		self:_sync_game_score_end_time()
	end)
end

function ProgressionManager:_should_use_dummy_session_report(session_id)
	local use_dummy_session_report = FETCH_DUMMY_SESSION_REPORT
	local host_type = Managers.multiplayer_session:host_type()
	local valid_host_type = host_type == HOST_TYPES.mission_server or host_type == HOST_TYPES.singleplay_backend_session

	if not valid_host_type then
		_info("invalid host_type %s", host_type)

		use_dummy_session_report = true
	end

	if GameParameters.testify then
		use_dummy_session_report = true
	end

	if not session_id then
		use_dummy_session_report = true
	end

	if session_id == "NO_SESSION_ID" then
		use_dummy_session_report = true
	end

	return use_dummy_session_report
end

function ProgressionManager:_parse_experience_settings(unparsed_xp_settings)
	local max_level = #unparsed_xp_settings
	local experience_settings = {
		experience_table = unparsed_xp_settings,
		max_level_experience = unparsed_xp_settings[max_level],
		max_level = max_level
	}

	return experience_settings
end

function ProgressionManager:_parse_report(eor)
	local player = Managers.player:player(Network.peer_id(), 1)
	local my_account_id = player:account_id()
	local account_data = self:_get_account_data(eor, my_account_id)

	if not account_data then
		Log.error("ProgressManager", "No account data found for me in session report, account_id: %s", my_account_id)

		self._session_report_state = SESSION_REPORT_STATES.fail

		return
	end

	local progression = self:_get_progression(account_data)

	if not progression then
		Log.error("ProgressionManager", "No progression found for me in session report, account_id: %s", my_account_id)

		self._session_report_state = SESSION_REPORT_STATES.fail

		return
	end

	local inventory = self:_get_inventory(account_data)

	if not inventory then
		Log.error("ProgressionManager", "No inventory found for me in session report, account_id: %s", my_account_id)

		self._session_report_state = SESSION_REPORT_STATES.fail

		return
	end

	self._session_report.character.inventory = inventory
	local character_stats = self:_get_progression_stats(progression, "character")

	if not character_stats then
		Log.error("ProgressionManager", "No character_stats found for me in session report, account_id: %s", my_account_id)

		self._session_report_state = SESSION_REPORT_STATES.fail

		return
	end

	local account_stats = self:_get_progression_stats(progression, "account")

	if not account_stats then
		Log.warning("ProgressionManager", "No account_stats found for me in session report, account_id: %s", my_account_id)

		self._session_report_state = SESSION_REPORT_STATES.fail

		return
	end

	self:_parse_stats(character_stats)
	self:_parse_stats(account_stats)
	self:_parse_mission_stats(eor)
	self:_parse_team_stats(account_data)
	self:_parse_reward_cards(account_data)

	local credits_reward = self:_get_credits_reward(account_data.missionRewards)
	self._session_report.credits_reward = credits_reward
	local promise_list = {}
	local character_level_up_promise = self:_check_level_up(character_stats)

	table.insert(promise_list, character_level_up_promise)

	local account_level_up_promise = self:_check_level_up(account_stats)

	table.insert(promise_list, account_level_up_promise)
	Promise.all(unpack(promise_list)):next(function (data)
		if self._session_report_is_dummy then
			self._session_report_state = SESSION_REPORT_STATES.success

			_info("Dummmy session_report fetched and parsed successfully")
			self:_calculate_game_score_end()

			return
		end

		local profile = self:_get_profile()
		local character_id = profile.character_id

		Promise.all(Managers.backend.interfaces.gear:fetch(), Managers.backend.interfaces.progression:get_progression("character", character_id)):next(function (results)
			local gear_list, character_progression = unpack(results, 1, 2)
			profile.current_level = character_progression.currentLevel or 1
			self._session_report_state = SESSION_REPORT_STATES.success

			_info("session_report fetched and parsed successfully")

			local is_host = Managers.connection:is_host()

			if is_host then
				self:_calculate_and_sync_game_score_end()
			end
		end)
	end):catch(function (errors)
		local error_string = nil

		if type(errors) == "table" then
			error_string = table.tostring(errors, 5)
		else
			error_string = errors
		end

		Log.error("ProgressionManager", "Error parsing session_report: %s", error_string)

		self._session_report_state = SESSION_REPORT_STATES.fail
	end)
end

function ProgressionManager:_parse_wallets(wallets)
	local session_report_rewards = self._session_report.character.rewards
	local salary_card = nil

	for i = 1, #session_report_rewards do
		local reward_card = session_report_rewards[i]

		if reward_card.kind == "salary" then
			salary_card = reward_card

			break
		end
	end

	local salary_rewards = salary_card and salary_card.rewards

	if salary_rewards then
		for i = 1, #salary_rewards do
			local salary_reward = salary_rewards[i]
			local currency = salary_reward.currency
			local wallet = wallets:by_type(currency)

			if wallet then
				salary_reward.current_amount = wallet.balance.amount
			end
		end
	end
end

function ProgressionManager:_get_account_data(eor, my_account_id)
	local team = eor.team
	local participants = team.participants

	for _, participant in ipairs(participants) do
		local participant_account_id = participant.accountId

		if participant_account_id == my_account_id then
			return participant
		end
	end
end

function ProgressionManager:_get_progression(account_data)
	return account_data.progression
end

function ProgressionManager:_get_inventory(account_data)
	local character_details = account_data.characterDetails

	return character_details and character_details.inventory
end

function ProgressionManager:_get_credits_reward(reward_cards)
	if not reward_cards then
		return 0
	end

	local len = #reward_cards

	for i = 1, len do
		local card = reward_cards[i]

		if card.kind == "salary" then
			local rewards = card.rewards
			local reward_len = #rewards

			for j = 1, reward_len do
				local reward = rewards[j]

				if reward.rewardType == "currency" and reward.currency == "credits" then
					return reward.amount
				end

				j = j + 1
			end
		end

		i = i + 1
	end

	return 0
end

function ProgressionManager:_parse_stats(stats)
	local start_xp = stats.startXp
	local current_xp = stats.currentXp
	local experience_gained = current_xp - start_xp
	local report_sheet = self._session_report[stats.type]
	report_sheet.starting_experience = start_xp
	report_sheet.current_experience = current_xp
	report_sheet.experience_gained = experience_gained
end

function ProgressionManager:_get_profile()
	local profile = Managers.player:local_player_backend_profile()

	if self._session_report_is_dummy and not profile then
		local player = Managers.player:player(Network.peer_id(), 1)
		profile = player:profile()
	end

	return profile
end

function ProgressionManager:_get_progression_stats(progression, stat_type)
	for _, stats in ipairs(progression) do
		if stats.type == stat_type then
			return stats
		end
	end
end

function ProgressionManager:_parse_team_stats(account_data)
	local session_statistics = account_data.sessionStatistics
	local total_kills = self:_get_session_stat(session_statistics, "team_kills") or 0
	local total_deaths = self:_get_session_stat(session_statistics, "team_deaths") or 0
	self._session_report.team.total_kills = total_kills
	self._session_report.team.total_deaths = total_deaths
end

function ProgressionManager:_get_session_stat(session_statistics, stat_type)
	for i, stat in ipairs(session_statistics) do
		local type_path = stat.typePath

		if type_path == stat_type then
			local session_value = stat.sessionValue

			if not session_value then
				Log.error("ProgressionManager", "Missing sessionValue for %s", stat_type)

				return
			end

			local value = session_value.none

			if not value then
				Log.error("ProgressionManager", "Missing sessionValue.none for %s", stat_type)

				return
			end

			return value
		end
	end
end

function ProgressionManager:_parse_mission_stats(eor)
	local mission = eor.mission
	local play_time_seconds = mission.playTimeSeconds
	self._session_report.team.play_time_seconds = play_time_seconds
end

function ProgressionManager:_parse_reward_cards(account_data)
	local reward_cards = account_data.rewardCards

	if not reward_cards then
		return
	end

	local character_rewards = self._session_report.character.rewards

	table.create_copy(character_rewards, reward_cards)

	for i = 1, #character_rewards do
		local reward_card = character_rewards[i]
		local reward_card_rewards = reward_card.rewards

		for j = 1, #reward_card_rewards do
			local reward = reward_card_rewards[j]
			reward.amount_gained = reward.amount or 0
			reward.amount = nil
			reward.reward_type = reward.rewardType
			reward.rewardType = nil
			reward.master_id = reward.masterId
			reward.masterId = nil
			reward.gear_id = reward.gearId
			reward.gearId = nil
			local details = reward.details

			if details then
				details.from_circumstance = details.fromCircumstance
				details.fromCircumstance = nil
				details.from_side_mission = details.fromSideMission
				details.fromSideMission = nil
				details.from_side_mission_bonus = details.fromSideMissionBonus
				details.fromSideMissionBonus = nil
				details.from_total_bonus = details.fromTotalBonus
				details.fromTotalBonus = nil
			end
		end

		if reward_card.kind == "levelUp" and reward_card.target == "character" then
			self:_add_level_up_unlocks_to_card(reward_card)
		end
	end
end

function ProgressionManager:session_report()
	_info("Parsed session report has been returned")

	return self._session_report
end

function ProgressionManager:_check_level_up(stats)
	if self._session_report_is_dummy then
		_info("Dummy Session report level up completed")

		return Promise.resolved()
	end

	local needed_xp_for_next_level = stats.neededXpForNextLevel

	if needed_xp_for_next_level == 0 then
		local current_level = stats.currentLevel
		local next_level = current_level + 1

		return self:_level_up(stats, next_level)
	end

	if needed_xp_for_next_level == -1 then
		self:_cap_xp(stats)
	end

	_info("Session report " .. stats.type .. " level up completed [id:%s]", stats.id)

	return Promise.resolved()
end

function ProgressionManager:_add_unlocked_weapons_to_card(reward_card, specialization_name, target_level)
	local archetype_weapon_unlocks = WeaponUnlockSettings[specialization_name]
	local weapons_unlocks_at_level = archetype_weapon_unlocks[target_level]

	if weapons_unlocks_at_level then
		for i = 1, #weapons_unlocks_at_level do
			self:_append_reward_to_card(reward_card, {
				reward_type = "weapon_unlock",
				master_id = weapons_unlocks_at_level[i]
			})
		end
	end
end

function ProgressionManager:_add_unlocked_talents_to_card(reward_card, profile, specialization_name, target_level)
	local profile_archetype = profile.archetype
	local talent_group_id = PlayerSpecializationUtils.talent_group_unlocked_by_level(profile_archetype, specialization_name, target_level)

	if not talent_group_id then
		return
	end

	Managers.data_service.talents:mark_unlocked_group_as_new(profile.character_id, talent_group_id)

	local talent_group = PlayerSpecializationUtils.talent_group_from_id(profile_archetype, specialization_name, talent_group_id)
	local talents = table.clone(talent_group.talents)
	local talent_group_name = talent_group.group_name

	self:_append_reward_to_card(reward_card, {
		reward_type = "talents_unlock",
		specialization_name = specialization_name,
		talent_group_id = talent_group_id,
		talent_group_name = talent_group_name,
		talents = talents
	})
end

function ProgressionManager:_add_level_up_unlocks_to_card(reward_card)
	local target_level = reward_card.level
	local profile = self:_get_profile()
	local specialization_name = profile.specialization

	self:_add_unlocked_weapons_to_card(reward_card, specialization_name, target_level)
	self:_add_unlocked_talents_to_card(reward_card, profile, specialization_name, target_level)
end

function ProgressionManager:_level_up(stats, target_level)
	_info("Leveling up " .. stats.type .. " to %s ...", target_level)

	return self._progression:level_up(stats.type, stats.id, target_level):next(function (data)
		_info("level_up %s: %s", stats.type, table.tostring(data, 6))

		local reward_card = self:_find_level_up_card(target_level, stats.type)

		self:_parse_level_up_rewards(reward_card, stats.type, data)

		local progression_info = data.progressionInfo

		return self:_check_level_up(progression_info)
	end):catch(function (error)
		self._session_report_state = SESSION_REPORT_STATES.fail

		_info("Failed level_up, error: %s", error)

		return Promise.rejected(error)
	end)
end

function ProgressionManager:_parse_level_up_rewards(reward_card, type, data)
	local rewards = self._session_report[type].rewards
	local reward_info = data.rewardInfo
	local reward_list = reward_info.rewards

	for _, reward in ipairs(reward_list) do
		self:_append_reward_to_card(reward_card, reward)

		local reward_type = reward.rewardType

		if reward_type == "item" then
			local reward_item_id = reward.masterId

			if MasterItems.item_exists(reward_item_id) then
				local reward_data = {
					text = "testing testing",
					type = reward_type,
					reward_item_id = reward_item_id,
					level = reward_info.level
				}

				table.insert(rewards, reward_data)

				local item = MasterItems.get_store_item_instance(reward)

				if item then
					local gear_id = item.gear_id

					if gear_id then
						local item_type = item.item_type

						ItemUtils.mark_item_id_as_new(gear_id, item_type)
					end
				end
			else
				Log.error("ProgressionManager", "Recieved invalid item %s as reward from backend", reward_item_id)
			end
		end
	end
end

function ProgressionManager:_find_level_up_card(target_level, experience_type)
	experience_type = experience_type or "character"
	local reward_cards = self._session_report.character.rewards

	if not reward_cards then
		return
	end

	for i = 1, #reward_cards do
		local reward_card = reward_cards[i]
		local kind = reward_card.kind

		if kind == "levelUp" then
			local level = reward_card.level
			local target = reward_card.target

			if level == target_level and target == experience_type then
				return reward_card
			end
		end
	end
end

function ProgressionManager:_append_reward_to_card(reward_card, reward)
	if not reward_card then
		return
	end

	local rewards = reward_card.rewards
	rewards[#rewards + 1] = reward
	reward_card.rewards = rewards
end

function ProgressionManager:_cap_xp(stats)
	local report_sheet = self._session_report[stats.type]
	local experience_settings = report_sheet.experience_settings_unparsed
	local level = stats.currentLevel
	local max_experience = experience_settings[level]
	local session_starting_experience = report_sheet.starting_experience
	local starting_experience = math.min(session_starting_experience, max_experience)
	local current_experience = math.min(stats.currentXp, max_experience)
	local experience_gained = current_experience - starting_experience
	report_sheet.starting_experience = starting_experience
	report_sheet.current_experience = current_experience
	report_sheet.experience_gained = experience_gained
	report_sheet.max_level_reached = true

	_info("%s is capped at level: %s, xp: %s ", stats.type, level, max_experience)
end

function ProgressionManager:get_item_rank(item)
	return item.weapon_level or 1
end

function ProgressionManager:get_traits(item)
	if not item.bound_traits then
		return
	end

	local bound_traits = table.clone(item.bound_traits)

	return bound_traits
end

function ProgressionManager:is_trait_slot_unlocked(item, slot_index)
	local bound_traits = item.bound_traits

	if not bound_traits then
		return false, 1
	end

	local trait_unlocked_at = slot_index
	local weapon_level = item.weapon_level or math.huge
	local trait_slot_unlocked = trait_unlocked_at <= weapon_level

	return trait_slot_unlocked, trait_unlocked_at
end

function ProgressionManager:set_game_score_end_time(end_time)
	self._game_score_end_time = end_time
end

function ProgressionManager:game_score_end_time()
	if not self._game_score_end_time then
		return
	end

	local game_score_end_time_in_ms = self._game_score_end_time * 1000

	return game_score_end_time_in_ms
end

function ProgressionManager:_calculate_game_score_end()
	local t = Managers.time:time("main")
	local server_time = math.floor(Managers.backend:get_server_time(t) / 1000)
	local max_report_time = 0
	local dummy = self._session_report.dummy

	if dummy then
		Log.info("ProgressionManager", "Calculating length of EoR from Dummy Session Report")
	end

	local eor = self._session_report.eor
	local participant_reports = eor.team.participants

	for i = 1, #participant_reports do
		local report = participant_reports[i]
		local character_id = report.characterId
		local associated_profile = nil

		for _, player in pairs(Managers.player:human_players()) do
			if player:character_id() == character_id then
				associated_profile = player:profile()

				break
			end
		end

		local report_time = self:_calculate_report_time(associated_profile, report)

		if max_report_time < report_time then
			max_report_time = report_time
		end
	end

	max_report_time = max_report_time + EndViewSettings.delay_before_summary + EndViewSettings.delay_after_summary
	local end_time = server_time + max_report_time
	self._game_score_end_time = end_time
end

function ProgressionManager:_calculate_and_sync_game_score_end()
	self:_calculate_game_score_end()
	self:_sync_game_score_end_time()
end

function ProgressionManager:_sync_game_score_end_time()
	local mechanism_name = Managers.mechanism:mechanism_name()

	if mechanism_name == "adventure" then
		local game_score_end_time = self._game_score_end_time

		Managers.mechanism:trigger_event("game_score_end_time", game_score_end_time)
	end
end

local _card_animations = {
	xp = EndPlayerViewAnimations.experience_card_show_content,
	levelUp = EndPlayerViewAnimations.level_up_show_content,
	salary = EndPlayerViewAnimations.salary_card_show_content,
	weaponDrop = EndPlayerViewAnimations.item_reward_show_content
}

function ProgressionManager:_calculate_report_time(profile, participant_report)
	if profile == nil then
		Log.info("ProgressionManager", "No profile found for '%s' in session report.", table.tostring(participant_report, 3))

		return 0
	end

	local report_time = 0
	local card_animations = _card_animations
	local reward_cards = participant_report.rewardCards

	for i = 1, #reward_cards do
		local reward_card = reward_cards[i]
		local card_kind = reward_card.kind

		if card_kind == "levelUp" then
			report_time = report_time + self:_get_level_up_card_time(profile, reward_card)
		elseif card_animations[card_kind] ~= nil then
			report_time = report_time + self:_get_duration_for_reward_card_animation(card_animations[card_kind])
		else
			Log.warning("ProgressManager", "Unknown card kind '%s'.", card_kind)
		end
	end

	return report_time
end

function ProgressionManager:_get_level_up_card_time(profile, reward_card)
	local level = reward_card.level
	local total_time = 0
	local profile_archetype = profile.archetype
	local specialization_name = profile.specialization
	local archetype_weapon_unlocks = WeaponUnlockSettings[specialization_name]
	local weapons_unlocks_at_level = archetype_weapon_unlocks[level]

	if weapons_unlocks_at_level then
		total_time = total_time + self:_get_duration_for_reward_card_animation(EndPlayerViewAnimations.unlocked_weapon_show_content) * #weapons_unlocks_at_level
	end

	local talent_group_id = PlayerSpecializationUtils.talent_group_unlocked_by_level(profile_archetype, specialization_name, level)

	if talent_group_id then
		total_time = total_time + self:_get_duration_for_reward_card_animation(EndPlayerViewAnimations.unlocked_talents_show_content)
	end

	for i = 1, #reward_card.rewards do
		local reward = reward_card.rewards[i]
		local reward_type = reward.rewardType

		if reward_type == "gear" then
			total_time = total_time + self:_get_duration_for_reward_card_animation(EndPlayerViewAnimations.level_up_show_content)
		else
			Log.warning("Progression", "Unknown reward type '%s' recieved from backend.", reward_type)
		end
	end

	return total_time
end

local _fixed_card_time = EndPlayerViewSettings.animation_times.fixed_card_time

function ProgressionManager:_get_duration_for_reward_card_animation(animation)
	if not animation then
		return 0
	end

	local end_time = animation[#animation].end_time

	return end_time + _fixed_card_time
end

function ProgressionManager:_use_dummy_session_report()
	self._session_report_is_dummy = true
	self._dummy_session_promise = Promise.new()
	self._session_report_state = SESSION_REPORT_STATES.fetching

	if FETCH_DUMMY_SESSION_REPORT_DELAY.max > 0 then
		local t = Managers.time:time("main")
		local delay = math.random_range(FETCH_DUMMY_SESSION_REPORT_DELAY.min, FETCH_DUMMY_SESSION_REPORT_DELAY.max)

		_info("Fetching dummy session report with delay %s sec", delay)

		self._fetch_session_report_at = t + delay
	else
		self:_fetch_dummy_session_report()
	end

	return self._dummy_session_promise
end

function ProgressionManager:_fetch_dummy_session_report()
	local player = Managers.player:player(Network.peer_id(), 1)
	local session_report = DummySessionReport.fetch_session_report(player:account_id())
	local character_xp = DummySessionReport.fetch_xp_table("character")
	local account_xp = DummySessionReport.fetch_xp_table("account")
	local inventory = DummySessionReport.fetch_inventory(session_report)
	self._session_report.eor = session_report
	self._session_report.dummy = true
	self._session_report.character.inventory = inventory
	self._session_report.character.experience_settings = self:_parse_experience_settings(character_xp)
	self._session_report.account.experience_settings = self:_parse_experience_settings(account_xp)

	self:_parse_report(session_report)

	self._session_report_state = SESSION_REPORT_STATES.success
	local dummy_wallet = {
		wallets = {
			{
				balance = {
					amount = 12345,
					type = "credits"
				}
			},
			{
				balance = {
					amount = 2345,
					type = "plasteel"
				}
			},
			{
				balance = {
					amount = 25,
					type = "diamantine"
				}
			}
		},
		by_type = function (self, wallet_type)
			if wallet_type == "credits" then
				return self.wallets[1]
			elseif wallet_type == "plasteel" then
				return self.wallets[2]
			elseif wallet_type == "diamantine" then
				return self.wallets[3]
			end
		end
	}
	self._session_report.character.wallets = dummy_wallet

	self:_parse_wallets(dummy_wallet)

	if self._dummy_session_promise then
		self._dummy_session_promise:resolve()
	end
end

function ProgressionManager:fetch_dummy_session_report()
	self._session_report = {
		team = {},
		character = {}
	}
	self._session_report.character.rewards = {}
	self._session_report.account = {
		rewards = {}
	}
	self._session_report.weapon = {}
	self._session_report_is_dummy = true

	self:_fetch_dummy_session_report()

	return self._session_report
end

function ProgressionManager:_use_dummy_session_report_server()
	local session_report = DummySessionReport.fetch_session_report()
	self._session_report.eor = session_report
	self._session_report.dummy = true
	self._session_report_state = SESSION_REPORT_STATES.success
end

function ProgressionManager:update(dt, t)
	local fetch_session_report_at = self._fetch_session_report_at

	if fetch_session_report_at and fetch_session_report_at <= t then
		self:_fetch_dummy_session_report()
		_info("Fetch dummy session report completed")

		self._fetch_session_report_at = nil
	end
end

return ProgressionManager
