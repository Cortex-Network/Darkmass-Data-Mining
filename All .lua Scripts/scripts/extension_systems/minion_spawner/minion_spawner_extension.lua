local Breeds = require("scripts/settings/breed/breeds")
local Component = require("scripts/utilities/component")
local MinionSpawnerQueue = require("scripts/extension_systems/minion_spawner/utilities/minion_spawner_queue")
local MinionSpawnerSpawnPosition = require("scripts/extension_systems/minion_spawner/utilities/minion_spawner_spawn_position")
local PerceptionSettings = require("scripts/settings/perception/perception_settings")
local aggro_states = PerceptionSettings.aggro_states
local MinionSpawnerExtension = class("MinionSpawnerExtension")
MinionSpawnerExtension.UPDATE_DISABLED_BY_DEFAULT = true
local DEFAULT_SPAWN_DELAY = 0.25

function MinionSpawnerExtension:init(extension_init_context, unit, extension_init_data, ...)
	self._unit = unit
	self._is_server = extension_init_context.is_server
	self._nav_world = extension_init_context.nav_world
	self._nav_tag_cost_table = extension_init_context.nav_tag_cost_table
	self._traverse_logic = extension_init_context.traverse_logic
	self._owner_system = extension_init_context.owner_system
	self._spawn_queue = MinionSpawnerQueue:new()
	self._next_spawn_time = nil
	self._is_setup = false
	self._spawned_minions_by_queue_id = {}
end

function MinionSpawnerExtension:setup_from_component(spawner_groups, spawn_position, exit_position, exclude_from_pacing)
	local exit_position_on_nav_mesh = MinionSpawnerSpawnPosition.find_exit_position_on_nav_mesh(self._nav_world, spawn_position, exit_position, self._traverse_logic)

	if not exit_position_on_nav_mesh then
		Log.warning("[MinionSpawnerExtension]", "Couldn't find any nav mesh at spawner exit position %s, on unit: %s", exit_position, Unit.id_string(self._unit))

		exit_position_on_nav_mesh = exit_position
	end

	self._spawner_groups = spawner_groups
	self._spawn_position = Vector3Box(spawn_position)
	self._spawn_rotation = QuaternionBox(Quaternion.look(Vector3.flat(exit_position_on_nav_mesh - spawn_position), Vector3.up()))
	self._exit_position = Vector3Box(exit_position_on_nav_mesh)
	self._is_setup = true
	self._excluded_from_pacing = exclude_from_pacing
end

function MinionSpawnerExtension:spawner_groups()
	return self._spawner_groups
end

function MinionSpawnerExtension:exit_position_boxed()
	return self._exit_position
end

function MinionSpawnerExtension:is_excluded_from_pacing()
	return self._excluded_from_pacing
end

function MinionSpawnerExtension:unit()
	return self._unit
end

function MinionSpawnerExtension:position()
	local unit = self._unit
	local position = POSITION_LOOKUP[unit]

	return position
end

function MinionSpawnerExtension:add_spawns(breed_list, spawn_side_id, optional_target_side_id, optional_spawn_delay, optional_mission_objective_id, optional_group_id, optional_attack_selection_template_name, optional_aggro_state, optional_max_health_modifier)
	local queue = self._spawn_queue
	local spawn_delay = optional_spawn_delay or DEFAULT_SPAWN_DELAY
	local spawn_data = {
		spawn_delay = spawn_delay,
		spawn_side_id = spawn_side_id,
		target_side_id = optional_target_side_id,
		mission_objective_id = optional_mission_objective_id,
		group_id = optional_group_id,
		attack_selection_template_name = optional_attack_selection_template_name,
		aggro_state = optional_aggro_state,
		max_health_modifier = optional_max_health_modifier
	}
	local queue_id = queue:enqueue(breed_list, spawn_data)

	if not self._next_spawn_time then
		self._next_spawn_time = 0

		Component.event(self._unit, "minion_spawner_spawning_started")
		self._owner_system:enable_update_function(self.__class_name, "update", self._unit, self)
	end

	return queue_id
