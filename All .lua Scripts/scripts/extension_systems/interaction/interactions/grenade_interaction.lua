require("scripts/extension_systems/interaction/interactions/pickup_interaction")

local Pickups = require("scripts/settings/pickup/pickups")
local GrenadeInteraction = class("GrenadeInteraction", "PickupInteraction")
local ABILITY_TYPE = "grenade_ability"

function GrenadeInteraction:stop(world, interactor_unit, unit_data_component, t, result, interactor_is_server)
	if interactor_is_server then
		local target_unit = unit_data_component.target_unit

		if result == "success" then
			local ability_extension = ScriptUnit.has_extension(interactor_unit, "ability_system")
			local pickup_name = Unit.get_data(target_unit, "pickup_type")
			local pickup_data = Pickups.by_name[pickup_name]
			local charges_restored = pickup_data.charges_restored

			ability_extension:restore_ability_charge(ABILITY_TYPE, charges_restored)
			self:_trigger_sound(interactor_unit, pickup_data)
			self:_use_charge(target_unit, interactor_unit)
		end
	end
end

function GrenadeInteraction:interactor_condition_func(interactor_unit, interactee_unit)
	local ability_extension = ScriptUnit.has_extension(interactor_unit, "ability_system")

	if not ability_extension then
		return false
	end

	local ability_equipped = ability_extension:ability_is_equipped(ABILITY_TYPE)

	if not ability_equipped then
		return false
	end

	local max_grenade_charges = ability_extension:max_ability_charges(ABILITY_TYPE)
	local remaining_grenade_charges = ability_extension:remaining_ability_charges(ABILITY_TYPE)
	local full_charges = max_grenade_charges <= remaining_grenade_charges

	return not full_charges and GrenadeInteraction.super.interactor_condition_func(self, interactor_unit, interactee_unit)
end

function GrenadeInteraction:hud_block_text(interactor_unit, interactee_unit, interactable_actor_node_index)
	local ability_extension = ScriptUnit.has_extension(interactor_unit, "ability_system")

	if not ability_extension then
		return "loc_action_interaction_inactive_no_grenades"
	end

	local ability_equipped = ability_extension:ability_is_equipped(ABILITY_TYPE)
	local max_grenade_charges = ability_extension:max_ability_charges(ABILITY_TYPE)

	if not ability_equipped or max_grenade_charges <= 0 then
		return "loc_action_interaction_inactive_no_grenades"
	end

	local remaining_grenade_charges = ability_extension:remaining_ability_charges(ABILITY_TYPE)
	local full_charges = max_grenade_charges <= remaining_grenade_charges

	if full_charges then
		return "loc_action_interaction_inactive_grenades_full"
	end

	return GrenadeInteraction.super.hud_block_text(self, interactor_unit, interactee_unit, interactable_actor_node_index)
end

return GrenadeInteraction
