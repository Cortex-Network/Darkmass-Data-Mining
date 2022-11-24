local MechanismBase = require("scripts/managers/mechanism/mechanisms/mechanism_base")
local Missions = require("scripts/settings/mission/mission_templates")
local StateGameplay = require("scripts/game_states/game/state_gameplay")
local StateLoading = require("scripts/game_states/game/state_loading")
local MechanismSandbox = class("MechanismSandbox", "MechanismBase")

function MechanismSandbox:init(...)
	MechanismSandbox.super.init(self, ...)

	local mission_name = GameParameters.mission
	self._mission_name = mission_name
	local level_name = nil

	if LEVEL_EDITOR_TEST then
		level_name = Application.get_data("LevelEditor", "level_resource_name") or "__level_editor_test"

		if not mission_name then
			for listed_mission_name, data in pairs(Missions) do
				if data.level == level_name then
					mission_name = listed_mission_name
					self._mission_name = listed_mission_name

					break
				end
			end

			if not mission_name then
				mission_name = "editor_simulation_without_mission"
				self._mission_name = mission_name
			end
		end
	else
		level_name = Missions[mission_name].level
	end

	self._level_name = level_name
end

function MechanismSandbox:sync_data()
end

function MechanismSandbox:game_mode_end(outcome)
	self:_set_state("game_mode_ended")
end

function MechanismSandbox:wanted_transition()
	if self._state == "init" or self._state == "game_mode_ended" then
		self:_set_state("gameplay")

		local challenge = DevParameters.challenge
		local resistance = DevParameters.resistance
		local circumstance = GameParameters.circumstance
		local side_mission = GameParameters.side_mission

		Log.info("MechanismSandbox", "Using dev parameters for challenge and resistance (%s/%s)", challenge, resistance)

		local mechanism_data = {
			challenge = challenge,
			resistance = resistance,
			circumstance_name = circumstance,
			side_mission = side_mission
		}

		return false, StateLoading, {
			level = self._level_name,
			mission_name = self._mission_name,
			circumstance_name = circumstance,
			side_mission = side_mission,
			next_state = StateGameplay,
			next_state_params = {
				mechanism_data = mechanism_data
			}
		}
	end

	return false
end

function MechanismSandbox:is_allowed_to_reserve_slots(peer_ids)
	return true
end

function MechanismSandbox:peers_reserved_slots(peer_ids)
end

function MechanismSandbox:peer_freed_slot(peer_id)
end

implements(MechanismSandbox, MechanismBase.INTERFACE)

return MechanismSandbox
