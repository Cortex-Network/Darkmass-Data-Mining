local HealthExtensionInterface = require("scripts/extension_systems/health/health_extension_interface")
local HuskHealthExtension = class("HuskHealthExtension")

local function _health_and_damage(game_session, game_object_id)
	local health = GameSession.game_object_field(game_session, game_object_id, "health")
	local damage = GameSession.game_object_field(game_session, game_object_id, "damage")

	return health, damage
end

function HuskHealthExtension:init(extension_init_context, unit, extension_init_data, game_session, game_object_id, owner_id)
	self.game_session = game_session
	self.game_object_id = game_object_id
	self.is_dead = false
	local has_health_bar = extension_init_data and extension_init_data.has_health_bar

	if has_health_bar then
		Managers.event:trigger("add_world_marker_unit", "damage_indicator", unit)
	end
end

function HuskHealthExtension:is_alive()
	return not self.is_dead
end

function HuskHealthExtension:is_unkillable()
	return false
end

function HuskHealthExtension:is_invulnerable()
	return false
end

function HuskHealthExtension:current_health()
	local health, damage = _health_and_damage(self.game_session, self.game_object_id)

	return math.max(0, health - damage)
end

function HuskHealthExtension:current_health_percent()
	local health, damage = _health_and_damage(self.game_session, self.game_object_id)

	if health <= 0 then
		return 0
	end

	return math.max(0, 1 - damage / health)
end

function HuskHealthExtension:damage_taken()
	return GameSession.game_object_field(self.game_session, self.game_object_id, "damage")
end

function HuskHealthExtension:permanent_damage_taken()
	return GameSession.game_object_field(self.game_session, self.game_object_id, "damage")
end

function HuskHealthExtension:permanent_damage_taken_percent()
	local health, damage = _health_and_damage(self.game_session, self.game_object_id)

	if health <= 0 then
		return 0
	end

	return damage / health
end

function HuskHealthExtension:total_damage_taken()
	local health, damage = _health_and_damage(self.game_session, self.game_object_id)

	return math.min(health, damage)
end

function HuskHealthExtension:max_health()
	return GameSession.game_object_field(self.game_session, self.game_object_id, "health")
end

function HuskHealthExtension:add_damage()
end

function HuskHealthExtension:add_heal()
end

function HuskHealthExtension:health_depleted()
end

function HuskHealthExtension:set_unkillable()
end

function HuskHealthExtension:set_invulnerable()
end

function HuskHealthExtension:num_wounds()
	return 1
end

function HuskHealthExtension:max_wounds()
	return 1
end

implements(HuskHealthExtension, HealthExtensionInterface)

return HuskHealthExtension
