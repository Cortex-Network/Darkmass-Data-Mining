local ActionHandler = require("scripts/utilities/action/action_handler")
local AbilityActionHandlerData = require("scripts/settings/ability/ability_action_handler_data")
local AbilityTemplates = require("scripts/settings/ability/ability_templates/ability_templates")
local FixedFrame = require("scripts/utilities/fixed_frame")
local ItemUtils = require("scripts/utilities/items")
local PlayerAbilities = require("scripts/settings/ability/player_abilities/player_abilities")
local PlayerCharacterConstants = require("scripts/settings/player_character/player_character_constants")
local PlayerUnitVisualLoadout = require("scripts/extension_systems/visual_loadout/utilities/player_unit_visual_loadout")
local EquippedAbilityEffectScripts = require("scripts/extension_systems/ability/utilities/equipped_ability_effect_scripts")
local MasterItems = require("scripts/backend/master_items")
local ability_configuration = PlayerCharacterConstants.ability_configuration
local PlayerUnitAbilityExtension = class("PlayerUnitAbilityExtension")

function PlayerUnitAbilityExtension:init(extension_init_context, unit, extension_init_data, ...)
	self._unit = unit
	local player = extension_init_data.player
	self._player = player
	local world = extension_init_context.world
	self._world = world
	local physics_world = extension_init_context.physics_world
	self._physics_world = physics_world
	local wwise_world = extension_init_context.wwise_world
	self._wwise_world = wwise_world
	self._initial_fixed_frame_t = extension_init_context.fixed_frame_t
	local first_person_extension = ScriptUnit.extension(unit, "first_person_system")
	self._first_person_extension = first_person_extension
	self._input_extension = ScriptUnit.extension(unit, "input_system")
	local unit_data = ScriptUnit.extension(unit, "unit_data_system")

	self:_init_action_components(unit_data)

	self._unit_data_extension = unit_data
	local is_server = extension_init_data.is_server
	self._is_server = is_server
	local is_local_unit = extension_init_data.is_local_unit
	self._is_local_unit = is_local_unit
	self._abilities = {}
	self._equipped_abilities = {}
	local action_handler = ActionHandler:new(unit, AbilityActionHandlerData)

	action_handler:add_component("combat_ability_action")
	action_handler:add_component("grenade_ability_action")

	self._action_handler = action_handler
	self._item_definitions = MasterItems.get_cached()
	self._equiped_ability_effect_scripts = {}
	self._equiped_ability_effect_scripts_context = {
		world = world,
		physics_world = physics_world,
		wwise_world = wwise_world,
		unit = unit,
		unit_data_extension = unit_data,
		is_local_unit = is_local_unit,
		is_server = is_server
	}
end

function PlayerUnitAbilityExtension:_init_action_components(unit_data_extension)
	local equipped_abilities_component = unit_data_extension:write_component("equipped_abilities")
	equipped_abilities_component.combat_ability = "none"
	equipped_abilities_component.grenade_ability = "none"
	self._equipped_abilities_component = equipped_abilities_component
	local combat_ability_component = unit_data_extension:write_component("combat_ability")
	local grenade_ability_component = unit_data_extension:write_component("grenade_ability")
	combat_ability_component.cooldown = 0
	combat_ability_component.num_charges = 0
	combat_ability_component.active = false
	combat_ability_component.enabled = true
	grenade_ability_component.cooldown = 0
	grenade_ability_component.num_charges = 0
	grenade_ability_component.active = false
	grenade_ability_component.enabled = true
	self._ability_components = {
		combat_ability = combat_ability_component,
		grenade_ability = grenade_ability_component
	}
end

