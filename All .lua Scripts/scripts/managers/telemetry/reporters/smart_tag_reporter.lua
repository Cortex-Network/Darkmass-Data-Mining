local ReporterInterface = require("scripts/managers/telemetry/reporters/reporter_interface")
local SmartTagReporter = class("SmartTagReporter")

function SmartTagReporter:init()
	self._reports = {}
end

function SmartTagReporter:update(dt, t)
end

function SmartTagReporter:report()
	if table.is_empty(self._reports) then
		return
	end

	Managers.telemetry_events:smart_tag_report(self._reports)
end

function SmartTagReporter:register_event(player, template_name)
	local subject = player:telemetry_subject()
	local player_key = string.format("%s:%s", subject.account_id, subject.character_id)
	local entries = self._reports[player_key] and self._reports[player_key].entries

	if entries then
		entries[template_name] = (entries[template_name] or 0) + 1
	else
		local player_data = {
			telemetry_subject = subject,
			telemetry_game_session = player:telemetry_game_session()
		}
		self._reports[player_key] = {
			player_data = player_data,
			entries = {
				[template_name] = 1
			}
		}
	end
end

function SmartTagReporter:destroy()
end

implements(SmartTagReporter, ReporterInterface)

return SmartTagReporter
