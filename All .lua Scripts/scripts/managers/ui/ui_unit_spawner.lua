local GrowQueue = require("scripts/foundation/utilities/grow_queue")
local Unit_alive = Unit.alive
local UIUnitSpawner = class("UIUnitSpawner")
local DELETION_STATES = table.enum("default", "in_network_layers", "removing_units")
UIUnitSpawner.DELETION_STATES = DELETION_STATES

function UIUnitSpawner:init(world)
	self._world = world
	self._deletion_queue = GrowQueue:new()
	self._num_deleted_units = 0
	self._deletion_state = DELETION_STATES.default
	self._temp_units_list = {}
end

function UIUnitSpawner:destroy()
	self._unit_destroy_listeners = nil
end

function UIUnitSpawner:remove_pending_units()
	local num_removed = nil

	repeat
		num_removed = self:_remove_units_marked_for_deletion()
	until num_removed == 0
end

function UIUnitSpawner:mark_for_deletion(unit)
	local deletion_state = self._deletion_state

	if deletion_state == DELETION_STATES.removing_units then
		Unit.flow_event(unit, "cleanup_before_destroy")

		self._num_deleted_units = self._num_deleted_units + 1
		self._temp_units_list[self._num_deleted_units] = unit
	else
		self._deletion_queue:push_back(unit)
	end
end

function UIUnitSpawner:_remove_units_marked_for_deletion()
	if self._deletion_queue:size() == 0 then
		return 0
	end

	local temp_deleted_units_list = self._temp_units_list
	self._num_deleted_units = 0

	self:_set_deletion_state(DELETION_STATES.removing_units)

	local unit = self._deletion_queue:pop_first()

	while unit do
		Unit.flow_event(unit, "cleanup_before_destroy")

		self._num_deleted_units = self._num_deleted_units + 1
		temp_deleted_units_list[self._num_deleted_units] = unit
		unit = self._deletion_queue:pop_first()
	end

	self:_set_deletion_state(DELETION_STATES.default)

	local world = self._world
	local num_deleted_units = self._num_deleted_units

	self:_world_delete_units(world, temp_deleted_units_list, num_deleted_units)

	return num_deleted_units
end

function UIUnitSpawner:_set_deletion_state(state)
	self._deletion_state = state
end

function UIUnitSpawner:spawn_unit(unit_name, ...)
	local unit = World.spawn_unit_ex(self._world, unit_name, nil, ...)

	Unit.set_data(unit, "unit_name", unit_name)

	return unit
end

function UIUnitSpawner:_world_delete_units(world, units_list, num_units)
	for i = 1, num_units do
		local unit = units_list[i]
		local unit_is_alive = Unit_alive(unit)

		Unit.flow_event(unit, "unit_despawned")
		World.destroy_unit(world, unit)
	end
end

local TEMP_UNIT_TABLE = {}

function UIUnitSpawner:_world_delete_unit(world, unit)
	TEMP_UNIT_TABLE[1] = unit

	self:_world_delete_units(world, TEMP_UNIT_TABLE, 1)
end

return UIUnitSpawner
