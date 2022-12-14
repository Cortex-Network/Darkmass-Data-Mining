require("scripts/extension_systems/interaction/interactions/base_interaction")

local InteractionSettings = require("scripts/settings/interaction/interaction_settings")
local Vo = require("scripts/utilities/vo")
local interaction_results = InteractionSettings.results
local RemoveNetInteraction = class("RemoveNetInteraction", "BaseInteraction")

function RemoveNetInteraction:start(world, interactor_unit, unit_data_component, t, is_server)
	RemoveNetInteraction.super.start(self, world, interactor_unit, unit_data_component, t, is_server)

	local target_unit = unit_data_component.target_unit
	local vo_event = self._template.vo_event

	Vo.player_interaction_vo_event(interactor_unit, target_unit, vo_event)
end

function RemoveNetInteraction:interactee_condition_func(interactee_unit)
	local unit_data_extension = ScriptUnit.extension(interactee_unit, "unit_data_system")
	local character_state_component = unit_data_extension:read_component("character_state")

	return character_state_component.state_name == "netted"
end

function RemoveNetInteraction:stop(world, interactor_unit, unit_data_component, t, result, interactor_is_server)
	if interactor_is_server and result == interaction_results.success then
		local target_unit = unit_data_component.target_unit
		local unit_data_extension = ScriptUnit.extension(target_unit, "unit_data_system")
		local assisted_state_input_component = unit_data_extension:write_component("assisted_state_input")
		assisted_state_input_component.success = true
		local interactor_player = Managers.state.player_unit_spawn:owner(interactor_unit)
		local target_player = Managers.state.player_unit_spawn:owner(target_unit)
		local reviver_position = POSITION_LOOKUP[interactor_unit]
		local revivee_position = POSITION_LOOKUP[target_unit]
		local state_name = "netted"

		Managers.telemetry_events:player_revived_ally(interactor_player, target_player, reviver_position, revivee_position, state_name)
	end
end

return RemoveNetInteraction