end

function MinionSpawnerExtension:remove_spawns_by_id(queue_id)
	self._spawn_queue:remove(queue_id)
end

function MinionSpawnerExtension:clear_all_spawns()
	self._spawn_queue:clear()
end

function MinionSpawnerExtension:is_spawning()
	return self._next_spawn_time and true or false
end

function MinionSpawnerExtension:spawned_minions_by_queue_id(queue_id)
	return self._spawned_minions_by_queue_id[queue_id]
end

function MinionSpawnerExtension:update(unit, dt, t)
	if not self._is_setup then
		return
	end

	local next_spawn_time = self._next_spawn_time

	if next_spawn_time and next_spawn_time <= t then
		local breed_name, spawn_data, queue_id = self._spawn_queue:dequeue()

		if breed_name then
			local spawned_minion = self:_spawn(breed_name, spawn_data)
			local spawnd_minions = self._spawned_minions_by_queue_id
			local spawned_minion_table = spawnd_minions[queue_id]

			if not spawned_minion_table then
				spawned_minion_table = {}
				spawnd_minions[queue_id] = spawned_minion_table
			end

			spawned_minion_table[#spawned_minion_table + 1] = spawned_minion
			self._next_spawn_time = t + spawn_data.spawn_delay
		else
			self._next_spawn_time = nil

			Component.event(self._unit, "minion_spawner_spawning_done")
			self._owner_system:disable_update_function(self.__class_name, "update", self._unit, self)
		end
	end
end

function MinionSpawnerExtension:_spawn(breed_name, spawn_data)
	local breed = Breeds[breed_name]
	local nav_world = self._nav_world
	local exit_position = self._exit_position:unbox()
	local exit_position_valid = MinionSpawnerSpawnPosition.validate_exit_position(nav_world, exit_position, self._traverse_logic)

	if not exit_position_valid then
		Log.warning("[MinionSpawnerExtension]", "Spawning aborted for %q, couldn't find any traversable nav mesh at exit position %s, on unit: %s", breed_name, exit_position, Unit.id_string(self._unit))

		return
	end

	local spawn_position = self._spawn_position:unbox()
	local spawn_rotation = self._spawn_rotation:unbox()
	local mission_objective_id = spawn_data.mission_objective_id
	local spawn_side_id = spawn_data.spawn_side_id
	local target_side_id = spawn_data.target_side_id
	local aggro_state = spawn_data.aggro_state or aggro_states.aggroed
	local target_unit = nil

	if target_side_id and aggro_state == aggro_states.aggroed then
		local main_path_manager = Managers.state.main_path

		if main_path_manager:is_main_path_ready() then
			target_unit = main_path_manager:ahead_unit(target_side_id)
		end
	end

	local unit = self._unit
	local group_id = spawn_data.group_id
	local attack_selection_template_name = spawn_data.attack_selection_template_name
	local spawned_unit = Managers.state.minion_spawn:spawn_minion(breed_name, spawn_position, spawn_rotation, spawn_side_id, aggro_state, target_unit, unit, group_id, mission_objective_id, attack_selection_template_name)
	local max_health_modifier = spawn_data.max_health_modifier

	if max_health_modifier then
		local spawned_unit_health_extension = ScriptUnit.extension(spawned_unit, "health_system")
		local max_health = spawned_unit_health_extension:max_health()

		spawned_unit_health_extension:add_damage(max_health * max_health_modifier)
	end

	return spawned_unit
end

function MinionSpawnerExtension:destroy()
	self._unit = nil
	self._nav_world = nil
	self._nav_tag_cost_table = nil
	self._traverse_logic = nil
	self._spawn_queue = nil
	self._next_spawn_time = nil
end

return MinionSpawnerExtension
