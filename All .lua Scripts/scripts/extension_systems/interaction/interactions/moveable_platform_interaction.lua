require("scripts/extension_systems/interaction/interactions/base_interaction")

local MoveablePlatformQueries = require("scripts/extension_systems/moveable_platform/utilities/moveable_platform_queries")
local MoveablePlatformInteraction = class("MoveablePlatformInteraction", "BaseInteraction")

function MoveablePlatformInteraction:interactee_condition_func(interactee_unit)
	local moveable_platform_extension = ScriptUnit.extension(interactee_unit, "moveable_platform_system")
	local can_interact = moveable_platform_extension:can_move()

	return can_interact
end

function MoveablePlatformInteraction:hud_description(interactor_unit, interactee_unit, interactable_actor_node_index)
	local interactee_extension = ScriptUnit.extension(interactee_unit, "interactee_system")
	local description = interactee_extension:description()

	if interactable_actor_node_index then
		local moveable_platform_extension = ScriptUnit.extension(interactee_unit, "moveable_platform_system")
		local platform_description = MoveablePlatformQueries.interaction_hud_description(moveable_platform_extension, interactable_actor_node_index)

		if platform_description and platform_description ~= "" then
			description = platform_description
		end
	end

	return description
end

function MoveablePlatformInteraction:stop(world, interactor_unit, unit_data_component, t, result, interactor_is_server)
	if interactor_is_server and result == "success" then
		local target_unit = unit_data_component.target_unit
		local target_actor_node_index = unit_data_component.target_actor_node_index
		local moveable_platform_extension = ScriptUnit.extension(target_unit, "moveable_platform_system")

		if target_actor_node_index then
			MoveablePlatformQueries.activate_platform(moveable_platform_extension, target_actor_node_index)
		end
	end
end

function MoveablePlatformInteraction:marker_offset(interactee_unit, interactable_actor_node_index)
	local result = Vector3.zero()

	if interactable_actor_node_index then
		local moveable_platform_extension = ScriptUnit.extension(interactee_unit, "moveable_platform_system")
		local actor_offset = MoveablePlatformQueries.interaction_offset(interactee_unit, moveable_platform_extension, interactable_actor_node_index)

		if actor_offset then
			result = actor_offset
		end
	end

	return result
end

return MoveablePlatformInteraction
