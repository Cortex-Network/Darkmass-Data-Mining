require("scripts/extension_systems/broadphase/broadphase_extension")

local Pickups = require("scripts/settings/pickup/pickups")
local BroadphaseSystem = class("BroadphaseSystem", "ExtensionSystemBase")

local function _generate_broadphase_categories(system_init_data)
	local side_names = system_init_data.side_names
	local broadphase_categories = table.append({
		"doors",
		"pickups"
	}, side_names)
	local pickup_groups = Pickups.by_group

	for group_name, _ in pairs(pickup_groups) do
		broadphase_categories[#broadphase_categories + 1] = group_name
	end

	return broadphase_categories
end

local BROADPHASE_CELL_RADIUS = 50
local MAX_EXPECTED_ENTITIES = 512

function BroadphaseSystem:init(extension_system_creation_context, system_init_data, ...)
	BroadphaseSystem.super.init(self, extension_system_creation_context, system_init_data, ...)

	local broadphase_categories = _generate_broadphase_categories(system_init_data)
	self.broadphase = Broadphase(BROADPHASE_CELL_RADIUS, MAX_EXPECTED_ENTITIES, broadphase_categories)
	self._extension_init_context.broadphase = self.broadphase
	self._moving_units = Script.new_map(256)

	Managers.event:register(self, "unit_died", "_event_unit_died")
end

function BroadphaseSystem:destroy()
	Managers.event:unregister(self, "unit_died")
	BroadphaseSystem.super.destroy(self)
end

function BroadphaseSystem:on_add_extension(world, unit, extension_name, extension_init_data)
	local extension = BroadphaseSystem.super.on_add_extension(self, world, unit, extension_name, extension_init_data)

	if extension_init_data.moving then
		self._moving_units[unit] = extension._broadphase_id
	end

	return extension
end

function BroadphaseSystem:on_remove_extension(unit, extension_name)
	self._moving_units[unit] = nil

	BroadphaseSystem.super.on_remove_extension(self, unit, extension_name)
end

function BroadphaseSystem:_event_unit_died(unit)
	self._moving_units[unit] = nil
end

function BroadphaseSystem:update(context, dt, t, ...)
	local broadphase_move = Broadphase.move
	local broadphase = self.broadphase
	local POSITION_LOOKUP = POSITION_LOOKUP

	for unit, broadphase_id in pairs(self._moving_units) do
		broadphase_move(broadphase, broadphase_id, POSITION_LOOKUP[unit])
	end
end

return BroadphaseSystem