function PlayerUnitAbilityExtension:extensions_ready(world, unit)
	local action_handler = self._action_handler
	local action_context = {}
	local unit_data_extension = self._unit_data_extension
	local first_person_extension = ScriptUnit.extension(unit, "first_person_system")
	local first_person_unit = first_person_extension:first_person_unit()
	local visual_loadout_extension = ScriptUnit.extension(unit, "visual_loadout_system")
	self._visual_loadout_extension = visual_loadout_extension
	self._buff_extension = ScriptUnit.extension(unit, "buff_system")
	action_context.first_person_unit = first_person_unit
	action_context.world = self._world
	action_context.physics_world = self._physics_world
	action_context.wwise_world = Managers.world:wwise_world(self._world)
	action_context.player_unit = self._unit
	action_context.is_server = self._is_server
	action_context.is_local_unit = self._is_local_unit
	action_context.unit_data_extension = unit_data_extension
	action_context.smart_targeting_extension = ScriptUnit.extension(unit, "smart_targeting_system")
	action_context.input_extension = self._input_extension
	action_context.first_person_extension = self._first_person_extension
	action_context.fx_extension = ScriptUnit.extension(unit, "fx_system")
	action_context.animation_extension = ScriptUnit.extension(unit, "animation_system")
	action_context.camera_extension = ScriptUnit.extension(unit, "camera_system")
	action_context.ability_extension = self
	action_context.dialogue_input = ScriptUnit.extension_input(unit, "dialogue_system")
	action_context.weapon_extension = ScriptUnit.extension(unit, "weapon_system")
	action_context.inventory_component = unit_data_extension:read_component("inventory")
	action_context.visual_loadout_extension = visual_loadout_extension
	action_context.first_person_component = unit_data_extension:read_component("first_person")
	action_context.sprint_character_state_component = unit_data_extension:read_component("sprint_character_state")
	action_context.locomotion_component = unit_data_extension:read_component("locomotion")
	action_context.movement_state_component = unit_data_extension:read_component("movement_state")

	action_handler:set_action_context(action_context)
end

function PlayerUnitAbilityExtension:on_player_unit_spawn(spawn_grenade_percentage)
	local ability_components = self._ability_components
	local grenade_component = ability_components.grenade_ability
	local num_charges = grenade_component.num_charges
	local num_spawn_charges = math.ceil(num_charges * spawn_grenade_percentage)
	grenade_component.num_charges = num_spawn_charges
end

function PlayerUnitAbilityExtension:on_player_unit_respawn(respawn_grenade_percentage)
	local ability_components = self._ability_components
	local grenade_component = ability_components.grenade_ability
	local num_charges = grenade_component.num_charges
	local num_respawn_charges = math.ceil(num_charges * respawn_grenade_percentage)
	grenade_component.num_charges = num_respawn_charges
end

function PlayerUnitAbilityExtension:equip_ability(ability_type, ability, fixed_t)
	self._equipped_abilities_component[ability_type] = ability.name

	self:_equip_ability(ability_type, ability, fixed_t)
end

function PlayerUnitAbilityExtension:unequip_ability(ability_type, fixed_t)
	local ability = self._equipped_abilities[ability_type]

	self:_unequip_ability(ability_type, ability, fixed_t)

	self._equipped_abilities_component[ability_type] = "none"
end

function PlayerUnitAbilityExtension:_equip_ability(ability_type, ability, fixed_t, from_server_correction)
	Log.info("PlayerUnitAbilityExtension", "Equipping ability %q of type %q%s", ability.name, ability_type, from_server_correction and " from server correction" or "")

	self._equipped_abilities[ability_type] = ability
	local inventory_item_name = ability.inventory_item_name
	from_server_correction = not not from_server_correction

	if ability.inventory_item_name then
		local item = self._item_definitions[inventory_item_name]
		local slot_name = self:get_slot_name(ability_type)

		if not from_server_correction then
			PlayerUnitVisualLoadout.equip_item_to_slot(self._unit, item, slot_name, nil, self._initial_fixed_frame_t)
		end
	else
		local component_name = ability_type .. "_action"
		local ability_template_name = ability.ability_template
		local ability_template = AbilityTemplates[ability_template_name]

		if not from_server_correction then
			self._action_handler:set_active_template(component_name, ability_template.name)
		end

		self._abilities[component_name] = {
			ability_template = ability_template,
			ability = ability,
			actions = {}
		}
		local equiped_ability_effect_scripts = {}
		self._equiped_ability_effect_scripts[ability_type] = equiped_ability_effect_scripts
		local equiped_ability_effect_scripts_context = self._equiped_ability_effect_scripts_context

		EquippedAbilityEffectScripts.create(equiped_ability_effect_scripts_context, equiped_ability_effect_scripts, ability_template, ability_type)
	end

	if not from_server_correction then
		local component = self._ability_components[ability_type]
		component.num_charges = self:_ability_max_charges(ability)
	end
end

