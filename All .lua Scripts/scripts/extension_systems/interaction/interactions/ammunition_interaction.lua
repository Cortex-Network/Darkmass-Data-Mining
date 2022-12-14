require("scripts/extension_systems/interaction/interactions/pickup_interaction")

local Ammo = require("scripts/utilities/ammo")
local BuffSettings = require("scripts/settings/buff/buff_settings")
local DialogueSettings = require("scripts/settings/dialogue/dialogue_settings")
local Pickups = require("scripts/settings/pickup/pickups")
local Vo = require("scripts/utilities/vo")
local buff_proc_events = BuffSettings.proc_events
local AmmunitionInteraction = class("AmmunitionInteraction", "PickupInteraction")

function AmmunitionInteraction:stop(world, interactor_unit, unit_data_component, t, result, interactor_is_server)
	if interactor_is_server then
		local target_unit = unit_data_component.target_unit

		if result == "success" then
			local pickup_name = Unit.get_data(target_unit, "pickup_type")
			local pickup_data = Pickups.by_name[pickup_name]

			self:_add_ammo(interactor_unit, pickup_data)
			self:_trigger_sound(interactor_unit, pickup_data)
			self:_use_charge(target_unit, interactor_unit)
		end
	end
end

function AmmunitionInteraction:interactor_condition_func(interactor_unit, interactee_unit)
	local missing_ammo = not Ammo.ammo_is_full(interactor_unit)

	return missing_ammo and AmmunitionInteraction.super.interactor_condition_func(self, interactor_unit, interactee_unit)
end

function AmmunitionInteraction:hud_block_text(interactor_unit, interactee_unit, interactable_actor_node_index)
	local missing_ammo = not Ammo.ammo_is_full(interactor_unit)

	if not missing_ammo then
		if Ammo.uses_ammo(interactor_unit) then
			return "loc_action_interaction_inactive_ammo_full"
		else
			return "loc_action_interaction_inactive_no_ammo"
		end
	end

	return AmmunitionInteraction.super.hud_block_text(self, interactor_unit, interactee_unit, interactable_actor_node_index)
end

function AmmunitionInteraction:_add_ammo(interactor_unit, pickup_data)
	local unit_data_ext = ScriptUnit.extension(interactor_unit, "unit_data_system")
	local visual_loadout_extension = ScriptUnit.extension(interactor_unit, "visual_loadout_system")
	local weapon_slot_configuration = visual_loadout_extension:slot_configuration_by_type("weapon")

	for slot_name, config in pairs(weapon_slot_configuration) do
		local wieldable_component = unit_data_ext:write_component(slot_name)

		if wieldable_component.max_ammunition_reserve > 0 then
			local ammo_reserve = wieldable_component.current_ammunition_reserve
			local max_ammo_reserve = wieldable_component.max_ammunition_reserve
			local ammo_clip = wieldable_component.current_ammunition_clip
			local max_ammo_clip = wieldable_component.max_ammunition_clip
			local players_have_improved_keyword = false
			local side_system = Managers.state.extension:system("side_system")
			local side = side_system.side_by_unit[interactor_unit]
			local player_units = side.player_units
			local buff_keywords = BuffSettings.keywords

			for _, player_unit in pairs(player_units) do
				local buff_extension = ScriptUnit.has_extension(player_unit, "buff_system")

				if buff_extension then
					local improved_keyword = buff_extension:has_keyword(buff_keywords.improved_ammo_pickups)

					if improved_keyword then
						players_have_improved_keyword = true

						break
					end
				end
			end

			pickup_data.modifier = 1

			if players_have_improved_keyword and pickup_data.ammo_crate then
				local ability_extension = ScriptUnit.has_extension(interactor_unit, "ability_system")

				if ability_extension then
					local ability_type = "grenade_ability"
					local charges_restored = 100

					ability_extension:restore_ability_charge(ability_type, charges_restored)
				end
			end

			local pickup_amount = pickup_data.ammo_amount_func(max_ammo_reserve, max_ammo_clip, pickup_data)
			local missing_clip = max_ammo_clip - ammo_clip
			local new_ammo_amount = math.min(ammo_reserve + pickup_amount, max_ammo_reserve + missing_clip)
			wieldable_component.current_ammunition_reserve = new_ammo_amount
			local missing_player_ammo = max_ammo_reserve - ammo_reserve

			if missing_player_ammo < pickup_amount * DialogueSettings.ammo_hog_pickup_share and not pickup_data.ammo_crate then
				Vo.ammo_hog_event(interactor_unit, wieldable_component, pickup_data)
			end

			local buff_extension = ScriptUnit.has_extension(interactor_unit, "buff_system")

			if buff_extension then
				local param_table = buff_extension:request_proc_event_param_table()

				if param_table then
					param_table.pickup_amount = pickup_amount
					param_table.pickup_name = pickup_data.name
					param_table.new_ammo_amount = new_ammo_amount

					buff_extension:add_proc_event(buff_proc_events.on_ammo_pickup, param_table)
				end
			end
		end
	end
end

return AmmunitionInteraction
