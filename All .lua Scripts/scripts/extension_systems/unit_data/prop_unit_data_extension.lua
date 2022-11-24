local PropData = require("scripts/settings/prop_data/prop_data")
local HitZone = require("scripts/utilities/attack/hit_zone")
local PropUnitDataExtension = class("PropUnitDataExtension")

function PropUnitDataExtension:init(extension_init_context, unit)
	self._unit = unit
	self._breed = nil
end

function PropUnitDataExtension:setup_from_component(armor_data_name)
	local breed = PropData[armor_data_name]
	local unit = self._unit
	self._breed = breed
	local hit_zones = breed.hit_zones
	self._hit_zone_lookup, self._hit_zone_actors_lookup = HitZone.initialize_lookup(unit, hit_zones)
	local bind_pose = Unit.local_pose(unit, 1)
	self._bind_pose = Matrix4x4Box(bind_pose)
	self._node_to_bind_pose = {}
	local inv_bind_pose = Matrix4x4.inverse(bind_pose)

	for i = 1, #hit_zones do
		local hit_zone = hit_zones[i]
		local actors = hit_zone.actors

		for j = 1, #actors do
			local actor_name = actors[j]
			local actor_id = Unit.find_actor(unit, actor_name)
			local actor = Unit.actor(unit, actor_id)
			local node_index = Actor.node(actor)

			if not self._node_to_bind_pose[node_index] then
				local bind_pose_for_node = Actor.pose(actor)
				bind_pose_for_node = Matrix4x4.multiply(bind_pose_for_node, inv_bind_pose)
				self._node_to_bind_pose[node_index] = Matrix4x4Box(bind_pose_for_node)
			end
		end
	end
end

function PropUnitDataExtension:breed()
	return self._breed
end

function PropUnitDataExtension:faction_name()
	return self._breed.faction_name
end

function PropUnitDataExtension:breed_name()
	local breed = self._breed
	local breed_name = breed.name

	return breed_name
end

function PropUnitDataExtension:archetype()
	ferror("[PropUnitDataExtension:archetype()] Props don't have archetypes.")
end

function PropUnitDataExtension:archetype_name()
	ferror("[PropUnitDataExtension:archetype_name()] Props don't have archetypes.")
end

function PropUnitDataExtension:specialization()
	ferror("[PropUnitDataExtension:specialization()] Props don't have specializations.")
end

function PropUnitDataExtension:bind_pose()
	return self._bind_pose:unbox()
end

function PropUnitDataExtension:node_bind_pose(node_index)
	local bind_pose = self._node_to_bind_pose[node_index]

	if bind_pose then
		return bind_pose:unbox()
	end

	return nil
end

function PropUnitDataExtension:breed_size_variation()
	ferror("PropUnitDataExtension does not support breed_size_variation.")
end

function PropUnitDataExtension:hit_zone(actor)
	return self._hit_zone_lookup[actor]
end

function PropUnitDataExtension:hit_zone_actors(hit_zone_name)
	return self._hit_zone_actors_lookup[hit_zone_name]
end

function PropUnitDataExtension:is_owned_by_death_manager()
	return false
end

return PropUnitDataExtension
