local AttackSettings = require("scripts/settings/damage/attack_settings")
local Action = require("scripts/utilities/weapon/action")
local Breed = require("scripts/utilities/breed")
local BuffSettings = require("scripts/settings/buff/buff_settings")
local InteractionSettings = require("scripts/settings/interaction/interaction_settings")
local Stamina = require("scripts/utilities/attack/stamina")
local Stun = require("scripts/utilities/attack/stun")
local attack_types = AttackSettings.attack_types
local stat_buff_types = BuffSettings.stat_buffs
local buff_keywords = BuffSettings.keywords
local DEFAULT_BLOCK_BREAK_DISORIENTATION_TYPE = "block_broken"
local _block_buff_modifier, _calculate_block_angle, _get_block_angles, _get_block_cost = nil
local Block = {}
local auto_block_interactions = {
	revive = true,
	rescue = true
}
local default_block_types = {
	[attack_types.melee] = true
}
local default_block_angles = {
	inner = 0.33 * math.pi,
	outer = math.pi
}

function Block.is_blocking(target_unit, attacking_unit, attack_type, weapon_template, is_server)
	local unit_data_extension = ScriptUnit.has_extension(target_unit, "unit_data_system")

	if not unit_data_extension then
		return false
	end

	local breed = unit_data_extension:breed()

	if not Breed.is_player(breed) then
		return false
	end

	local block_component = unit_data_extension:read_component("block")
	local is_blocking = block_component.is_blocking

	if is_server and not is_blocking then
		local interaction_component = unit_data_extension:read_component("interaction")
		local is_interacting = interaction_component.state == InteractionSettings.states.is_interacting

		if is_interacting then
			local interaction_type = interaction_component.type
			local should_block = interaction_type and auto_block_interactions[interaction_type]

			if should_block then
				local specialization = unit_data_extension:specialization()
				local specialization_stamina_template = specialization.stamina
				local stamina_write_component = unit_data_extension:write_component("stamina")
				local current_stamina = Stamina.current_and_max_value(target_unit, stamina_write_component, specialization_stamina_template)

				if current_stamina > 0 then
					is_blocking = true
				end
			end
		end
	end

	if not is_blocking then
		return false
	end

	local weapon_action_component = unit_data_extension:read_component("weapon_action")
	local _, action_setting = Action.current_action(weapon_action_component, weapon_template)
	local block_types = action_setting and action_setting.block_attack_types or default_block_types
	local can_block = block_types[attack_type]

	if attack_type == attack_types.ranged then
		local buff_extension = ScriptUnit.has_extension(target_unit, "buff_system")
		local can_block_ranged_keyword = buff_extension and buff_extension:has_keyword(buff_keywords.can_block_ranged)

		if can_block_ranged_keyword then
			can_block = true
		end
	end

	if can_block then
		local weapon_extension = ScriptUnit.has_extension(target_unit, "weapon_system")
		local stamina_template = weapon_extension and weapon_extension:stamina_template()
		local block_angles = _get_block_angles(weapon_template, attack_type)
		local block_angle = _calculate_block_angle(target_unit, attacking_unit, unit_data_extension)
		local is_within_inner_angle = block_angles.inner and block_angle <= block_angles.inner
		local is_within_outer_angle = block_angles.outer and block_angle <= block_angles.outer
		local has_block_cost = not not _get_block_cost(attack_type, stamina_template, is_within_inner_angle)
		can_block = (is_within_inner_angle or is_within_outer_angle) and has_block_cost
	end

	return can_block
end

function Block.attack_is_blockable(damage_profile, target_unit, weapon_template)
	local unit_data_extension = ScriptUnit.has_extension(target_unit, "unit_data_system")
	local weapon_action_component = unit_data_extension:read_component("weapon_action")
	local _, action_setting = Action.current_action(weapon_action_component, weapon_template)
	local block_unblockable = action_setting and action_setting.block_unblockable
	local block_goes_brrr = action_setting and action_setting.block_goes_brrr

	return block_unblockable or block_goes_brrr or not damage_profile.unblockable
end

