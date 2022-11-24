require("scripts/extension_systems/buff/buffs/buff")

local TimedTriggerBuff = class("TimedTriggerBuff", "Buff")

function TimedTriggerBuff:init(context, template, start_time, instance_id, ...)
	TimedTriggerBuff.super.init(self, context, template, start_time, instance_id, ...)

	self._active_start_time = start_time
end

function TimedTriggerBuff:destroy()
	local buff_component = self._buff_component

	if buff_component then
		local component_keys = self._component_keys
		local active_start_time = component_keys.active_start_time_key
		buff_component[active_start_time] = 0
	end

	TimedTriggerBuff.super.destroy(self)
end

function TimedTriggerBuff:update(dt, t, portable_random)
	TimedTriggerBuff.super.update(self, dt, t, portable_random)

	local template = self._template
	local active_duration = template.active_duration
	local active_start_time = self._active_start_time

	if active_duration and active_start_time > 0 and t > active_start_time + active_duration then
		template.trigger_function(self._template_data, self._template_context)

		self._active_start_time = 0
	end
end

function TimedTriggerBuff:active_start_time()
	return self._active_start_time
end

function TimedTriggerBuff:set_active_start_time(active_start_time)
	self._active_start_time = active_start_time
end

return TimedTriggerBuff
