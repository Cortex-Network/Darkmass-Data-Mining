local GameplayInitTimeSlice = {
	MAX_DT_IN_MSEC = 33.333333333333336
}
GameplayInitTimeSlice.MAX_DT_IN_SEC = GameplayInitTimeSlice.MAX_DT_IN_MSEC / 1000

function GameplayInitTimeSlice.pre_loop()
	local performance_counter_handle = Application.query_performance_counter()
	local duration_ms = 0

	return performance_counter_handle, duration_ms
end

function GameplayInitTimeSlice.pre_process(performance_counter_handle, duration_ms, max_dt_in_msec)
	local max_dt_in_msec = max_dt_in_msec or GameplayInitTimeSlice.MAX_DT_IN_MSEC

	if duration_ms < max_dt_in_msec then
		local start_timer = Application.time_since_query(performance_counter_handle)

		return start_timer
	end

	return nil
end

function GameplayInitTimeSlice.post_process(performance_counter_handle, start_timer, duration_ms)
	local finish_timer = Application.time_since_query(performance_counter_handle)
	local delta_ms = finish_timer - start_timer
	duration_ms = duration_ms + delta_ms

	return duration_ms
end

function GameplayInitTimeSlice.set_finished(data)
	table.clear(data)

	data.ready = true
end

return GameplayInitTimeSlice
