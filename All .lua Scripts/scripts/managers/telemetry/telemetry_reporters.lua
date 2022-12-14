local CombatAbilityReporter = require("scripts/managers/telemetry/reporters/combat_ability_reporter")
local ComWheelReporter = require("scripts/managers/telemetry/reporters/com_wheel_reporter")
local EnemySpawnedReporter = require("scripts/managers/telemetry/reporters/enemy_spawned_reporter")
local FrameTimeReporter = require("scripts/managers/telemetry/reporters/frame_time_reporter")
local GrenadeAbilityReporter = require("scripts/managers/telemetry/reporters/grenade_ability_reporter")
local HeartbeatReporter = require("scripts/managers/telemetry/reporters/heartbeat_reporter")
local LoadTimesReporter = require("scripts/managers/telemetry/reporters/load_times_reporter")
local PacingReporter = require("scripts/managers/telemetry/reporters/pacing_reporter")
local PickedItemsReporter = require("scripts/managers/telemetry/reporters/picked_items_reporter")
local PingReporter = require("scripts/managers/telemetry/reporters/ping_reporter")
local PlacedItemsReporter = require("scripts/managers/telemetry/reporters/placed_items_reporter")
local PlayerDealtDamageReporter = require("scripts/managers/telemetry/reporters/player_dealt_damage_reporter")
local PlayerTakenDamageReporter = require("scripts/managers/telemetry/reporters/player_taken_damage_reporter")
local SharedItemsReporter = require("scripts/managers/telemetry/reporters/shared_items_reporter")
local SmartTagReporter = require("scripts/managers/telemetry/reporters/smart_tag_reporter")
local TrainingGroundsReporter = require("scripts/managers/telemetry/reporters/training_grounds_reporter")
local TelemetryReporters = class("TelemetryReporters")
local REPORTER_CLASS_MAP = {
	com_wheel = ComWheelReporter,
	combat_ability = CombatAbilityReporter,
	enemy_spawns = EnemySpawnedReporter,
	frame_time = FrameTimeReporter,
	grenade_ability = GrenadeAbilityReporter,
	heartbeat = HeartbeatReporter,
	load_times = LoadTimesReporter,
	pacing = PacingReporter,
	picked_items = PickedItemsReporter,
	ping = PingReporter,
	placed_items = PlacedItemsReporter,
	player_dealt_damage = PlayerDealtDamageReporter,
	player_taken_damage = PlayerTakenDamageReporter,
	shared_items = SharedItemsReporter,
	smart_tag = SmartTagReporter,
	training_grounds = TrainingGroundsReporter
}

function TelemetryReporters:init()
	self._reporters = {}

	self:start_reporter("heartbeat")
	self:start_reporter("load_times")
end

function TelemetryReporters:start_reporter(name, params)
	Log.debug("TelemetryReporters", "Starting reporter '%s'", name)

	local reporter_class = REPORTER_CLASS_MAP[name]
	self._reporters[name] = reporter_class:new(params)
end

function TelemetryReporters:stop_reporter(name)
	Log.debug("TelemetryReporters", "Stopping reporter '%s'", name)
	self._reporters[name]:report()
	self._reporters[name]:destroy()

	self._reporters[name] = nil
end

function TelemetryReporters:reporter(name)
	return self._reporters[name]
end

function TelemetryReporters:update(dt, t)
	for _, reporter in pairs(self._reporters) do
		reporter:update(dt, t)
	end
end

function TelemetryReporters:destroy()
	for _, reporter in pairs(self._reporters) do
		reporter:destroy()
	end
end

return TelemetryReporters
