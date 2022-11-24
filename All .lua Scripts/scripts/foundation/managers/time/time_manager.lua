local Timer = require("scripts/foundation/managers/time/timer")
local TimeManager = class("TimeManager")

function TimeManager:init(dt)
	self._timers = {
		main = Timer:new("main", nil, 0, dt)
	}
	self._dt_stack = {}
	self._dt_stack_max_size = 10
	self._dt_stack_index = self._dt_stack_max_size
	self._mean_dt = 0
	self._dt = dt
end

function TimeManager:register_timer(name, parent_name, start_time)
	local timers = self._timers
	local parent_timer = timers[parent_name]
	local new_timer = Timer:new(name, parent_timer, start_time, self._dt)

	parent_timer:add_child(new_timer)

	timers[name] = new_timer
end

function TimeManager:unregister_timer(name)
	local timer = self._timers[name]
	local parent = timer:parent()

	if parent then
		parent:remove_child(timer)
	end

	timer:destroy()

	self._timers[name] = nil
end

function TimeManager:has_timer(name)
	return self._timers[name] and true or false
end

function TimeManager:update(dt)
	self._dt = dt
	local main_timer = self._timers.main

	if main_timer:active() then
		main_timer:update(dt, 1)
	end

	self:_update_mean_dt(dt)
end

function TimeManager:_update_mean_dt(dt)
	self._dt_stack_index = self._dt_stack_index % self._dt_stack_max_size + 1
	local dt_stack = self._dt_stack
	dt_stack[self._dt_stack_index] = dt
	local dt_sum = 0
	local dt_stack_size = #dt_stack

	for i = 1, dt_stack_size do
		local dt_stack_entry = dt_stack[i]
		dt_sum = dt_sum + dt_stack_entry
	end

	self._mean_dt = dt_sum / dt_stack_size
end

function TimeManager:mean_dt()
	return self._mean_dt
end

function TimeManager:set_time(name, time)
	self._timers[name]:set_time(time)
end

function TimeManager:time(name)
	return self._timers[name]:time()
end

function TimeManager:delta_time(name)
	return self._timers[name]:delta_time()
end

function TimeManager:active(name)
	return self._timers[name]:active()
end

function TimeManager:set_active(name, active)
	self._timers[name]:set_active(active)
end

function TimeManager:set_local_scale(name, scale)
	self._timers[name]:set_local_scale(scale)
end

function TimeManager:local_scale(name)
	return self._timers[name]:local_scale()
end

function TimeManager:destroy()
	for name, timer in pairs(self._timers) do
		timer:destroy()
	end

	self._timers = nil
end

return TimeManager
