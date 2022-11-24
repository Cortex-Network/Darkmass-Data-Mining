local MinionDifficultySettings = require("scripts/settings/difficulty/minion_difficulty_settings")
local PlayerDifficultySettings = require("scripts/settings/difficulty/player_difficulty_settings")
local DifficultyManager = class("DifficultyManager")

function DifficultyManager:init(is_server, resistance, challenge)
	self._is_server = is_server
	self._resistance = resistance
	self._challenge = challenge

	Log.info("DifficultyManager", "Difficulty initialized to challenge %s, resistance %s", challenge, resistance)
end

function DifficultyManager:get_minion_max_health(breed_name)
	local max_health_settings = MinionDifficultySettings.health[breed_name]
	local current_challenge = self._challenge
	local max_health = max_health_settings[math.min(#max_health_settings, current_challenge)]

	return max_health
end

function DifficultyManager:get_minion_attack_power_level(breed, attack_type)
	local breed_power_level_type = breed.power_level_type
	local power_level_type = type(breed_power_level_type) == "table" and breed_power_level_type[attack_type] or breed_power_level_type
	local power_level_settings = MinionDifficultySettings.power_level[power_level_type]
	local current_challenge = self._challenge
	local power_level = power_level_settings[math.min(#power_level_settings, current_challenge)]

	return power_level
end

function DifficultyManager:get_table_entry_by_resistance(t)
	local resistance = self._resistance

	return t[math.min(#t, resistance)]
end

function DifficultyManager:get_table_entry_by_challenge(t)
	local challenge = self._challenge

	return t[math.min(#t, challenge)]
end

function DifficultyManager:get_challenge()
	return self._challenge
end

function DifficultyManager:get_resistance()
	return self._resistance
end

function DifficultyManager:get_difficulty()
	return self:get_challenge()
end

function DifficultyManager:set_challenge(new_challenge)
	self._challenge = new_challenge

	Log.info("DifficultyManager", "Challenge set to %s", self._challenge)
end

function DifficultyManager:set_resistance(new_resistance)
	self._resistance = new_resistance

	Log.info("DifficultyManager", "Resistance set to %s", self._resistance)
end

function DifficultyManager:modify_resistance(modifier)
	self._resistance = math.max(1, self._resistance + modifier)

	Log.info("DifficultyManager", "Resistance modified to %s", self._resistance)
end

function DifficultyManager:friendly_fire_enabled(target_is_player, target_is_minion)
	if target_is_player then
		return false
	elseif target_is_minion then
		return true
	end

	return true
end

function DifficultyManager:player_wounds(specialization)
	local wounds_settings = PlayerDifficultySettings.specialization_wounds[specialization]
	local challenge = self._challenge
	local max_wounds = wounds_settings[math.min(#wounds_settings, challenge)]

	return max_wounds
end

return DifficultyManager
