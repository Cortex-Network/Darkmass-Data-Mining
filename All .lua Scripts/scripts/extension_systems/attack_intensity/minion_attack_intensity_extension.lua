local AttackIntensitySettings = require("scripts/settings/attack_intensity/attack_intensity_settings")
local Breed = require("scripts/utilities/breed")
local MinionAttackIntensityExtension = class("MinionAttackIntensityExtension")
local attack_intensities = AttackIntensitySettings.attack_intensities

function MinionAttackIntensityExtension:init(extension_init_context, unit, extension_init_data)
	local breed = extension_init_data.breed
	local cooldowns = breed.attack_intensity_cooldowns
	self._cooldowns = cooldowns
	self._breed = breed
	local difficulty_settings = {}
	local allowed_attacks = {}
	local uses_suppression = false

	for intensity_type, _ in pairs(cooldowns) do
		local settings = Managers.state.difficulty:get_table_entry_by_challenge(attack_intensities[intensity_type])
		allowed_attacks[intensity_type] = true

		if settings.disallow_when_suppressed then
			uses_suppression = true
		end

		difficulty_settings[intensity_type] = settings
	end

	self._difficulty_settings = difficulty_settings
	local blackboard = BLACKBOARDS[unit]
	self._perception_component = blackboard.perception

	if uses_suppression then
		self._suppression_component = blackboard.suppression
	end

	self._allowed_attacks = allowed_attacks
	self._current_cooldowns = {}
end

function MinionAttackIntensityExtension:update(unit, dt, t)
	local perception_component = self._perception_component
	local target_unit = perception_component.target_unit

	if not HEALTH_ALIVE[target_unit] then
		return
	end

	local target_unit_data_extension = ScriptUnit.extension(target_unit, "unit_data_system")
	local breed = target_unit_data_extension:breed()
	local target_movement_state = nil

	if Breed.is_player(breed) then
		local movement_state_component = target_unit_data_extension:read_component("movement_state")
		target_movement_state = movement_state_component.method
	end

	local target_attack_intensity_extension = ScriptUnit.extension(target_unit, "attack_intensity_system")
	local suppression_component = self._suppression_component
	local cooldowns = self._cooldowns
	local current_cooldowns = self._current_cooldowns
	local allowed_attacks = self._allowed_attacks

	for intensity_type, cooldown in pairs(cooldowns) do
		repeat
			local difficulty_settings = self._difficulty_settings[intensity_type]
			local ignored_movement_states = difficulty_settings.ignored_movement_states
			local ignore_attack_intensity = ignored_movement_states and ignored_movement_states[target_movement_state]

			if ignore_attack_intensity then
				allowed_attacks[intensity_type] = true
			elseif suppression_component then
				local disallow_when_suppressed = difficulty_settings.disallow_when_suppressed
				local is_suppressed = suppression_component.is_suppressed

				if disallow_when_suppressed and is_suppressed then
					allowed_attacks[intensity_type] = false
				end
			else
				local attack_allowed, ignore_cooldown = target_attack_intensity_extension:attack_allowed(intensity_type)

				if attack_allowed then
					if current_cooldowns[intensity_type] and t < current_cooldowns[intensity_type] then
						allowed_attacks[intensity_type] = false
					else
						allowed_attacks[intensity_type] = true
						current_cooldowns[intensity_type] = nil
					end
				elseif not current_cooldowns[intensity_type] then
					current_cooldowns[intensity_type] = t + (ignore_cooldown and 0 or math.random_range(cooldown[1], cooldown[2]))
					allowed_attacks[intensity_type] = false
				elseif current_cooldowns[intensity_type] <= t then
					current_cooldowns[intensity_type] = nil
				end
			end
		until true
	end
end

function MinionAttackIntensityExtension:set_monster_attacker(attacker_unit)
end

function MinionAttackIntensityExtension:monster_attacker()
end

function MinionAttackIntensityExtension:add_intensity(intensity_type, intensity)
end

function MinionAttackIntensityExtension:get_intensity(intensity_type)
	return 0
end

function MinionAttackIntensityExtension:attack_allowed(intensity_type)
	return true
end

function MinionAttackIntensityExtension:locked_in_melee()
	return false
end

function MinionAttackIntensityExtension:add_to_locked_in_melee_timer()
end

function MinionAttackIntensityExtension:set_attacked()
end

function MinionAttackIntensityExtension:can_attack(attack_type)
	return self._allowed_attacks[attack_type]
end

return MinionAttackIntensityExtension
