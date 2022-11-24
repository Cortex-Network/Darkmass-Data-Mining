local TriggerSettings = require("scripts/extension_systems/trigger/trigger_settings")
local ONLY_ONCE = TriggerSettings.only_once
local ACTION_TARGETS = TriggerSettings.action_targets
local MACHINE_TARGETS = TriggerSettings.machine_targets
local SafeVolume = component("SafeVolume")

function SafeVolume:init(unit)
	local trigger_extension = ScriptUnit.fetch_component_extension(unit, "trigger_system")

	if trigger_extension then
		local parameters = {
			action_player_side = "none",
			action_target = ACTION_TARGETS.none,
			action_machine_target = MACHINE_TARGETS.server
		}
		local only_once = ONLY_ONCE.only_once_for_all_units
		local evaluate_bots = false
		local start_active = true

		trigger_extension:setup_from_component("at_least_one_player_inside", evaluate_bots, "safe_volume", parameters, only_once, start_active, "content/volume_types/player_trigger")

		self._trigger_extension = trigger_extension
	end
end

function SafeVolume:editor_init(unit)
end

function SafeVolume:enable(unit)
end

function SafeVolume:disable(unit)
end

function SafeVolume:destroy(unit)
end

function SafeVolume:activate()
	local trigger_extension = self._trigger_extension

	if trigger_extension then
		trigger_extension:activate(true)
	end
end

function SafeVolume:deactivate()
	local trigger_extension = self._trigger_extension

	if trigger_extension then
		trigger_extension:activate(false)
	end
end

SafeVolume.component_data = {
	inputs = {
		activate = {
			accessibility = "public",
			type = "event"
		},
		deactivate = {
			accessibility = "public",
			type = "event"
		}
	},
	extensions = {
		"TriggerExtension"
	}
}

return SafeVolume
