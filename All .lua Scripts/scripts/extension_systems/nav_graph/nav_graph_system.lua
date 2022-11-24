local SmartObject = require("scripts/extension_systems/nav_graph/utilities/smart_object")

require("scripts/extension_systems/nav_graph/nav_graph_extension")

local NavGraphSystem = class("NavGraphSystem", "ExtensionSystemBase")

function NavGraphSystem:init(...)
	NavGraphSystem.super.init(self, ...)

	self._smart_object_id_to_extension = {}
end

function NavGraphSystem:on_remove_extension(unit, extension_name)
	local extension = self._unit_to_extension_map[unit]
	local smart_object_id_to_extension = self._smart_object_id_to_extension

	for smart_object_id, extension_to_remove in pairs(smart_object_id_to_extension) do
		if extension_to_remove == extension then
			smart_object_id_to_extension[smart_object_id] = nil
		end
	end

	NavGraphSystem.super.on_remove_extension(self, unit, extension_name)
end

function NavGraphSystem:destroy()
	SmartObject.reset_last_smart_object_id()
	NavGraphSystem.super.destroy(self)
end

function NavGraphSystem:register_smart_object_id_to_extension(smart_object_id, extension)
	local smart_object_id_to_extension = self._smart_object_id_to_extension
	smart_object_id_to_extension[smart_object_id] = extension
end

function NavGraphSystem:register_smart_object_ids_to_extension(smart_object_ids, extension)
	local smart_object_id_to_extension = self._smart_object_id_to_extension

	for i = 1, #smart_object_ids do
		local smart_object_id = smart_object_ids[i]
		smart_object_id_to_extension[smart_object_id] = extension
	end
end

function NavGraphSystem:unregister_smart_object_id_from_extension(smart_object_id, extension)
	local smart_object_id_to_extension = self._smart_object_id_to_extension
	smart_object_id_to_extension[smart_object_id] = nil
end

function NavGraphSystem:smart_object_layer_type(smart_object_id)
	local extension = self._smart_object_id_to_extension[smart_object_id]

	if extension then
		local smart_object = extension:smart_object_from_id(smart_object_id)
		local layer_type = smart_object:layer_type()

		return layer_type
	end

	return nil
end

function NavGraphSystem:smart_object_data(smart_object_id)
	local extension = self._smart_object_id_to_extension[smart_object_id]

	if extension then
		local smart_object = extension:smart_object_from_id(smart_object_id)

		return smart_object:data()
	end

	return nil
end

function NavGraphSystem:unit_from_smart_object_id(smart_object_id)
	local extension = self._smart_object_id_to_extension[smart_object_id]

	if extension then
		local unit = extension:unit()

		return unit
	end

	return nil
end

return NavGraphSystem
