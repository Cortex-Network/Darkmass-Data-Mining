require("scripts/extension_systems/weapon/actions/action_weapon_base")

local Attack = require("scripts/utilities/attack/attack")
local AttackSettings = require("scripts/settings/damage/attack_settings")
local Breed = require("scripts/utilities/breed")
local Explosion = require("scripts/utilities/attack/explosion")
local Health = require("scripts/utilities/health")
local Overheat = require("scripts/utilities/overheat")
local PlayerUnitStatus = require("scripts/utilities/attack/player_unit_status")
local WarpCharge = require("scripts/utilities/warp_charge")
local attack_types = AttackSettings.attack_types
local attack_results = AttackSettings.attack_results
local ActionOverloadExplosion = class("ActionOverloadExplosion", "ActionWeaponBase")
local DEFAULT_POWER_LEVEL = 2000

function ActionOverloadExplosion:init(action_context, action_params, ...)
	ActionOverloadExplosion.super.init(self, action_context, action_params, ...)

	local weapon = action_params.weapon
	self._on_start_source_name = weapon.fx_sources._overheat
	self._exploding_character_state_component = action_context.unit_data_extension:write_component("exploding_character_state")
end

function ActionOverloadExplosion:start(action_settings, ...)
	ActionOverloadExplosion.super.start(self, action_settings, ...)

	local sfx = action_settings.sfx
	local on_start_sfx = sfx and sfx.on_start

	if on_start_sfx then
		local sync_to_clients = true
		local external_properties = nil

		self._fx_extension:trigger_gear_wwise_event_with_source(on_start_sfx, external_properties, self._on_start_source_name, sync_to_clients)
	end
end

function ActionOverloadExplosion:fixed_update(dt, t, time_in_action)
	ActionOverloadExplosion.super.fixed_update(self, dt, t, time_in_action)

	if self._is_server then
		local action_settings = self._action_settings
		local dot_settings = action_settings.dot_settings

		if dot_settings then
			local damage_frequency = dot_settings.damage_frequency
			local this_frame_time = time_in_action % damage_frequency
			local previous_frame_time = math.max(time_in_action - dt, 0) % damage_frequency
			local time_to_do_damage = this_frame_time < previous_frame_time

			if time_to_do_damage then
				local damage_profile = dot_settings.damage_profile
				local player_unit = self._player_unit
				local power_level = dot_settings.power_level
				local weapon_item = self._weapon.item

				Attack.execute(player_unit, damage_profile, "power_level", power_level, "item", weapon_item)
			end
		end
	end
end

function ActionOverloadExplosion:finish(reason, data, t, time_in_action)
	ActionOverloadExplosion.super.finish(self, reason, data, t, time_in_action)

	if reason == "psyker_ability" then
		return
	end

	self:_explode(self._action_settings)

	local state_component = self._exploding_character_state_component
	local unit_data_extension = self._unit_data_extension

	if state_component.reason == "overheat" then
		local slot_name = state_component.slot_name
		local inventory_slot_component = unit_data_extension:write_component(slot_name)

		Overheat.clear(inventory_slot_component)
	elseif state_component.reason == "warp_charge" then
		local warp_charge_component = unit_data_extension:write_component("warp_charge")

		WarpCharge.clear(warp_charge_component)
	end
end

local explosion_results = {}

function ActionOverloadExplosion:_explode(action_settings)
	if self._is_server then
		local explosion_template = action_settings.explosion_template
		local position = self._locomotion_component.position
		local impact_normal = nil
		local power_level = DEFAULT_POWER_LEVEL
		local charge_level = 1

		table.clear(explosion_results)

		local is_critical_strike = false
		local ignore_cover = false
		local weapon = self._weapon
		local item = weapon and weapon.item
		local wielded_slot = weapon and self._inventory_component.wielded_slot

		Explosion.create_explosion(self._world, self._physics_world, position, impact_normal, self._player_unit, explosion_template, power_level, charge_level, attack_types.explosion, is_critical_strike, ignore_cover, item, wielded_slot, explosion_results)
		self:_handle_exposion_stats(explosion_results)
	end

	if action_settings.death_on_explosion then
		local unit = self._player_unit
		local health_percentage = Health.current_health_percent(unit)
		local unit_data_extension = ScriptUnit.extension(unit, "unit_data_system")
		local character_state_component = unit_data_extension:read_component("character_state")
		local is_knocked_down = PlayerUnitStatus.is_knocked_down(character_state_component)
		local is_alive = health_percentage > 0 and not is_knocked_down

		if is_alive then
			Attack.execute(unit, action_settings.death_damage_profile, "instakill", true, "damage_type", action_settings.death_damage_type, "item", nil)
		end
	end
end

function ActionOverloadExplosion:_handle_exposion_stats(explosion_attack_result_table)
	if Managers.stats.can_record_stats() then
		local player = self._player
		local difficulty = Managers.state.difficulty:get_difficulty()

		if difficulty >= 3 then
			local count = 0

			for hit_unit, attack_result in pairs(explosion_attack_result_table) do
				if attack_result == attack_results.died then
					local breed = Breed.unit_breed_or_nil(hit_unit)

					if breed and breed.tags and breed.tags.elite then
						count = count + 1
					end
				end
			end

			if count >= 3 then
				Managers.achievements:trigger_event(player:account_id(), player:character_id(), "psyker_2_perils_of_the_warp_elite_kills_event")
			end
		end
	end
end

return ActionOverloadExplosion
