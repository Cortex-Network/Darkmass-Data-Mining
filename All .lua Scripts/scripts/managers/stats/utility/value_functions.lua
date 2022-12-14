local ValueFunctions = {
	constant = function (value)
		return function (...)
			return value
		end
	end,
	multiply = function (func, value)
		return function (...)
			return value * func(...)
		end
	end,
	trivial_stat = function (stat_to_read)
		return function (stat_table, _, _, ...)
			return stat_to_read:get_value(stat_table)
		end
	end
}

function ValueFunctions.stat(triggering_stat, stat_to_read, piped_parameters, fixed_parameters)
	local param_count = #stat_to_read:get_parameters()
	local param_mem = {}

	for name, value in pairs(fixed_parameters) do
		local index_of_name = table.index_of(stat_to_read:get_parameters(), name)
		param_mem[index_of_name] = value
	end

	local piped_triggers = {}

	for read_name, trigger_name in pairs(piped_parameters) do
		local index_of_reading = table.index_of(stat_to_read:get_parameters(), read_name)
		local index_of_triggering = table.index_of(triggering_stat:get_parameters(), trigger_name)
		piped_triggers[index_of_reading] = index_of_triggering
	end

	for i = 1, param_count do
	end

	return function (stat_table, _, _, ...)
		for read_index = 1, param_count do
			local trigger_index = piped_triggers[read_index]

			if trigger_index then
				param_mem[read_index] = select(trigger_index, ...)
			end
		end

		return stat_to_read:get_value(stat_table, unpack(param_mem))
	end
end

function ValueFunctions.param(triggering_stat, param_name)
	local index_of = table.index_of(triggering_stat:get_parameters(), param_name)

	return function (_, _, _, ...)
		return select(index_of, ...)
	end
end

return ValueFunctions
