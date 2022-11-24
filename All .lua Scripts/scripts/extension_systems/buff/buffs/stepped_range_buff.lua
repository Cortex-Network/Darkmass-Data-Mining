require("scripts/extension_systems/buff/buffs/buff")

local SteppedRangeBuff = class("SteppedRangeBuff", "Buff")

function SteppedRangeBuff:init(context, template, start_time, instance_id, ...)
	SteppedRangeBuff.super.init(self, context, template, start_time, instance_id, ...)

	local lerp_value = self._template_context.buff_lerp_value
	self._duration_progress = 0
	self._start_time = start_time
	self._instance_id = instance_id
	self._finished = false
	self._lerped_stat_buffs = {}
	local stat_buffs = {}

	for key, range in pairs(template.stat_buffs) do
		local min = 1
		local max = #range
		local value = math.lerp(min, max, lerp_value)
		local index = math.round(value)
		stat_buffs[key] = range[index]
	end

	self._lerp_value = lerp_value
	self._stat_buffs = stat_buffs
end

function SteppedRangeBuff:debug_get_stat_buffs()
	return self._stat_buffs
end

function SteppedRangeBuff:update_stat_buffs(current_stat_buffs, t)
	self:_calculate_stat_buffs(current_stat_buffs, self._stat_buffs)
end

return SteppedRangeBuff
