require("scripts/extension_systems/weapon/actions/action_weapon_base")

local Attack = require("scripts/utilities/attack/attack")
local SpecialRulesSetting = require("scripts/settings/ability/special_rules_settings")
local TalentSettings = require("scripts/settings/buff/talent_settings")
local Toughness = require("scripts/utilities/toughness/toughness")
local Vo = require("scripts/utilities/vo")
local WarpCharge = require("scripts/utilities/warp_charge")
local special_rules = SpecialRulesSetting.special_rules
local talent_settings = TalentSettings.shared.venting
local ActionVentWarpCharge = class("ActionVentWarpCharge", "ActionWeaponBase")
local DEFAULT_WEAPON_VENT_POWER_LEVEL_MODIFIER = {
	1,
	1
}

function ActionVentWarpCharge:init(action_context, action_params, action_settings)
	ActionVentWarpCharge.super.init(self, action_context, action_params, action_settings)

	self._warp_charge_component = self._unit_data_extension:write_component("warp_charge")
	self._specialization_warp_charge_template = WarpCharge.specialization_warp_charge_template(self._player)
	self._buff_extension = ScriptUnit.has_extension(self._player_unit, "buff_system")
	self._specialization_extension = ScriptUnit.has_extension(self._player_unit, "specialization_system")
end

local vo_threshold = 0.8

function ActionVentWarpCharge:start(action_settings, t, time_scale, action_start_params)
	ActionVentWarpCharge.super.start(self, action_settings, t, time_scale, action_start_params)
	WarpCharge.start_venting(t, self._player, self._warp_charge_component)

	local current_warp_charge = self._warp_charge_component.current_percentage

	if vo_threshold <= current_warp_charge then
		local vo_tag = action_settings.vo_tag

		if vo_tag then
			Vo.play_combat_ability_event(self._player_unit, vo_tag)
		end
	end

	self._venting_restores_toughness = self._specialization_extension:has_special_rule(special_rules.venting_restores_toughness)
end

function ActionVentWarpCharge:fixed_update(dt, t, time_in_action)
	local warp_charge = self._warp_charge_component.current_percentage or 0

	WarpCharge.update_venting(dt, t, self._player, self._warp_charge_component)

	if self._is_server then
		local new_warp_charge = self._warp_charge_component.current_percentage or 0

		if self._venting_restores_toughness then
			local vent_percent = (warp_charge - new_warp_charge) * talent_settings.vent_to_toughness

			if vent_percent > 0 then
				Toughness.replenish_percentage(self._player_unit, vent_percent, false, "vent")
			end
		end
	end
end

function ActionVentWarpCharge:finish(reason, data, t, time_in_action)
	WarpCharge.stop_venting(self._warp_charge_component)
end

function ActionVentWarpCharge:running_action_state(t, time_in_action)
	local current_warp_charge = self._warp_charge_component.current_percentage

	if current_warp_charge <= 0 then
		return "fully_vented"
	end

	return nil
end

return ActionVentWarpCharge
