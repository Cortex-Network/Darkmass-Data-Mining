local StatTrigger = class("StatTrigger")

function StatTrigger:init(calling_function, optional_param_function)
	self._calling_function = calling_function
	self._param_function = optional_param_function
end

function StatTrigger:get_parameters(trigger_value, ...)
	if self._param_function then
		return self._param_function(trigger_value, ...)
	end
end

function StatTrigger:activate(stat_table, current_value, triggered_value, ...)
	return self._calling_function(stat_table, current_value, triggered_value, ...)
end

return StatTrigger
