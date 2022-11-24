local PackageManager = require("scripts/foundation/managers/package/package_manager")
local PackageManagerEditor = class("PackageManagerEditor")
PackageManagerEditor.FIRST_ITEM = 1

function PackageManagerEditor:init()
	self._current_item = PackageManagerEditor.FIRST_ITEM
	self._callback_queue = {}
end

function PackageManagerEditor:load(package_name, reference_name, callback, prioritize)
	local id = self._current_item

	if callback then
		local item = {
			id = id,
			callback = callback
		}
		self._callback_queue[#self._callback_queue + 1] = item
	end

	self._current_item = self._current_item + 1

	return id
end

function PackageManagerEditor:release(id)
end

function PackageManagerEditor:can_unload(package_name)
	return true
end

function PackageManagerEditor:shutdown_has_started()
end

function PackageManagerEditor:destroy()
end

function PackageManagerEditor:is_loading_now(package)
	return false
end

function PackageManagerEditor:is_loading(package)
	return false
end

function PackageManagerEditor:has_loaded(package_name)
	return true
end

function PackageManagerEditor:has_loaded_id(id)
	return true
end

function PackageManagerEditor:package_loaded(package_name)
	return true
end

function PackageManagerEditor:temp_hack_id_from_name_and_reference(package_name, reference_name)
	return 0
end

function PackageManagerEditor:reference_count(package, reference_name)
	return 0
end

function PackageManagerEditor:all_reference_count(reference_name)
	return 0
end

function PackageManagerEditor:package_is_known(package)
	return true
end

function PackageManagerEditor:update()
	local callback_queue = table.clone(self._callback_queue)

	table.clear(self._callback_queue)

	for i = 1, #callback_queue do
		local item = callback_queue[i]

		item.callback(item.id)
	end

	return true
end

function PackageManagerEditor:dump_reference_counter(reference_name)
end

function PackageManagerEditor:dump_all()
end

function PackageManagerEditor:references()
end

local interface = {}
local i = 1

for name, value in pairs(PackageManager) do
	if type(value) == "function" and string.sub(name, 1, 1) ~= "_" then
		interface[i] = name
		i = i + 1
	end
end

implements(PackageManagerEditor, interface)

return PackageManagerEditor