function PlayerUnitAbilityExtension:_unequip_ability(ability_type, ability, fixed_t, from_server_correction)
	Log.info("PlayerUnitAbilityExtension", "Unequipping ability %q of type %q%s", ability.name, ability_type, from_server_correction and " from server correction" or "")

	local inventory_item_name = ability.inventory_item_name
	from_server_correction = not not from_server_correction

	if inventory_item_name then
		local slot_name = self:get_slot_name(ability_type)

		if not from_server_correction then
			PlayerUnitVisualLoadout.unequip_item_from_slot(self._unit, slot_name, fixed_t)
		end
	else
		local component_name = ability_type .. "_action"

		if not from_server_correction then
			self._action_handler:set_active_template(component_name, "none")
		end

		self._abilities[component_name] = nil
		local equiped_ability_effect_scripts = self._equiped_ability_effect_scripts[ability_type]

		EquippedAbilityEffectScripts.destroy(equiped_ability_effect_scripts)

		self._equiped_ability_effect_scripts[ability_type] = nil
	end

	self._equipped_abilities[ability_type] = nil
end

function PlayerUnitAbilityExtension:equipped_abilities()
	return self._equipped_abilities
end

function PlayerUnitAbilityExtension:ability_is_equipped(ability_type)
	return self._equipped_abilities[ability_type]
end

function PlayerUnitAbilityExtension:update(unit, dt, t)
	self._action_handler:update(dt, t)

	for ability_type, ability_effect_scripts in pairs(self._equiped_ability_effect_scripts) do
		EquippedAbilityEffectScripts.update(ability_effect_scripts, unit, dt, t)
	end
end

function PlayerUnitAbilityExtension:fixed_update(unit, dt, t, fixed_frame)
	self._action_handler:fixed_update(dt, t)
	self:_update_ability_cooldowns(t)

	for ability_type, ability_effect_scripts in pairs(self._equiped_ability_effect_scripts) do
		EquippedAbilityEffectScripts.fixed_update(ability_effect_scripts, unit, dt, t)
	end
end

function PlayerUnitAbilityExtension:post_update(unit, dt, t, fixed_frame)
	for ability_type, ability_effect_scripts in pairs(self._equiped_ability_effect_scripts) do
		EquippedAbilityEffectScripts.post_update(ability_effect_scripts, unit, dt, t)
	end
end

local action_params = {}

function PlayerUnitAbilityExtension:server_correction_occurred(unit, from_frame)
	table.clear(action_params)

	local equipped_abilities_component = self._equipped_abilities_component
	local from_server_correction = true
	local fixed_t = from_frame * GameParameters.fixed_time_step
	local locally_equipped_abilities = self._equipped_abilities

	for ability_type, _ in pairs(ability_configuration) do
		local server_authoritative_equipped_ability_name = equipped_abilities_component[ability_type]
		local locally_equipped_ability = locally_equipped_abilities[ability_type]
		local locally_equipped_ability_name = locally_equipped_ability and locally_equipped_ability.name or "none"

		if locally_equipped_ability_name ~= server_authoritative_equipped_ability_name then
			if locally_equipped_ability_name ~= "none" then
				self:_unequip_ability(ability_type, locally_equipped_ability, fixed_t, from_server_correction)
			end

			if server_authoritative_equipped_ability_name ~= "none" then
				local ability = PlayerAbilities[server_authoritative_equipped_ability_name]

				self:_equip_ability(ability_type, ability, fixed_t, from_server_correction)
			end
		end
	end

	for id, data in pairs(self._abilities) do
		local action_objects, actions = nil
		action_objects = data.actions
		actions = data.ability_template.actions

		self._action_handler:server_correction_occurred(id, action_objects, action_params, actions)
	end
end

function PlayerUnitAbilityExtension:stop_action(reason, data, t)
	self._action_handler:stop_action("combat_ability_action", reason, data, t)
end

local temp_table = {}

function PlayerUnitAbilityExtension:_condition_func_params()
	table.clear(temp_table)

	temp_table.ability_extension = self
	temp_table.unit_data_extension = self._unit_data_extension

	return temp_table
end

