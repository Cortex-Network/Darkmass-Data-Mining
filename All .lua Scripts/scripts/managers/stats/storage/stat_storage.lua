local StatStorage = class("StatStorage")
StatStorage.INTERFACE = {
	"set_value",
	"get_value"
}

function StatStorage:init(id, optional_parameters)
	self._parameters = optional_parameters or {}
	self._id = id
end

function StatStorage:get_id()
	return self._id
end

function StatStorage:get_parameters()
	return self._parameters
end

function StatStorage:get_raw(stat_table)
	return stat_table[self._id]
end

return StatStorage
