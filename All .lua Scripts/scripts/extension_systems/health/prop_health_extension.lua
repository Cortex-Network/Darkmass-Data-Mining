local Component = require("scripts/utilities/component")
local HealthExtensionInterface = require("scripts/extension_systems/health/health_extension_interface")
local PropHealthExtension = class("PropHealthExtension")

function PropHealthExtension:init(extension_init_context, unit)
	self._unit = unit
	self._health = math.huge
	self._max_health = math.huge
	self._is_dead = false
	self._unkillable = false
	self._invulnerable = false
	self._speed_on_hit = 5
	self._breed_white_list = nil
	self._ignored_colliders = {}
end

function PropHealthExtension:setup_from_component(max_health, invulnerable, unkillable, breed_white_list, ignored_collider_actor_names, speed_on_hit)
	self._max_health = max_health
	self._health = max_health
	self._invulnerable = invulnerable
	self._unkillable = unkillable
	self._speed_on_hit = speed_on_hit
	self._breed_white_list = breed_white_list

	if ignored_collider_actor_names then
		local unit = self._unit

		for ii = 1, #ignored_collider_actor_names do
			local actor = Unit.actor(unit, ignored_collider_actor_names[ii])
			self._ignored_colliders[actor] = true
		end
	end
end

function PropHealthExtension:set_dead()
	self._health = 0

	if not self._unkillable then
		self._is_dead = true
		HEALTH_ALIVE[self._unit] = nil
	end

	Component.event(self._unit, "died")
end

local function _add_force_on_parts(actor, mass, speed, attack_direction)
	local direction = attack_direction

	if not direction then
		local random_x = math.random() * 2 - 1
		local random_y = math.random() * 2 - 1
		local random_z = math.random() * 2 - 1
		local random_direction = Vector3(random_x, random_y, random_z)
		random_direction = Vector3.normalize(random_direction)
		direction = random_direction
	end

	Actor.add_impulse(actor, direction * mass * speed)
end

function PropHealthExtension:add_damage(damage_amount, permanent_damage, hit_actor, damage_profile, attack_type, attack_direction, attacking_unit)
	if self._ignored_colliders[hit_actor] then
		return
	end

	if self:_can_receive_damage(attacking_unit) then
		local max_health = self._max_health
		local health = self._health - damage_amount
		health = math.clamp(health, 0, max_health)
		self._health = health

		Component.event(self._unit, "add_damage", damage_amount, hit_actor, attack_direction)

		if hit_actor and Actor.is_dynamic(hit_actor) then
			_add_force_on_parts(hit_actor, Actor.mass(hit_actor), self._speed_on_hit, attack_direction)
		end

		if self._health <= 0 then
			self:set_dead()
		end
	end
end

function PropHealthExtension:add_heal(heal_amount, heal_type)
end

function PropHealthExtension:set_last_damaging_unit(last_damaging_unit)
	self._last_damaging_unit = last_damaging_unit
end

function PropHealthExtension:last_damaging_unit()
	return self._last_damaging_unit
end

function PropHealthExtension:max_health()
	return self._max_health
end

function PropHealthExtension:current_health()
	return self._health
end

function PropHealthExtension:current_health_percent()
	if self._max_health <= 0 then
		return 0
	end

	return 1 - self._health / self._max_health
end

function PropHealthExtension:damage_taken()
	return 0
end

function PropHealthExtension:permanent_damage_taken()
	return 0
end

function PropHealthExtension:permanent_damage_taken_percent()
	return 0
end

function PropHealthExtension:total_damage_taken()
	return 0
end

function PropHealthExtension:health_depleted()
	return self._health <= 0
end

function PropHealthExtension:is_alive()
	return not self._is_dead
end

function PropHealthExtension:is_unkillable()
	return self._is_unkillable
end

function PropHealthExtension:is_invulnerable()
	return self._is_invulnerable
end

function PropHealthExtension:set_unkillable(should_be_unkillable)
	self._unkillable = should_be_unkillable
end

function PropHealthExtension:set_invulnerable(should_be_invulnerable)
	self._invulnerable = should_be_invulnerable
end

function PropHealthExtension:num_wounds()
	return 1
end

function PropHealthExtension:max_wounds()
	return 1
end

function PropHealthExtension:_can_receive_damage(attacking_unit)
	if attacking_unit == self._unit then
		return true
	end

	if self._is_dead or self._invulnerable then
		return false
	end

	if not self._breed_white_list then
		return true
	end

	local unit_data_extension = ScriptUnit.has_extension(attacking_unit, "unit_data_system")

	if unit_data_extension then
		local breed_name = unit_data_extension:breed_name()
		local key = table.find(self._breed_white_list, breed_name)
		local can_damage = key ~= nil

		if can_damage then
			return true
		end
	end

	return false
end

implements(PropHealthExtension, HealthExtensionInterface)

return PropHealthExtension
