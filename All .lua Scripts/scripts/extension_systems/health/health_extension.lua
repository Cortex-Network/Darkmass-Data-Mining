local HealthExtensionInterface = require("scripts/extension_systems/health/health_extension_interface")
local HealthExtension = class("HealthExtension")

function HealthExtension:init(extension_init_context, unit, extension_init_data, game_object_data)
	local health = extension_init_data.health or Unit.get_data(unit, "health")
	self._health = health
	self._unit = unit
	self._is_unkillable = not not extension_init_data.is_unkillable
	self._is_invulnerable = not not extension_init_data.is_invulnerable
	self._damage = 0
	self._is_dead = false
	game_object_data.health = self._health
	game_object_data.damage = self._damage
	game_object_data.is_dead = self._is_dead
	local has_health_bar = extension_init_data.has_health_bar

	if has_health_bar then
		Managers.event:trigger("add_world_marker_unit", "damage_indicator", unit)
	end

	self._damaging_players = {}
end

function HealthExtension:game_object_initialized(session, object_id)
	self._game_session = session
	self._game_object_id = object_id
end

function HealthExtension:is_alive()
	return not self._is_dead
end

function HealthExtension:is_unkillable()
	return self._is_unkillable
end

function HealthExtension:is_invulnerable()
	return self._is_invulnerable
end

function HealthExtension:current_health()
	return math.max(0, self._health - self._damage)
end

function HealthExtension:current_health_percent()
	local health = self._health

	if health <= 0 then
		return 0
	end

	return math.max(0, 1 - self._damage / health)
end

function HealthExtension:damage_taken()
	return self._damage
end

function HealthExtension:permanent_damage_taken()
	return 0
end

function HealthExtension:permanent_damage_taken_percent()
	return 0
end

function HealthExtension:total_damage_taken()
	return math.min(self._health, self._damage)
end

function HealthExtension:max_health()
	return self._health
end

function HealthExtension:add_damage(damage_amount, permanent_damage, hit_actor, damage_profile, attack_type, attack_direction, attacking_unit)
	local current_damage = self._damage
	local health = self._health
	local game_session = self._game_session
	local game_object_id = self._game_object_id
	local new_damage = current_damage + damage_amount
	local network_damage = math.min(new_damage, health)

	GameSession.set_game_object_field(game_session, game_object_id, "damage", network_damage)

	self._damage = new_damage

	if damage_amount > 0 then
		local player_unit_spawn_manager = Managers.state and Managers.state.player_unit_spawn
		local player = player_unit_spawn_manager and player_unit_spawn_manager:owner(attacking_unit)

		if player then
			local damaging_players = self._damaging_players

			if not table.array_contains(damaging_players, player) then
				damaging_players[#damaging_players + 1] = player
			end
		end
	end

	local actual_damage_dealt = math.clamp(damage_amount, 0, health - current_damage)

	return actual_damage_dealt
end

function HealthExtension:add_heal(heal_amount, heal_type)
	local health = self._health
	local game_session = self._game_session
	local game_object_id = self._game_object_id
	local old_damage = self._damage
	local actual_heal_amount = math.min(heal_amount, old_damage)
	local new_damage = old_damage - actual_heal_amount
	local network_damage = math.min(new_damage, health)

	GameSession.set_game_object_field(game_session, game_object_id, "damage", network_damage)

	self._damage = new_damage

	return actual_heal_amount
end

function HealthExtension:set_last_damaging_unit(last_damaging_unit, hit_zone_name, last_hit_was_critical)
	self._last_damaging_unit = last_damaging_unit
	self._last_hit_zone_name = hit_zone_name
	self._last_hit_was_critical = last_hit_was_critical
end

function HealthExtension:last_damaging_unit()
	return self._last_damaging_unit
end

function HealthExtension:last_hit_zone_name()
	return self._last_hit_zone_name
end

function HealthExtension:last_hit_was_critical()
	return self._last_hit_was_critical
end

function HealthExtension:health_depleted()
	if self._is_unkillable then
		return false
	else
		return self._health <= self._damage
	end
end

function HealthExtension:set_unkillable(should_be_unkillable)
	self._is_unkillable = should_be_unkillable
end

function HealthExtension:set_invulnerable(should_be_invulnerable)
	self._is_invulnerable = should_be_invulnerable
end

local IS_DEAD_FIELD_NAME = "is_dead"

function HealthExtension:kill()
	if self._is_unkillable then
		Log.warning("HealthExtension", "Trying to kill health extension which is unkillable")

		return
	end

	Managers.event:trigger("unit_died", self._unit)

	HEALTH_ALIVE[self._unit] = nil
	self._is_dead = true

	GameSession.set_game_object_field(self._game_session, self._game_object_id, IS_DEAD_FIELD_NAME, true)
end

function HealthExtension:num_wounds()
	return 1
end

function HealthExtension:max_wounds()
	return 1
end

function HealthExtension:damaging_players()
	return self._damaging_players
end

implements(HealthExtension, HealthExtensionInterface)

return HealthExtension