function PlayerUnitAbilityExtension:update_ability_actions(fixed_frame)
	table.clear(action_params)

	local condition_func_params = self:_condition_func_params()
	local abilities = self._abilities
	local unit_data_extension = self._unit_data_extension

	for component_name, data in pairs(abilities) do
		local component = unit_data_extension:read_component(component_name)
		action_params.ability = data.ability
		local template_name = component.template_name

		if template_name ~= "none" then
			local action_objects = data.actions
			local actions = data.ability_template.actions

			self._action_handler:update_actions(fixed_frame, component_name, condition_func_params, actions, action_objects, action_params)
		end
	end
end

function PlayerUnitAbilityExtension:_update_ability_cooldowns(t)
	local ability_components = self._ability_components
	local abilities = self._equipped_abilities

	for ability_type, component in pairs(ability_components) do
		local ability = abilities[ability_type]

		if ability and ability.cooldown then
			local current_charges = self:remaining_ability_charges(ability_type)
			local cooldown = component.cooldown
			local max_charges = self:_ability_max_charges(ability)

			if current_charges < max_charges and cooldown == 0 then
				local ability_cooldown = self:max_ability_cooldown(ability_type)
				cooldown = t + ability_cooldown
			end

			if cooldown ~= 0 and cooldown < t then
				component.num_charges = math.min(max_charges, component.num_charges + 1)
				cooldown = 0
			end

			component.cooldown = cooldown
		end
	end
end

function PlayerUnitAbilityExtension:can_wield(slot_name, previous_check)
	for ability_type, ability_slot_name in pairs(ability_configuration) do
		if ability_slot_name == slot_name then
			local equipped_abilities = self._equipped_abilities
			local ability = equipped_abilities[ability_type]
			local can_be_wielded_when_depleted = ability.can_be_wielded_when_depleted
			local can_be_previously_wielded_to = not previous_check or ability.can_be_previously_wielded_to

			return self:remaining_ability_charges(ability_type) > 0 and can_be_previously_wielded_to or can_be_wielded_when_depleted and can_be_previously_wielded_to
		end
	end

	return true
end

function PlayerUnitAbilityExtension:set_ability_enabled(ability_type, enable)
	local ability_components = self._ability_components
	local component = ability_components[ability_type]
	component.enabled = enable
end

function PlayerUnitAbilityExtension:ability_enabled(ability_type)
	local ability_components = self._ability_components
	local component = ability_components[ability_type]

	return component.enabled
end

function PlayerUnitAbilityExtension:can_use_ability(ability_type)
	local enabled = self:ability_enabled(ability_type)

	if not enabled then
		return false
	end

	if self:remaining_ability_charges(ability_type) <= 0 then
		return false
	end

	local abilities = self._equipped_abilities
	local ability = abilities[ability_type]
	local required_weapon_type = ability.required_weapon_type

	if required_weapon_type and required_weapon_type == "ranged" then
		local item_in_primary_slot = self._visual_loadout_extension:item_in_slot("slot_primary")
		local item_in_secondary_slot = self._visual_loadout_extension:item_in_slot("slot_secondary")
		local has_ranged_weapon = ItemUtils.is_weapon_template_ranged(item_in_primary_slot) or ItemUtils.is_weapon_template_ranged(item_in_secondary_slot)

		if not has_ranged_weapon then
			return false
		end
	end

	return true
end

function PlayerUnitAbilityExtension:has_ability_type(ability_type)
	local abilities = self._equipped_abilities
	local ability = abilities[ability_type]
	local has_ability_type = ability and true or false

	return has_ability_type
end

function PlayerUnitAbilityExtension:action_input_is_currently_valid(component_name, action_input, used_input, current_fixed_t)
	local abilities = self._abilities
	local ability_data = abilities[component_name]
	local ability_template = ability_data.ability_template
	local actions = ability_template.actions
	local condition_func_params = self:_condition_func_params()

	return self._action_handler:action_input_is_currently_valid(component_name, actions, condition_func_params, current_fixed_t, action_input, used_input)
end

function PlayerUnitAbilityExtension:remaining_ability_cooldown(ability_type)
	local enabled = self:ability_enabled(ability_type)

	if not enabled then
		return math.huge
	end

	local ability_components = self._ability_components
	local component = ability_components[ability_type]
	local cooldown = component.cooldown
	local fixed_frame_t = FixedFrame.get_latest_fixed_time()
	local remaining_cooldown = math.max(cooldown - fixed_frame_t, 0)

	return remaining_cooldown
end

