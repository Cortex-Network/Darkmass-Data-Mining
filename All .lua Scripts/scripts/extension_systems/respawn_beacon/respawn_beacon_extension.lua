local NavQueries = require("scripts/utilities/nav_queries")
local MainPathQueries = require("scripts/utilities/main_path_queries")
local PlayerCharacterConstants = require("scripts/settings/player_character/player_character_constants")
local RespawnBeaconGuardSettings = require("scripts/extension_systems/respawn_beacon/respawn_beacon_guard_settings")
local RespawnBeaconQueries = require("scripts/extension_systems/respawn_beacon/utilities/respawn_beacon_queries")
local SpawnPointQueries = require("scripts/managers/main_path/utilities/spawn_point_queries")
local RespawnBeaconExtension = class("RespawnBeaconExtension")
RespawnBeaconExtension.UPDATE_DISABLED_BY_DEFAULT = true
local _player_max_radius_height = nil

function RespawnBeaconExtension:init(extension_init_context, unit, extension_init_data, ...)
	self._physics_world = extension_init_context.physics_world
	self._nav_world = extension_init_context.nav_world
	self._is_server = extension_init_context.is_server
	self._owner_system = extension_init_context.owner_system
	self._unit = unit
	self._player_unit_spawn_manager = Managers.state.player_unit_spawn
	self._side = nil
	self._has_spawned_guards = false
	self._guards = {}
end

function RespawnBeaconExtension:update(unit, dt, t)
end

function RespawnBeaconExtension:setup_from_component(side)
	self._side = side
	local max_player_radius, max_player_height = _player_max_radius_height()
	local valid_spawn_positions, _, _, _ = RespawnBeaconQueries.spawn_locations(self._nav_world, self._physics_world, self._unit, max_player_radius, max_player_height)
end

function RespawnBeaconExtension:respawn_players()
	local player_unit_spawn_manager = self._player_unit_spawn_manager
	local players_to_spawn = player_unit_spawn_manager:players_to_spawn()
	local valid_spawn_positions = self:best_respawn_positions()
	local beacon_unit = self._unit
	local beacon_position = Unit.world_position(beacon_unit, Unit.node(beacon_unit, "aim_target"))
	local side = self._side
	local force_spawn = false
	local is_respawn = true

	for i = 1, #players_to_spawn do
		local player = players_to_spawn[i]
		local spawn_position = valid_spawn_positions[i]

		if spawn_position then
			self:_try_spawn_guards(spawn_position, beacon_unit, valid_spawn_positions)

			local spawn_parent = nil
			local spawn_rotation = Quaternion.look(beacon_position - spawn_position, Vector3.up())

			player_unit_spawn_manager:spawn_player(player, spawn_position, spawn_rotation, spawn_parent, force_spawn, side, nil, "hogtied", is_respawn)
		end
	end
end

function RespawnBeaconExtension:best_respawn_positions()
	local max_player_radius, max_player_height = _player_max_radius_height()
	local valid_spawn_positions, _, _, _ = RespawnBeaconQueries.spawn_locations(self._nav_world, self._physics_world, self._unit, max_player_radius, max_player_height)

	return valid_spawn_positions
end

local NAV_ABOVE = 1
local NAV_BELOW = 1
local TOO_CLOSE_TO_SPAWN_POSITION_DISTANCE = 1

function RespawnBeaconExtension:_try_spawn_guards(spawn_position, beacon_unit, valid_spawn_positions)
	if self._has_spawned_guards then
		return
	end

	local main_path_manager = Managers.state.main_path
	local side_system = Managers.state.extension:system("side_system")
	local side = side_system:get_side_from_name(self._side)
	local side_id = side.side_id
	local furthest_travel_distance = MainPathQueries.is_main_path_registered() and main_path_manager:furthest_travel_distance(side_id)

	if not furthest_travel_distance then
		return
	end

	local settings = Managers.state.difficulty:get_table_entry_by_challenge(RespawnBeaconGuardSettings)
	local nav_spawn_points = main_path_manager:nav_spawn_points()
	local spawn_point_group_index = SpawnPointQueries.group_from_position(self._nav_world, nav_spawn_points, spawn_position)
	local start_index = Managers.state.main_path:node_index_by_nav_group_index(spawn_point_group_index or 1)
	local end_index = start_index + 1
	local _, travel_distance, _, _, _ = MainPathQueries.closest_position_between_nodes(spawn_position, start_index, end_index)
	local travel_distance_threshold = settings.travel_distance_threshold
	local diff = math.max(travel_distance - furthest_travel_distance, 0)

	if diff < travel_distance_threshold then
		return
	end

	local beacon_unit_rotation = Unit.world_rotation(beacon_unit, 1)
	local minion_spawn_manager = Managers.state.minion_spawn
	local breeds = settings.breeds
	local current_faction = Managers.state.pacing:current_faction()
	local faction_breeds = breeds[current_faction]
	local num_guards = settings.num_guards
	local degree_range = settings.direction_degree_range
	local degree_per_direction = degree_range / num_guards
	local position_offset = settings.position_offset_range
	local current_degree = -(degree_range / 2)
	local has_spawned_guards = false

	for i = 1, num_guards do
		current_degree = current_degree + degree_per_direction
		local radians = math.degrees_to_radians(current_degree)
		local direction = -Vector3(math.sin(radians), math.cos(radians), 0)
		local rotation = Quaternion.look(direction)
		local wanted_rotation = Quaternion.multiply(beacon_unit_rotation, rotation)
		local wanted_direction = Quaternion.forward(wanted_rotation)
		local offseted_position = spawn_position + wanted_direction * position_offset
		local navmesh_position = NavQueries.position_on_mesh(self._nav_world, offseted_position, NAV_ABOVE, NAV_BELOW)

		if navmesh_position then
			local too_close_to_spawn_position = false

			for j = 1, #valid_spawn_positions do
				local distance_to_spawn_position = Vector3.distance(navmesh_position, valid_spawn_positions[j])

				if distance_to_spawn_position <= TOO_CLOSE_TO_SPAWN_POSITION_DISTANCE then
					too_close_to_spawn_position = true

					break
				end
			end

			if not too_close_to_spawn_position then
				local breed_name = faction_breeds[math.random(1, #faction_breeds)]
				local guard_unit = minion_spawn_manager:spawn_minion(breed_name, navmesh_position, Quaternion.look(wanted_direction), settings.side_id)
				self._guards[#self._guards + 1] = guard_unit
				has_spawned_guards = true
			end
		end
	end

	self._has_spawned_guards = has_spawned_guards
end

function RespawnBeaconExtension:despawn_guards()
	local minion_spawn_manager = Managers.state.minion_spawn

	for i = 1, #self._guards do
		local guard_unit = self._guards[i]

		minion_spawn_manager:despawn(guard_unit)
	end
end

function _player_max_radius_height()
	local max_radius = PlayerCharacterConstants.respawn_beacon_spot_radius
	local max_height = PlayerCharacterConstants.respawn_beacon_spot_height

	return max_radius, max_height
end

return RespawnBeaconExtension
