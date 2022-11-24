local ReporterInterface = require("scripts/managers/telemetry/reporters/reporter_interface")
local CombatAbilityReporter = class("CombatAbilityReporter")

function CombatAbilityReporter:init()
	self._reports = {}
end

function CombatAbilityReporter:destroy()
end

function CombatAbilityReporter:update(dt, t)
end

function CombatAbilityReporter:report()
	if table.is_empty(self._reports) then
		return
	end

	Managers.telemetry_events:player_combat_ability_report(self._reports)
end

function CombatAbilityReporter:register_event(player, ability_name)
	local subject = player:telemetry_subject()
	local player_key = string.format("%s:%s", subject.account_id, subject.character_id)
	local entries = self._reports[player_key] and self._reports[player_key].entries

	if entries then
		entries[ability_name] = (entries[ability_name] or 0) + 1
	else
		local player_data = {
			telemetry_subject = subject,
			telemetry_game_session = player:telemetry_game_session()
		}
		self._reports[player_key] = {
			player_data = player_data,
			entries = {
				[ability_name] = 1
			}
		}
	end
end

implements(CombatAbilityReporter, ReporterInterface)

return CombatAbilityReporter
