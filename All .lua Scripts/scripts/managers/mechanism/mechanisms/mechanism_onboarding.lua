local MatchmakingConstants = require("scripts/settings/network/matchmaking_constants")
local MechanismBase = require("scripts/managers/mechanism/mechanisms/mechanism_base")
local Missions = require("scripts/settings/mission/mission_templates")
local StateGameplay = require("scripts/game_states/game/state_gameplay")
local StateLoading = require("scripts/game_states/game/state_loading")
local HOST_TYPES = MatchmakingConstants.HOST_TYPES
local SINGLEPLAY_TYPES = MatchmakingConstants.SINGLEPLAY_TYPES
local MechanismOnboarding = class("MechanismOnboarding", "MechanismBase")

function MechanismOnboarding:init(...)
	MechanismOnboarding.super.init(self, ...)

	local context = self._context
	self._challenge_level = context.challenge_level
	self._mission_name = context.mission_name
	local mission_settings = Missions[self._mission_name]
	self._level_name = mission_settings.level
	self._singleplay_type = context.singleplay_type
	self._init_scenario = context.init_scenario

	Managers.event:register(self, "scripted_scenario_system_initialized", "_event_scenario_system_initialized")
end

function MechanismOnboarding:sync_data()
end

function MechanismOnboarding:game_mode_end(outcome)
	self:_set_state("game_mode_ended")
end

function MechanismOnboarding:all_players_ready()
end

function MechanismOnboarding:client_exit_gameplay()
end

function MechanismOnboarding:wanted_transition()
	local state = self._state

	if state == "init" then
		self:_set_state("gameplay")

		local challenge = self._challenge_level or DevParameters.challenge
		local resistance = DevParameters.resistance
		local circumstance = GameParameters.circumstance
		local side_mission = GameParameters.side_mission

		Log.info("MechanismOnboarding", "Using dev parameters for challenge and resistance (%s/%s)", challenge, resistance)

		local mechanism_data = {
			challenge = challenge,
			resistance = resistance,
			circumstance_name = circumstance,
			side_mission = side_mission
		}

		return false, StateLoading, {
			wait_for_despawn = true,
			level = self._level_name,
			mission_name = self._mission_name,
			circumstance_name = circumstance,
			side_mission = side_mission,
			next_state = StateGameplay,
			next_state_params = {
				mechanism_data = mechanism_data
			}
		}
	elseif state == "gameplay" then
		return false
	elseif state == "game_mode_ended" then
		local story_name = Managers.narrative.STORIES.onboarding
		local current_chapter = Managers.narrative:current_chapter(story_name)

		if current_chapter then
			local chapter_data = current_chapter.data
			local mission_name = chapter_data.mission_name
			self._mission_name = mission_name
			self._level_name = Missions[mission_name].level

			self:_set_state("init")

			return false
		else
			Log.info("MechanismOnboarding", "Last onboarding mission ended, joining hub...")
			Managers.multiplayer_session:leave("leave_to_hub")
			self:_set_state("joining_hub_server")

			return false
		end
	elseif state == "joining_hub_server" then
		return false
	end
end

function MechanismOnboarding:is_allowed_to_reserve_slots(peer_ids)
	return true
end

function MechanismOnboarding:peers_reserved_slots(peer_ids)
end

function MechanismOnboarding:peer_freed_slot(peer_id)
end

function MechanismOnboarding:destroy()
	Managers.event:unregister(self, "scripted_scenario_system_initialized")
end

function MechanismOnboarding:_event_scenario_system_initialized(scenario_system)
	local init_scenario = self._init_scenario

	if init_scenario then
		scenario_system:set_init_scenario(init_scenario.alias, init_scenario.name)
	end

	self._init_scenario = nil

	Managers.event:unregister(self, "scripted_scenario_system_initialized")
end

function MechanismOnboarding:singleplay_type()
	return self._singleplay_type
end

implements(MechanismOnboarding, MechanismBase.INTERFACE)

return MechanismOnboarding
