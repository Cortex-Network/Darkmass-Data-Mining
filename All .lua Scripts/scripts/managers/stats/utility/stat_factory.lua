local StatDefinition = require("scripts/managers/stats/stat_definition")
local Activations = require("scripts/managers/stats/utility/activation_functions")
local Parameters = require("scripts/managers/stats/utility/parameter_functions")
local Conditions = require("scripts/managers/stats/utility/conditional_functions")
local NoSave = require("scripts/managers/stats/storage/stat_no_save")
local SingleValue = require("scripts/managers/stats/storage/stat_single_value")
local Tree = require("scripts/managers/stats/storage/stat_tree")
local StatTrigger = require("scripts/managers/stats/stat_trigger")
local StatFactory = {
	create_group = function ()
		return {
			definitions = {},
			triggered_by = {}
		}
	end
}

function StatFactory.add_to_group(group, stat_definition, ...)
	if stat_definition ~= nil then
		local id = stat_definition:get_id()
		group.definitions[id] = stat_definition

		for _, stat_name in ipairs(stat_definition:get_triggers()) do
			local triggered_by = group.triggered_by[stat_name] or {}
			triggered_by[#triggered_by + 1] = id
			group.triggered_by[stat_name] = triggered_by
		end
	end

	if select("#", ...) > 0 then
		StatFactory.add_to_group(group, ...)
	end
end

function StatFactory.create_hook(id, params, optional_flags)
	return StatDefinition:new({}, NoSave:new(id, params), optional_flags)
end

function StatFactory.ping_on_any(id, optional_flags, ...)
	local triggers = {}

	for _, stat in ipairs({
		...
	}) do
		triggers[stat:get_id()] = StatTrigger:new(Activations.constant(nil))
	end

	return StatDefinition:new(triggers, NoSave:new(id), optional_flags)
end

function StatFactory.create_dynamic_reducer(id, stat_to_reduce, in_parameters, activation_function, optional_out_parameters, optional_flags, optional_default_value)
	local out_parameters = optional_out_parameters or in_parameters

	return StatDefinition:new({
		[stat_to_reduce:get_id()] = StatTrigger:new(activation_function, Parameters.pick(stat_to_reduce, unpack(in_parameters)))
	}, Tree:new(id, out_parameters, optional_default_value), optional_flags)
end

function StatFactory.create_smart_reducer(id, stat_to_reduce, in_parameters, transformers, out_parameters, activation_function, optional_flags, optional_default_value)
	return StatDefinition:new({
		[stat_to_reduce:get_id()] = StatTrigger:new(activation_function, Parameters.smart_pick(stat_to_reduce, in_parameters, transformers))
	}, Tree:new(id, out_parameters, optional_default_value), optional_flags)
end

function StatFactory.create_merger(id, stats, activation_function, optional_flags, optional_default_value)
	optional_default_value = optional_default_value ~= nil and optional_default_value or 0
	local triggers = {}

	for i = 1, #stats do
		local stat = stats[i]
		triggers[stat:get_id()] = StatTrigger:new(activation_function)
	end

	return StatDefinition:new(triggers, SingleValue:new(id, optional_default_value), optional_flags)
end

function StatFactory.create_flag(id, listens_to, optional_condition, optional_flags)
	local activation_function = optional_condition and Activations.on_condition(optional_condition, Activations.set(1)) or Activations.set(1)

	return StatDefinition:new({
		[listens_to:get_id()] = StatTrigger:new(activation_function)
	}, SingleValue:new(id, 0), optional_flags)
end

function StatFactory.create_flag_checker(id, flags, optional_flags, optional_max_amount)
	optional_max_amount = optional_max_amount or #flags
	local activation_function = Activations.clamp(Activations.increment, 0, optional_max_amount)

	return StatFactory.create_merger(id, flags, activation_function, optional_flags, 0)
end

function StatFactory.create_simple(id, stat_to_reduce, activation_function, optional_flags, optional_default_value)
	return StatDefinition:new({
		[stat_to_reduce:get_id()] = StatTrigger:new(activation_function)
	}, SingleValue:new(id, optional_default_value), optional_flags)
end

function StatFactory.create_transformer(id, stat_to_reduce, activation_function, optional_parameter_function, optional_out_params)
	return StatDefinition:new({
		[stat_to_reduce:get_id()] = StatTrigger:new(activation_function, optional_parameter_function)
	}, NoSave:new(id, optional_out_params))
end

function StatFactory.create_echo(id, stat_to_echo, optional_condition, optional_delay, optional_flags)
	local delay = optional_delay or 0
	local condition = optional_condition or Conditions.always_true

	return StatDefinition:new({
		[stat_to_echo:get_id()] = StatTrigger:new(Activations.on_condition(condition, delay > 0 and Activations.with_delay(delay, Activations.echo) or Activations.echo), Parameters.echo)
	}, NoSave:new(id, stat_to_echo:get_parameters()), optional_flags)
end

function StatFactory.create_in_a_row(id, increase_on_stat, reset_on_stat, optional_flags)
	return StatDefinition:new({
		[increase_on_stat:get_id()] = StatTrigger:new(Activations.increment),
		[reset_on_stat:get_id()] = StatTrigger:new(Activations.set(0))
	}, SingleValue:new(id, 0), optional_flags)
end

function StatFactory.create_flag_switch(id, set_on_stat, reset_on_stat, optional_flags, optional_start_active)
	local start_value = optional_start_active == true and 1 or 0

	return StatDefinition:new({
		[set_on_stat:get_id()] = StatTrigger:new(Activations.set(1)),
		[reset_on_stat:get_id()] = StatTrigger:new(Activations.set(0))
	}, SingleValue:new(id, start_value), optional_flags)
end

function StatFactory.create_sum_over_time(id, input_stat, time, optional_condition, optional_flags)
	local condition = optional_condition or Conditions.always_true
	local echo_stat = StatFactory.create_echo(string.format("_%s_anti", id), input_stat, nil, time)
	local sum_stat = StatDefinition:new({
		[input_stat:get_id()] = StatTrigger:new(Activations.on_condition(condition, Activations.sum)),
		[echo_stat:get_id()] = StatTrigger:new(Activations.on_condition(condition, Activations.difference))
	}, SingleValue:new(id, 0), optional_flags)

	return echo_stat, sum_stat
end

return StatFactory
