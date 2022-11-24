local PlayerUnitStatus = require("scripts/utilities/attack/player_unit_status")
local BaseInteraction = class("BaseInteraction")

function BaseInteraction:init(template)
	self._template = template
end

function BaseInteraction:start(world, interactor_unit, unit_data_component, t, interactor_is_server)
end

function BaseInteraction:stop(world, interactor_unit, unit_data_component, t, result, interactor_is_server)
end

function BaseInteraction:interactor_condition_func(interactor_unit, interactee_unit)
	return not self:_interactor_disabled(interactor_unit)
end

function BaseInteraction:interactee_condition_func(interactee_unit)
	return true
end

function BaseInteraction:interactee_show_marker_func(interactor_unit, interactee_unit)
	return not self:_interactor_disabled(interactor_unit)
end

function BaseInteraction:hud_description(interactor_unit, interactee_unit, target_node)
	local interactee_extension = ScriptUnit.extension(interactee_unit, "interactee_system")

	return interactee_extension:description()
end

function BaseInteraction:hud_block_text(interactor_unit, interactee_unit, target_node)
	local interactee_extension = ScriptUnit.extension(interactee_unit, "interactee_system")

	return interactee_extension:block_text()
end

function BaseInteraction:marker_offset()
	return nil
end

function BaseInteraction:type()
	return self._template.type
end

function BaseInteraction:duration()
	return self._template.duration
end

function BaseInteraction:ui_interaction_type()
	return self._template.ui_interaction_type
end

function BaseInteraction:interaction_icon()
	return self._template.interaction_icon
end

function BaseInteraction:description()
	return self._template.description
end

function BaseInteraction:action_text()
	return self._template.action_text
end

function BaseInteraction:ui_view_name()
	return self._template.ui_view_name
end

function BaseInteraction:only_once()
	return self._template.only_once
end

function BaseInteraction:_interactor_disabled(interactor_unit)
	local unit_data_extension = ScriptUnit.extension(interactor_unit, "unit_data_system")
	local character_state_component = unit_data_extension:read_component("character_state")

	return PlayerUnitStatus.is_disabled(character_state_component)
end

return BaseInteraction
