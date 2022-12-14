local ArchetypeTalents = require("scripts/settings/ability/archetype_talents/archetype_talents")
local FixedFrame = require("scripts/utilities/fixed_frame")
local GameModeBase = require("scripts/managers/game_mode/game_modes/game_mode_base")
local GameModeTrainingGrounds = class("GameModeTrainingGrounds", "GameModeBase")

local function _log(...)
	Log.info("GameModeTrainingGrounds", ...)
end

function GameModeTrainingGrounds:init(game_mode_context, game_mode_name, network_event_delegate)
	GameModeTrainingGrounds.super.init(self, game_mode_context, game_mode_name, network_event_delegate)
	Managers.event:register(self, "event_loading_finished", "_on_loading_finished")
end

function GameModeTrainingGrounds:_game_mode_state_changed(new_state, old_state)
	_log("[_game_mode_state_changed] new_state: %s; old_state: %s", new_state, old_state)

	if new_state == "in_game" then
		local settings = self._settings

		if settings.force_base_talents then
			local player = Managers.player:local_player(1)

			self:_force_base_talents(player)
		end

		local scenario_system = Managers.state.extension:system("scripted_scenario_system")

		scenario_system:set_enabled(true)
		scenario_system:on_level_enter()

		if not scenario_system:current_scenario() and not scenario_system:has_queued_scenario() then
			local default_scenario = settings.default_init_scripted_scenario

			if default_scenario then
				local t = Managers.time:time("gameplay")

				scenario_system:start_scenario(default_scenario.alias, default_scenario.name, t)
			end
		end
	end
end

function GameModeTrainingGrounds:_on_loading_finished()
	Managers.event:unregister(self, "event_loading_finished")
	self:_change_state("in_game")
end

function GameModeTrainingGrounds:evaluate_end_conditions()
	local current_state = self:state()

	if current_state == "loading" then
		return false
	elseif current_state == "in_game" then
		local failed = self._failed
		local completed = self._completed

		if completed or failed then
			local t = Managers.time:time("gameplay")
			self._leave_game_t = t + 2.5
			local scenario_system = Managers.state.extension:system("scripted_scenario_system")

			scenario_system:stop_scenario(t, nil, true)
			scenario_system:on_level_exit()
			scenario_system:set_enabled(false)
			self:_change_state("leaving_game")
		end
	elseif current_state == "leaving_game" then
		local t = Managers.time:time("gameplay")

		if self._leave_game_t < t then
			return true, "won"
		end
	end

	return false
end

function GameModeTrainingGrounds:complete(triggered_from_flow)
	self._completed = true
end

function GameModeTrainingGrounds:fail()
	self._failed = true
end

function GameModeTrainingGrounds:_force_base_talents(player)
	local profile = player:profile()
	local fixed_t = FixedFrame.get_latest_fixed_time()
	local specialization_name = profile.specialization
	local talent_groups = profile.archetype.specializations[specialization_name].talent_groups
	local base_talents = {}

	for _, group in ipairs(talent_groups) do
		if not group.required_level or group.required_level <= 1 then
			local talents = group.talents

			for _, talent_name in ipairs(talents) do
				base_talents[talent_name] = true
			end
		end
	end

	local specialization_extension = ScriptUnit.extension(player.player_unit, "specialization_system")

	specialization_extension:select_new_specialization(specialization_name, base_talents, fixed_t)
end

function GameModeTrainingGrounds:destroy()
	local telemetry_reporter = Managers.telemetry_reporters:reporter("training_grounds")

	if telemetry_reporter then
		Managers.telemetry_reporters:stop_reporter("training_grounds")
	end

	GameModeTrainingGrounds.super.destroy(self)
end

implements(GameModeTrainingGrounds, GameModeBase.INTERFACE)

return GameModeTrainingGrounds
