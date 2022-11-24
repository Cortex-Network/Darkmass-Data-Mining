local MatchmakingConstants = require("scripts/settings/network/matchmaking_constants")
local ReporterInterface = require("scripts/managers/telemetry/reporters/reporter_interface")
local SINGLEPLAY_TYPES = MatchmakingConstants.SINGLEPLAY_TYPES
local TrainingGroundsReporter = class("TrainingGroundsReporter")

function TrainingGroundsReporter:init()
	self:reset()
end

function TrainingGroundsReporter:update(dt, t)
end

function TrainingGroundsReporter:report()
	if not self._reporter_set_up then
		return
	end

	local start_type = self._start_type or ""
	local finish_type = self._checkpoint or ""
	local user_quit = not self._training_completed

	if user_quit then
		Log.info("TrainingGroundsReporter", "Training Complete was not registered properly. Level was likely force quit.")
	end

	local duration = Managers.time:time("training_grounds_timer")
	local singleplay_type = Managers.mechanism:singleplay_type()
	local is_onboarding = singleplay_type == SINGLEPLAY_TYPES.onboarding
	local latest_started_scenario = self._latest_started_scenario or ""
	local num_scenarios_started = self._num_scenarios_started or 0

	Managers.telemetry_events:training_grounds_completed(start_type, finish_type, user_quit, is_onboarding, duration, latest_started_scenario, num_scenarios_started)
	self:reset()
end

function TrainingGroundsReporter:set_start_type(start_type)
	if self._reporter_set_up then
		Log.info("TrainingGroundsReporter", "Attempted to set up reporter twice. This is expected when continuing onto advanced training.")

		return
	end

	self._reporter_set_up = true
	self._start_type = start_type

	Managers.time:register_timer("training_grounds_timer", "main")
end

function TrainingGroundsReporter:register_training_checkpoint(checkpoint)
	self._checkpoint = checkpoint
end

function TrainingGroundsReporter:register_training_completed()
	self._training_completed = true
end

function TrainingGroundsReporter:register_new_scenario_started(scenario_name)
	self._latest_started_scenario = scenario_name
	self._num_scenarios_started = (self._num_scenarios_started or 0) + 1
end

function TrainingGroundsReporter:destroy()
end

function TrainingGroundsReporter:reset()
	self._reporter_set_up = false
	self._training_completed = false
	self._start_type = nil
	self._checkpoint = nil
	self._duration = nil
	self._latest_started_scenario = nil
	self._scenarios_started = nil

	if Managers.time:has_timer("training_grounds_timer") then
		Managers.time:unregister_timer("training_grounds_timer")
	end
end

implements(TrainingGroundsReporter, ReporterInterface)

return TrainingGroundsReporter
