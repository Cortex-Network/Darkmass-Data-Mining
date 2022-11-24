require("scripts/foundation/utilities/script_unit")

local ExtensionConfig = class("ExtensionConfig")
local EMPTY_TABLE = {}

function ExtensionConfig:init()
	self._extension_data = {}
	self._num_extensions = 0
	self._unit_extensions = {}
end

function ExtensionConfig:reset()
	table.clear(self._extension_data)

	self._num_extensions = 0

	table.clear(self._unit_extensions)
end

function ExtensionConfig:parse_unit(unit)
	self._unit_extensions = ScriptUnit.extension_definitions(unit)
end

function ExtensionConfig:add(extension_class_name, init_args, remove_when_killed)
	local index = self._num_extensions * 3 + 1
	local exts = self._extension_data
	exts[index] = extension_class_name
	exts[index + 1] = init_args
	exts[index + 2] = remove_when_killed
	self._num_extensions = self._num_extensions + 1
end

function ExtensionConfig:num_extensions()
	if #self._unit_extensions > 0 then
		return #self._unit_extensions
	else
		return self._num_extensions
	end
end

function ExtensionConfig:extension(i)
	local unit_extensions = self._unit_extensions

	if #unit_extensions > 0 then
		return unit_extensions[i], EMPTY_TABLE, false
	else
		local index = (i - 1) * 3 + 1
		local extension_data = self._extension_data

		return extension_data[index], extension_data[index + 1], extension_data[index + 2]
	end
end

return ExtensionConfig