function Block.attempt_block_break(target_unit, attacking_unit, hit_world_position, attack_type, attack_direction, weapon_template, damage_profile)
	local unit_data_extension = ScriptUnit.has_extension(target_unit, "unit_data_system")
	local weapon_extension = ScriptUnit.extension(target_unit, "weapon_system")
	local stamina_template = weapon_extension:stamina_template()
	local buff_extension = ScriptUnit.has_extension(target_unit, "buff_system")
	local block_cost = math.huge

	if stamina_template then
		local block_buff_modifier = _block_buff_modifier(buff_extension, attack_type)
		local block_damage_modifier = damage_profile.block_cost_multiplier or 1
		local block_modifier = block_buff_modifier * block_damage_modifier
		local block_angles = _get_block_angles(weapon_template, attack_type)
		local block_angle = _calculate_block_angle(target_unit, attacking_unit, unit_data_extension)
		local is_within_inner_angle = block_angles.inner and block_angle <= block_angles.inner
		block_cost = _get_block_cost(attack_type, stamina_template, is_within_inner_angle) * block_modifier
	end

	local weapon_action_component = unit_data_extension:read_component("weapon_action")
	local _, action_setting = Action.current_action(weapon_action_component, weapon_template)

	if action_setting and action_setting.parry_block then
		block_cost = math.clamp(block_cost, 0, 2)
	end

	if action_setting and action_setting.block_goes_brrr then
		block_cost = 0
	end

	if buff_extension then
		local use_warp_charge = buff_extension:has_keyword(buff_keywords.block_gives_warp_charge)

		if use_warp_charge and block_cost > 0 then
			local stamina_write_component = unit_data_extension:write_component("stamina")
			local warp_charge_component = unit_data_extension:write_component("warp_charge")
			local specialization = unit_data_extension:specialization()
			local specialization_stamina_template = specialization.stamina
			local _, max_stamina = Stamina.current_and_max_value(target_unit, stamina_write_component, specialization_stamina_template)
			local current_warp_charge = warp_charge_component.current_percentage

			if current_warp_charge < 0.9 then
				local stat_buffs = buff_extension:stat_buffs()
				local warp_charge_efficiency_multiplier = stat_buffs.warp_charge_block_cost
				local percentage_of_stamina = block_cost / max_stamina
				local sum = current_warp_charge + percentage_of_stamina * warp_charge_efficiency_multiplier
				local new_warp_charge_percentage = math.min(sum, 0.9)
				local excess = sum - 0.9

				if excess > 0 then
					block_cost = excess * 1 / warp_charge_efficiency_multiplier * max_stamina
				else
					block_cost = 0
				end

				warp_charge_component.current_percentage = new_warp_charge_percentage
			end
		end
	end

	local t = Managers.state.extension:latest_fixed_t()
	local _, stamina_depleted = Stamina.drain(target_unit, block_cost, t)
	local block_broken = stamina_depleted

	if block_broken then
		local weapon_disorientation_type = stamina_template and stamina_template.block_break_disorientation_type or DEFAULT_BLOCK_BREAK_DISORIENTATION_TYPE
		local damage_disorientation_type = damage_profile.block_broken_disorientation_type
		local disorientation_type = damage_disorientation_type or weapon_disorientation_type

		Stun.apply(target_unit, disorientation_type, attack_direction, weapon_template, true, false)
	end

	local unit_id = Managers.state.unit_spawner:game_object_id(target_unit)
	local attacking_unit_id = Managers.state.unit_spawner:game_object_id(attacking_unit)
	local weapon_template_id = NetworkLookup.weapon_templates[weapon_template.name]
	local attack_type_id = NetworkLookup.attack_types[attack_type]

	Block.player_blocked_attack(target_unit, attacking_unit, hit_world_position, block_broken, weapon_template, attack_type)
	Managers.state.game_session:send_rpc_clients("rpc_player_blocked_attack", unit_id, attacking_unit_id, hit_world_position, block_broken, weapon_template_id, attack_type_id)

	return block_broken
end

function Block.player_blocked_attack(target_unit, attacking_unit, hit_world_position, block_broken, weapon_template, attack_type)
	local player_unit_spawn_manager = Managers.state.player_unit_spawn
	local player = player_unit_spawn_manager:owner(target_unit)

	if not player then
		return
	end

	local weapon_extension = ScriptUnit.has_extension(target_unit, "weapon_system")

	if weapon_extension then
		weapon_extension:blocked_attack(attacking_unit, hit_world_position, block_broken, weapon_template, attack_type)
	end
end

function _block_buff_modifier(buff_extension, attack_type)
	if not buff_extension then
		return 1
	end

	local stat_buffs = buff_extension:stat_buffs()
	local block_cost_multiplier = stat_buffs[stat_buff_types.block_cost_multiplier] or 1
	local block_cost_modifier = stat_buffs[stat_buff_types.block_cost_modifier] or 1
	local block_cost_buff_modifier = block_cost_multiplier * block_cost_modifier
	local is_ranged = attack_type == attack_types.ranged
	local ranged_block_cost_multipier = is_ranged and stat_buffs[stat_buff_types.block_cost_ranged_multiplier] or 1
	local ranged_block_cost_modifier = is_ranged and stat_buffs[stat_buff_types.block_cost_ranged_modifier] or 1
	local ranged_block_cost_buff_modifier = ranged_block_cost_multipier * ranged_block_cost_modifier

	return block_cost_buff_modifier * ranged_block_cost_buff_modifier
end

function _get_block_cost(attack_type, stamina_template, is_inner)
	if not stamina_template then
		return nil
	end

	local block_cost_group = nil

	if attack_type == attack_types.melee and stamina_template.block_cost_melee then
		block_cost_group = stamina_template.block_cost_melee
	elseif attack_type == attack_types.ranged and stamina_template.block_cost_ranged then
		block_cost_group = stamina_template.block_cost_ranged
	else
		block_cost_group = stamina_template.block_cost_default
	end

	if not block_cost_group then
		return nil
	end

	return is_inner and block_cost_group.inner or block_cost_group.outer
end

function _get_block_angles(weapon_template, attack_type)
	local weapon_block_angles = weapon_template.block_angles
	local weapon_default_block_angles = weapon_block_angles and weapon_block_angles.default
	local weapon_actack_type_block_angles = weapon_block_angles and weapon_block_angles[attack_type]

	return weapon_actack_type_block_angles or weapon_default_block_angles or default_block_angles
end

function _calculate_block_angle(target_unit, attacking_unit, target_unit_data_extension)
	if not attacking_unit then
		return 0
	end

	local target_position = POSITION_LOOKUP[target_unit]
	local attacking_position = POSITION_LOOKUP[attacking_unit]
	local attack_check_direction = Vector3.normalize(attacking_position - target_position)
	local target_forward = nil

	if target_unit_data_extension then
		local first_person_component = target_unit_data_extension:read_component("first_person")
		local first_person_rotation = first_person_component.rotation
		target_forward = Quaternion.forward(first_person_rotation)
	else
		local target_rotation = Unit.world_rotation(target_unit, 1)
		target_forward = Quaternion.forward(target_rotation)
	end

	local angle = Vector3.angle(attack_check_direction, target_forward)

	return angle
end

return Block
