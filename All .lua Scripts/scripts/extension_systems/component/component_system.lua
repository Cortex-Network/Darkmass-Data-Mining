require("scripts/extension_systems/component/component_extension")

local Component = require("scripts/utilities/component")
local ComponentSystem = class("ComponentSystem", "ExtensionSystemBase")
local RPCS = {
	Component.default_rpc_name,
	"rpc_animation_play_client",
	"rpc_networked_unique_randomize_roll"
}

function ComponentSystem:init(...)
	ComponentSystem.super.init(self, ...)

	self._component_name_to_units_map = {}

	for _, rpc_name in pairs(RPCS) do
		self[rpc_name] = Component.receive_client_event
	end

	local network_event_delegate = self._network_event_delegate

	if not self._is_server and network_event_delegate then
		network_event_delegate:register_session_events(self, unpack(RPCS))
	end
end

function ComponentSystem:destroy(...)
	local network_event_delegate = self._network_event_delegate

	if not self._is_server and network_event_delegate then
		network_event_delegate:unregister_events(unpack(RPCS))
	end

	ComponentSystem.super.destroy(self, ...)
end

function ComponentSystem:on_add_extension(world, unit, extension_name, extension_init_data, ...)
	local extension = ComponentSystem.super.on_add_extension(self, world, unit, extension_name, extension_init_data, ...)
	local component_name_to_units_map = self._component_name_to_units_map
	local components = extension:components()

	for i = 1, #components do
		local component_name = components[i]:name()
		component_name_to_units_map[component_name] = component_name_to_units_map[component_name] or {}
		local unit_list = component_name_to_units_map[component_name]
		unit_list[#unit_list + 1] = unit
	end

	return extension
end

function ComponentSystem:on_remove_extension(unit, extension_name)
	local component_name_to_units_map = self._component_name_to_units_map

	for component_name, unit_list in pairs(component_name_to_units_map) do
		for index = #unit_list, 1, -1 do
			local registered_unit = unit_list[index]

			if registered_unit == unit then
				table.swap_delete(unit_list, index)
			end
		end
	end

	ComponentSystem.super.on_remove_extension(self, unit, extension_name)
end

function ComponentSystem:register_extension_update(unit, extension_name, extension)
	ComponentSystem.super.register_extension_update(self, unit, extension_name, extension)
	extension:on_register_update()
end

function ComponentSystem:on_gameplay_post_init(level)
	local unit_to_extension_map = self._unit_to_extension_map

	for unit, extension in pairs(unit_to_extension_map) do
		extension:on_gameplay_post_init(unit, level)
	end
end

function ComponentSystem:enable_component(unit, guid)
	local extension = self._unit_to_extension_map[unit]

	extension:enable_component(guid)
end

function ComponentSystem:disable_component(unit, guid)
	local extension = self._unit_to_extension_map[unit]

	extension:disable_component(guid)
end

function ComponentSystem:trigger_event(unit, event_name, ...)
	local extension = self._unit_to_extension_map[unit]

	if extension then
		extension:trigger_event(event_name, ...)

		return true
	else
		return false
	end
end

function ComponentSystem:flow_call_component(unit, guid, function_name, ...)
	local extension = self._unit_to_extension_map[unit]

	extension:flow_call_component(guid, function_name, ...)
end

function ComponentSystem:get_components(unit, component_name)
	local result = {}
	local extension = self._unit_to_extension_map[unit]

	if extension then
		local components = extension:components()

		for i = 1, #components do
			if components[i]:name() == component_name then
				result[#result + 1] = components[i]
			end
		end
	end

	return result
end

function ComponentSystem:get_units_from_component_name(component_name)
	return self._component_name_to_units_map[component_name] or {}
end

return ComponentSystem
