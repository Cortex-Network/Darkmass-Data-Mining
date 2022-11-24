local BaseWeaponTraitBuffTemplates = require("scripts/settings/buff/weapon_traits_buff_templates/base_weapon_trait_buff_templates")
local BuffSettings = require("scripts/settings/buff/buff_settings")
local CheckProcFunctions = require("scripts/settings/buff/validation_functions/check_proc_functions")
local ConditionalFunctions = require("scripts/settings/buff/validation_functions/conditional_functions")
local stat_buffs = BuffSettings.stat_buffs
local proc_events = BuffSettings.proc_events
local templates = {
	weapon_trait_bespoke_chainsword_p1_increased_attack_cleave_on_multiple_hits = table.clone(BaseWeaponTraitBuffTemplates.increased_attack_cleave_on_multiple_hits),
	weapon_trait_bespoke_chainsword_p1_increased_melee_damage_on_multiple_hits = table.clone(BaseWeaponTraitBuffTemplates.increased_melee_damage_on_multiple_hits),
	weapon_trait_bespoke_chainsword_p1_infinite_melee_cleave_on_crit = table.clone(BaseWeaponTraitBuffTemplates.infinite_melee_cleave_on_crit),
	weapon_trait_bespoke_chainsword_p1_chained_hits_increases_melee_cleave_parent = table.clone(BaseWeaponTraitBuffTemplates.chained_hits_increases_melee_cleave_parent)
}
templates.weapon_trait_bespoke_chainsword_p1_chained_hits_increases_melee_cleave_parent.child_buff_template = "weapon_trait_bespoke_chainsword_p1_chained_hits_increases_melee_cleave_child"
templates.weapon_trait_bespoke_chainsword_p1_chained_hits_increases_melee_cleave_child = table.clone(BaseWeaponTraitBuffTemplates.chained_hits_increases_melee_cleave_child)
templates.weapon_trait_bespoke_chainsword_p1_chained_hits_increases_crit_chance_parent = table.clone(BaseWeaponTraitBuffTemplates.chained_hits_increases_crit_chance_parent)
templates.weapon_trait_bespoke_chainsword_p1_chained_hits_increases_crit_chance_parent.child_buff_template = "weapon_trait_bespoke_chainsword_p1_chained_hits_increases_crit_chance_child"
templates.weapon_trait_bespoke_chainsword_p1_chained_hits_increases_crit_chance_child = table.clone(BaseWeaponTraitBuffTemplates.chained_hits_increases_crit_chance_child)
templates.weapon_trait_bespoke_chainsword_p1_guaranteed_melee_crit_on_activated_kill = table.clone(BaseWeaponTraitBuffTemplates.guaranteed_melee_crit_on_activated_kill)
templates.weapon_trait_bespoke_chainsword_p1_guaranteed_melee_crit_on_activated_kill.buff_data.internal_buff_name = "weapon_trait_bespoke_chainsword_p1_guaranteed_melee_crit_on_activated_kill_effect"
templates.weapon_trait_bespoke_chainsword_p1_guaranteed_melee_crit_on_activated_kill_effect = table.clone(BaseWeaponTraitBuffTemplates.guaranteed_melee_crit_on_activated_kill_effect)
templates.weapon_trait_bespoke_chainsword_p1_bleed_on_activated_hit = table.clone(BaseWeaponTraitBuffTemplates.bleed_on_activated_hit)
templates.weapon_trait_bespoke_chainsword_p1_movement_speed_on_activation = table.clone(BaseWeaponTraitBuffTemplates.movement_speed_on_activation)
templates.weapon_trait_bespoke_chainsword_p1_movement_speed_on_activated_hit = {
	allow_proc_while_active = true,
	predicted = false,
	class_name = "proc_buff",
	active_duration = 4,
	proc_events = {
		[proc_events.on_hit] = 1
	},
	proc_stat_buffs = {
		[stat_buffs.movement_speed] = 1.5
	},
	conditional_proc_func = ConditionalFunctions.is_item_slot_wielded,
	check_proc_func = function (params, template_data, template_context)
		return ConditionalFunctions.is_item_slot_wielded(template_data, template_context) and CheckProcFunctions.on_melee_weapon_special_hit(params)
	end
}

return templates