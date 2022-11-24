local templates = {}

local function _create_entry(path)
	local entry_templates = require(path)

	for name, template in pairs(entry_templates) do
		templates[name] = template
	end
end

_create_entry("scripts/settings/buff/boon_buff_templates")
_create_entry("scripts/settings/buff/common_buff_templates")
_create_entry("scripts/settings/buff/gadget_buff_templates")
_create_entry("scripts/settings/buff/item_buff_templates")
_create_entry("scripts/settings/buff/liquid_area_buff_templates")
_create_entry("scripts/settings/buff/minion_buff_templates")
_create_entry("scripts/settings/buff/mission_objective_buff_templates")
_create_entry("scripts/settings/buff/mutator_buff_templates")
_create_entry("scripts/settings/buff/player_buff_templates")
_create_entry("scripts/settings/buff/training_grounds_buff_templates")
_create_entry("scripts/settings/buff/weapon_buff_templates")
_create_entry("scripts/settings/buff/weapon_traits_buff_templates/weapon_trait_buff_templates")
_create_entry("scripts/settings/buff/weapon_traits_buff_templates/weapon_traits_buff_examples")
_create_entry("scripts/settings/buff/weapon_traits_buff_templates/weapon_traits_melee_activated_buff_templates")
_create_entry("scripts/settings/buff/weapon_traits_buff_templates/weapon_traits_melee_common_buff_templates")
_create_entry("scripts/settings/buff/weapon_traits_buff_templates/weapon_traits_ranged_aimed_buff_templates")
_create_entry("scripts/settings/buff/weapon_traits_buff_templates/weapon_traits_ranged_common_buff_templates")
_create_entry("scripts/settings/buff/weapon_traits_buff_templates/weapon_traits_ranged_explosive_buff_templates")
_create_entry("scripts/settings/buff/weapon_traits_buff_templates/weapon_traits_ranged_overheat_buff_templates")
_create_entry("scripts/settings/buff/weapon_traits_buff_templates/weapon_traits_ranged_warp_charge_buff_templates")
_create_entry("scripts/settings/buff/weapon_traits_buff_templates/weapon_traits_bespoke_autogun_p1_buff_templates")
_create_entry("scripts/settings/buff/weapon_traits_buff_templates/weapon_traits_bespoke_autogun_p2_buff_templates")
_create_entry("scripts/settings/buff/weapon_traits_buff_templates/weapon_traits_bespoke_autogun_p3_buff_templates")
_create_entry("scripts/settings/buff/weapon_traits_buff_templates/weapon_traits_bespoke_autopistol_p1_buff_templates")
_create_entry("scripts/settings/buff/weapon_traits_buff_templates/weapon_traits_bespoke_bolter_p1_buff_templates")
_create_entry("scripts/settings/buff/weapon_traits_buff_templates/weapon_traits_bespoke_chainaxe_p1_buff_templates")
_create_entry("scripts/settings/buff/weapon_traits_buff_templates/weapon_traits_bespoke_chainsword_p1_buff_templates")
_create_entry("scripts/settings/buff/weapon_traits_buff_templates/weapon_traits_bespoke_chainsword_2h_p1_buff_templates")
_create_entry("scripts/settings/buff/weapon_traits_buff_templates/weapon_traits_bespoke_combataxe_p1_buff_templates")
_create_entry("scripts/settings/buff/weapon_traits_buff_templates/weapon_traits_bespoke_combataxe_p2_buff_templates")
_create_entry("scripts/settings/buff/weapon_traits_buff_templates/weapon_traits_bespoke_combataxe_p3_buff_templates")
_create_entry("scripts/settings/buff/weapon_traits_buff_templates/weapon_traits_bespoke_combatknife_p1_buff_templates")
_create_entry("scripts/settings/buff/weapon_traits_buff_templates/weapon_traits_bespoke_combatsword_p1_buff_templates")
_create_entry("scripts/settings/buff/weapon_traits_buff_templates/weapon_traits_bespoke_combatsword_p2_buff_templates")
_create_entry("scripts/settings/buff/weapon_traits_buff_templates/weapon_traits_bespoke_combatsword_p3_buff_templates")
_create_entry("scripts/settings/buff/weapon_traits_buff_templates/weapon_traits_bespoke_flamer_p1_buff_templates")
_create_entry("scripts/settings/buff/weapon_traits_buff_templates/weapon_traits_bespoke_forcestaff_p1_buff_templates")
_create_entry("scripts/settings/buff/weapon_traits_buff_templates/weapon_traits_bespoke_forcestaff_p2_buff_templates")
_create_entry("scripts/settings/buff/weapon_traits_buff_templates/weapon_traits_bespoke_forcestaff_p3_buff_templates")
_create_entry("scripts/settings/buff/weapon_traits_buff_templates/weapon_traits_bespoke_forcestaff_p4_buff_templates")
_create_entry("scripts/settings/buff/weapon_traits_buff_templates/weapon_traits_bespoke_forcesword_p1_buff_templates")
_create_entry("scripts/settings/buff/weapon_traits_buff_templates/weapon_traits_bespoke_lasgun_p1_buff_templates")
_create_entry("scripts/settings/buff/weapon_traits_buff_templates/weapon_traits_bespoke_lasgun_p2_buff_templates")
_create_entry("scripts/settings/buff/weapon_traits_buff_templates/weapon_traits_bespoke_lasgun_p3_buff_templates")
_create_entry("scripts/settings/buff/weapon_traits_buff_templates/weapon_traits_bespoke_laspistol_p1_buff_templates")
_create_entry("scripts/settings/buff/weapon_traits_buff_templates/weapon_traits_bespoke_ogryn_club_p1_buff_templates")
_create_entry("scripts/settings/buff/weapon_traits_buff_templates/weapon_traits_bespoke_ogryn_club_p2_buff_templates")
_create_entry("scripts/settings/buff/weapon_traits_buff_templates/weapon_traits_bespoke_ogryn_combatblade_p1_buff_templates")
_create_entry("scripts/settings/buff/weapon_traits_buff_templates/weapon_traits_bespoke_ogryn_gauntlet_p1_buff_templates")
_create_entry("scripts/settings/buff/weapon_traits_buff_templates/weapon_traits_bespoke_ogryn_heavystubber_p1_buff_templates")
_create_entry("scripts/settings/buff/weapon_traits_buff_templates/weapon_traits_bespoke_ogryn_powermaul_p1_buff_templates")
_create_entry("scripts/settings/buff/weapon_traits_buff_templates/weapon_traits_bespoke_ogryn_powermaul_slabshield_p1_buff_templates")
_create_entry("scripts/settings/buff/weapon_traits_buff_templates/weapon_traits_bespoke_ogryn_rippergun_p1_buff_templates")
_create_entry("scripts/settings/buff/weapon_traits_buff_templates/weapon_traits_bespoke_ogryn_thumper_p1_buff_templates")
_create_entry("scripts/settings/buff/weapon_traits_buff_templates/weapon_traits_bespoke_ogryn_thumper_p2_buff_templates")
_create_entry("scripts/settings/buff/weapon_traits_buff_templates/weapon_traits_bespoke_plasmagun_p1_buff_templates")
_create_entry("scripts/settings/buff/weapon_traits_buff_templates/weapon_traits_bespoke_powermaul_2h_p1_buff_templates")
_create_entry("scripts/settings/buff/weapon_traits_buff_templates/weapon_traits_bespoke_powermaul_p1_buff_templates")
_create_entry("scripts/settings/buff/weapon_traits_buff_templates/weapon_traits_bespoke_powersword_p1_buff_templates")
_create_entry("scripts/settings/buff/weapon_traits_buff_templates/weapon_traits_bespoke_shotgun_p1_buff_templates")
_create_entry("scripts/settings/buff/weapon_traits_buff_templates/weapon_traits_bespoke_stubrevolver_p1_buff_templates")
_create_entry("scripts/settings/buff/weapon_traits_buff_templates/weapon_traits_bespoke_thunderhammer_2h_p1_buff_templates")
_create_entry("scripts/settings/buff/player_archetype_specialization/common_player_specialization_buffs")
_create_entry("scripts/settings/buff/player_archetype_specialization/ogryn_buff_templates")
_create_entry("scripts/settings/buff/player_archetype_specialization/ogryn_bonebreaker_buff_templates")
_create_entry("scripts/settings/buff/player_archetype_specialization/psyker_buff_templates")
_create_entry("scripts/settings/buff/player_archetype_specialization/psyker_biomancer_buff_templates")
_create_entry("scripts/settings/buff/player_archetype_specialization/veteran_buff_templates")
_create_entry("scripts/settings/buff/player_archetype_specialization/veteran_ranger_buff_templates")
_create_entry("scripts/settings/buff/player_archetype_specialization/zealot_buff_templates")
_create_entry("scripts/settings/buff/player_archetype_specialization/zealot_maniac_buff_templates")

local default_buff_icon = "content/ui/materials/icons/abilities/default"

for buff_name, template in pairs(templates) do
	template.name = buff_name
	template.predicted = template.predicted == nil and true or template.predicted

	if not template.icon then
		template.icon = default_buff_icon
	end
end

return settings("BuffTemplates", templates)