function PlayerUnitAbilityExtension:max_ability_cooldown(ability_type)
	local abilities = self._equipped_abilities
	local ability = abilities[ability_type]
	local stat_buffs = self._buff_extension:stat_buffs()
	local ability_cooldown_flat_reduction = stat_buffs.ability_cooldown_flat_reduction or 0
	local ability_cooldown_modifier = stat_buffs.ability_cooldown_modifier or 1
	local max_ability_cooldown = math.max(0, ability.cooldown * ability_cooldown_modifier - ability_cooldown_flat_reduction)

	return max_ability_cooldown
end

function PlayerUnitAbilityExtension:remaining_ability_charges(ability_type)
	local enabled = self:ability_enabled(ability_type)

	if not enabled then
		return 0
	end

	local ability_components = self._ability_components
	local component = ability_components[ability_type]
	local charges = component.num_charges

	return charges
end

function PlayerUnitAbilityExtension:missing_ability_charges(ability_type)
	local max_charges = self:max_ability_charges(ability_type)
	local remaining_ability_charges = self:remaining_ability_charges(ability_type)
	local missing_charges = max_charges - remaining_ability_charges

	return missing_charges
end

function PlayerUnitAbilityExtension:max_ability_charges(ability_type)
	local equipped_abilities = self._equipped_abilities
	local ability = equipped_abilities[ability_type]
	local max_charges = self:_ability_max_charges(ability)

	return max_charges
end

function PlayerUnitAbilityExtension:_ability_max_charges(ability)
	local max_charges = ability.max_charges
	local ability_stat_buff = ability.stat_buff

	if ability_stat_buff then
		local stat_buffs = self._buff_extension:stat_buffs()
		local buff_amount = stat_buffs[ability_stat_buff]
		max_charges = max_charges + buff_amount
	end

	return max_charges
end

function PlayerUnitAbilityExtension:restore_ability_charge(ability_type, num_charges_restored)
	local ability_component = self._ability_components[ability_type]
	local equipped_abilities = self._equipped_abilities
	local ability = equipped_abilities[ability_type]
	local max_charges = self:_ability_max_charges(ability)
	ability_component.num_charges = math.clamp(ability_component.num_charges + num_charges_restored, 0, max_charges)
end

function PlayerUnitAbilityExtension:set_ability_charges(ability_type, num_charges)
	local ability_component = self._ability_components[ability_type]
	local equipped_abilities = self._equipped_abilities
	local ability = equipped_abilities[ability_type]
	local max_charges = self:_ability_max_charges(ability)
	ability_component.num_charges = math.clamp(num_charges, 0, max_charges)
end

function PlayerUnitAbilityExtension:reduce_ability_cooldown_percentage(ability_type, reduce_percetage)
	local max_cooldown = self:max_ability_cooldown(ability_type)
	local reduce_time = reduce_percetage * max_cooldown

	self:reduce_ability_cooldown_time(ability_type, reduce_time)
end

function PlayerUnitAbilityExtension:reduce_ability_cooldown_time(ability_type, reduce_time)
	local ability_component = self._ability_components[ability_type]
	local current_cool_down = ability_component.cooldown
	local new_cooldown = current_cool_down - reduce_time
	local fixed_frame_t = FixedFrame.get_latest_fixed_time()
	new_cooldown = math.max(new_cooldown, fixed_frame_t)
	ability_component.cooldown = new_cooldown
end

function PlayerUnitAbilityExtension:use_ability_charge(ability_type)
	local ability_components = self._ability_components
	local component = ability_components[ability_type]
	local equipped_abilities_component = self._equipped_abilities_component
	local ability_name = equipped_abilities_component[ability_type]

	if ability_type == "combat_ability" then
		Managers.telemetry_reporters:reporter("combat_ability"):register_event(self._player, ability_name)
	elseif ability_type == "grenade_ability" then
		Managers.telemetry_reporters:reporter("grenade_ability"):register_event(self._player, ability_name)
	end

	component.num_charges = math.max(component.num_charges - 1, 0)
end

function PlayerUnitAbilityExtension:wanted_character_state_transition()
	return self._action_handler:wanted_character_state_transition()
end

function PlayerUnitAbilityExtension:get_slot_name(ability_type)
	return "slot_" .. ability_type
end

return PlayerUnitAbilityExtension
