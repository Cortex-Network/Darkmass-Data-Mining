local BuffSettings = require("scripts/settings/buff/buff_settings")
local Health = require("scripts/utilities/health")
local Toughness = require("scripts/utilities/toughness/toughness")
local ProximityHeal = class("ProximityHeal")
local _heal_amount_percentage_from_range = nil

function ProximityHeal:init(logic_context, init_data)
	self._unit = logic_context.unit
	self._side_name = logic_context.side_name
	self._units_in_proximity = {}
	self._med_kit_settings = init_data
	self._amount_of_damage_healed = 0
	self._fx_time_table = {}
	local t = Managers.time:time("gameplay")
	self._start_time = t
	self._current_t = t
	local players_have_improved_keyword = false
	local side_system = Managers.state.extension:system("side_system")
	local side = side_system:get_side_from_name(self._side_name)
	local player_units = side.player_units
	local buff_keywords = BuffSettings.keywords

	for _, player_unit in pairs(player_units) do
		local buff_extension = ScriptUnit.has_extension(player_unit, "buff_system")

		if buff_extension then
			local improved_keyword = buff_extension:has_keyword(buff_keywords.improved_medical_crate)

			if improved_keyword then
				players_have_improved_keyword = true

				break
			end
		end
	end

	self._heal_amount_modifier = players_have_improved_keyword and 2 or 1
	self._heal_reserve = self._med_kit_settings.optional_heal_reserve
	self._heal_time = self._med_kit_settings.optional_heal_time
	self._players_have_improved_keyword = players_have_improved_keyword
end

function ProximityHeal:unit_entered_proximity(unit)
	local health_extension = ScriptUnit.has_extension(unit, "health_system")

	if not health_extension then
		return
	end

	self._units_in_proximity[unit] = health_extension
end

function ProximityHeal:unit_left_proximity(unit)
	self._units_in_proximity[unit] = nil
end

function ProximityHeal:unit_in_proximity_deleted(unit)
	self._units_in_proximity[unit] = nil
	self._fx_time_table[unit] = nil
end

function ProximityHeal:update(dt, t)
	self._current_t = t
	local healing_reserve = self._heal_reserve

	if healing_reserve and healing_reserve < self._amount_of_damage_healed then
		return
	end

	local heal_type = self._heal_type
	local heal_rate_percentage = self._med_kit_settings.heal_rate_percentage
	local heal_amount_modifier = self._heal_amount_modifier
	local heal_percentage = dt * heal_rate_percentage
	local amount_healed_this_tick = 0
	local players_have_improved_keyword = self._players_have_improved_keyword
	local optional_buff = self._med_kit_settings.optional_buff

	for unit, _ in pairs(self._units_in_proximity) do
		local health_extension = ScriptUnit.has_extension(unit, "health_system")

		if health_extension then
			local max_health = health_extension:max_health()
			local heal_amount = max_health * heal_percentage * heal_amount_modifier
			local health_added = Health.add(unit, heal_amount, heal_type)
			amount_healed_this_tick = amount_healed_this_tick + health_added

			if optional_buff then
				local buff_extension = ScriptUnit.has_extension(unit, "buff_system")
				local stat_buffs = buff_extension:stat_buffs()
				local heal_modifier = stat_buffs[optional_buff]
				local extra_heal_percentage = heal_percentage * heal_modifier - heal_percentage

				if extra_heal_percentage > 0 then
					local extra_heal_amount = max_health * extra_heal_percentage
					local extra_health_added = Health.add(unit, extra_heal_amount, heal_type)
				end
			end

			if players_have_improved_keyword then
				health_extension:reduce_permanent_damage(heal_amount * 0.5)
				Toughness.replenish_percentage(unit, 0.0016, false, "proximity_heal")
			end

			if health_added > 0 then
				self:play_fx_for_unit(unit, t)
			end
		end
	end

	self._amount_of_damage_healed = self._amount_of_damage_healed + amount_healed_this_tick
end

function ProximityHeal:play_fx_for_unit(unit, t)
	local last_play_time = self._fx_time_table[unit]
	local fx_intervall = self._med_kit_settings.fx_intervall

	if not last_play_time or t > last_play_time + fx_intervall then
		self._fx_time_table[unit] = t

		Health.play_fx(unit)
	end
end

function ProximityHeal:job_completed()
	local is_health_depleted = false
	local healing_reserve = self._heal_reserve

	if healing_reserve then
		local amount_of_damage_healed = self._amount_of_damage_healed
		is_health_depleted = healing_reserve <= amount_of_damage_healed
	end

	local is_life_span_over = false
	local life_time = self._heal_time

	if life_time then
		local life_span = self._current_t - self._start_time
		is_life_span_over = self._heal_time <= life_span
	end

	return is_health_depleted or is_life_span_over
end

function ProximityHeal:cancel_job()
	self._is_canceled = true
end

function ProximityHeal:is_job_canceled()
	return self._is_canceled or false
end

return ProximityHeal
