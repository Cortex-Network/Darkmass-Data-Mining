local StatStorage = require("scripts/managers/stats/storage/stat_storage")
local StatSingleValue = class("StatSingleValue", "StatStorage")

function StatSingleValue:init(id, optional_default_value)
	StatSingleValue.super.init(self, id)

	self._default_value = optional_default_value == nil and 0 or optional_default_value
end

function StatSingleValue:set_value(stat_table, value)
	stat_table[self._id] = value
end

function StatSingleValue:get_value(stat_table)
	return stat_table[self._id] or self._default_value
end

implements(StatSingleValue, StatStorage.INTERFACE)

return StatSingleValue
