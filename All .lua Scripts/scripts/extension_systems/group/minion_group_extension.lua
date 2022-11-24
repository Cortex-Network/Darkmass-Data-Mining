local MinionGroupExtension = class("MinionGroupExtension")

function MinionGroupExtension:init(extension_init_context, unit, extension_init_data, ...)
	local group_id = extension_init_data.group_id
	self._group_id = group_id
end

function MinionGroupExtension:extensions_ready(world, unit)
	local group_system = Managers.state.extension:system("group_system")
	local group = group_system:group_from_id(self._group_id)
	self._group = group
end

function MinionGroupExtension:group()
	return self._group
end

function MinionGroupExtension:group_id()
	return self._group_id
end

function MinionGroupExtension:leave_group()
	self._group_id = nil
	self._group = nil
end

return MinionGroupExtension
