local PropShieldExtension = class("PropShieldExtension")

function PropShieldExtension:init(extension_init_context, unit, extension_init_data, game_object_data)
	self._unit = unit
	self._shield_actors = {}
end

function PropShieldExtension:setup_from_component(actor_names)
	local unit = self._unit
	local shield_actors = self._shield_actors

	for i = 1, #actor_names do
		shield_actors[Unit.actor(unit, actor_names[i])] = true
	end
end

function PropShieldExtension:update(context, dt, t)
end

function PropShieldExtension:set_blocking(is_blocking)
	ferror("PropShieldExtension does not support set_blocking.")
end

function PropShieldExtension:is_blocking()
	ferror("PropShieldExtension does not support is_blocking.")
end

function PropShieldExtension:can_block_from_position(attacking_unit_position)
	return false
end

function PropShieldExtension:can_block_attack(damage_profile, attacking_unit, attacking_unit_owner_unit, hit_actor)
	if self._shield_actors[hit_actor] then
		return true
	end

	return false
end

function PropShieldExtension:apply_stagger(unit, damage_profile, stagger_strength, attack_result, stagger_type, duration_scale, length_scale)
	ferror("PropShieldExtension does not support stagger.")
end

return PropShieldExtension
