local PlayerGroupExtension = class("PlayerGroupExtension")

function PlayerGroupExtension:init(extension_init_context, unit, extension_init_data, ...)
	self._bot_group = extension_init_data.bot_group
	self._group_id = extension_init_data.group_id
	self._player = extension_init_data.player
	self._unit = unit
end

function PlayerGroupExtension:extensions_ready(world, unit)
	local group_system = Managers.state.extension:system("group_system")
	local group = group_system:group_from_id(self._group_id)
	self._group = group
end

function PlayerGroupExtension:register_extension_update(unit)
	local player = self._player

	if not player:is_human_controlled() then
		local bot_group = self._bot_group

		bot_group:add_bot_unit(unit)
	end
end

function PlayerGroupExtension:destroy(unit)
	local player = self._player

	if not player:is_human_controlled() then
		local bot_group = self._bot_group

		bot_group:remove_bot_unit(unit)
	end
end

function PlayerGroupExtension:bot_group()
	return self._bot_group
end

function PlayerGroupExtension:bot_group_data()
	local unit = self._unit
	local data = self._bot_group:data_by_unit(unit)

	return data
end

function PlayerGroupExtension:group()
	return self._group
end

function PlayerGroupExtension:group_id()
	return self._group_id
end

function PlayerGroupExtension:leave_group()
	self._group_id = nil
	self._group = nil
end

return PlayerGroupExtension
