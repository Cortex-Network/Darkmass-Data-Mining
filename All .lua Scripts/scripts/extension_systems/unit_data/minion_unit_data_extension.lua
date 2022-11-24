local HitZone = require("scripts/utilities/attack/hit_zone")
local MinionUnitDataExtension = class("MinionUnitDataExtension")
local CLIENT_RPCS = {
	"rpc_destroy_hit_zone"
}
local NODE_TO_BIND_POSE_BY_BREED_NAME = {}

function MinionUnitDataExtension:init(extension_init_context, unit, extension_init_data, game_object_data_or_game_session, nil_or_game_object_id)
	local is_server = extension_init_context.is_server
	self._is_server = is_server
	local breed = extension_init_data.breed
	self._breed = breed
	self._owned_by_death_manager = false
	local hit_zones = breed.hit_zones
	local breed_name = breed.name
	self._hit_zone_lookup, self._hit_zone_actors_lookup = HitZone.initialize_lookup(unit, hit_zones)
	self._pending_destroyed_hit_zones = {}
	self._destroyed_hit_zones = {}
	local bind_pose = Unit.world_pose(unit, 1)
	self._bind_pose = Matrix4x4Box(bind_pose)
	local breed_size_variation = Matrix4x4.scale(bind_pose)
	self._breed_size_variation = breed_size_variation.x
	local node_to_bind_pose = NODE_TO_BIND_POSE_BY_BREED_NAME[breed_name]

	if node_to_bind_pose == nil then
		node_to_bind_pose = {}
		local inv_bind_pose = Matrix4x4.inverse(bind_pose)

		for i = 1, #hit_zones do
			local hit_zone = hit_zones[i]
			local actors = hit_zone.actors

			for j = 1, #actors do
				local actor_name = actors[j]
				local actor_id = Unit.find_actor(unit, actor_name)
				local actor = Unit.actor(unit, actor_id)
				local node_index = Actor.node(actor)

				if not node_to_bind_pose[node_index] then
					local bind_pose_for_node = Unit.world_pose(unit, node_index)
					bind_pose_for_node = Matrix4x4.multiply(bind_pose_for_node, inv_bind_pose)
					node_to_bind_pose[node_index] = Matrix4x4Box(bind_pose_for_node)
				end
			end
		end

		NODE_TO_BIND_POSE_BY_BREED_NAME[breed_name] = node_to_bind_pose
	end

	self._node_to_bind_pose = node_to_bind_pose

	if not is_server then
		local network_event_delegate = extension_init_context.network_event_delegate
		self._network_event_delegate = network_event_delegate
		self._game_object_id = nil_or_game_object_id

		network_event_delegate:register_session_unit_events(self, nil_or_game_object_id, unpack(CLIENT_RPCS))

		self._unit_rpcs_registered = true
	end
end

function MinionUnitDataExtension:game_object_initialized(game_session, game_object_id)
	self._game_object_id = game_object_id
end

function MinionUnitDataExtension:set_unit_local()
	if not self._is_server then
		self._network_event_delegate:unregister_unit_events(self._game_object_id, unpack(CLIENT_RPCS))

		self._unit_rpcs_registered = false
		self._game_object_id = nil
	end

	self._unit_is_local = true
end

function MinionUnitDataExtension:hot_join_sync(unit, sender, channel_id)
	local game_object_id = self._game_object_id

	for hit_zone_name, _ in pairs(self._destroyed_hit_zones) do
		local hit_zone_id = NetworkLookup.hit_zones[hit_zone_name]

		RPC.rpc_destroy_hit_zone(channel_id, game_object_id, hit_zone_id)
	end
end

function MinionUnitDataExtension:destroy()
	if not self._is_server and self._unit_rpcs_registered then
		self._network_event_delegate:unregister_unit_events(self._game_object_id, unpack(CLIENT_RPCS))

		self._unit_rpcs_registered = false
	end
end

function MinionUnitDataExtension:breed()
	return self._breed
end

function MinionUnitDataExtension:faction_name()
	return self._breed.faction_name
end

function MinionUnitDataExtension:breed_name()
	local breed = self._breed
	local breed_name = breed.name

	return breed_name
end

function MinionUnitDataExtension:archetype()
	ferror("MinionUnitDataExtension does not support archetype.")
end

function MinionUnitDataExtension:archetype_name()
	ferror("MinionUnitDataExtension does not support archetype.")
end

function MinionUnitDataExtension:bind_pose()
	return self._bind_pose:unbox()
end

function MinionUnitDataExtension:node_bind_pose(node_index)
	local bind_pose = self._node_to_bind_pose[node_index]

	if bind_pose then
		return bind_pose:unbox()
	end

	return nil
end

function MinionUnitDataExtension:destroy_hit_zone(hit_zone_name)
	local destroyed_hit_zones = self._destroyed_hit_zones
	destroyed_hit_zones[hit_zone_name] = true
	local pending_destroyed_hit_zones = self._pending_destroyed_hit_zones
	pending_destroyed_hit_zones[#pending_destroyed_hit_zones + 1] = hit_zone_name
	local hit_zone_id = NetworkLookup.hit_zones[hit_zone_name]

	Managers.state.game_session:send_rpc_clients("rpc_destroy_hit_zone", self._game_object_id, hit_zone_id)
end

function MinionUnitDataExtension:breed_size_variation()
	return self._breed_size_variation
end

function MinionUnitDataExtension:hit_zone(actor)
	return self._hit_zone_lookup[actor]
end

function MinionUnitDataExtension:hit_zone_actors(hit_zone_name)
	return self._hit_zone_actors_lookup[hit_zone_name]
end

function MinionUnitDataExtension:set_owned_by_death_manager(owned)
	self._owned_by_death_manager = owned
end

function MinionUnitDataExtension:is_owned_by_death_manager()
	return self._owned_by_death_manager
end

function MinionUnitDataExtension:post_update(unit, dt, t, ...)
	local hit_zone_lookup = self._hit_zone_lookup
	local hit_zone_actors_lookup = self._hit_zone_actors_lookup
	local pending_destroyed_hit_zones = self._pending_destroyed_hit_zones

	for i = 1, #pending_destroyed_hit_zones do
		local hit_zone_name = pending_destroyed_hit_zones[i]

		HitZone.destroy_hit_zone(unit, hit_zone_lookup, hit_zone_actors_lookup, hit_zone_name)

		pending_destroyed_hit_zones[i] = nil
	end
end

function MinionUnitDataExtension:rpc_destroy_hit_zone(channel_id, game_object_id, hit_zone_id)
	local hit_zone_name = NetworkLookup.hit_zones[hit_zone_id]
	local pending_destroyed_hit_zones = self._pending_destroyed_hit_zones
	pending_destroyed_hit_zones[#pending_destroyed_hit_zones + 1] = hit_zone_name
	self._destroyed_hit_zones[hit_zone_name] = true
end

return MinionUnitDataExtension
