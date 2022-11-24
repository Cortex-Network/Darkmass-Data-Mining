local DialogueQueryQueue = class("DialogueQueryQueue")

function DialogueQueryQueue:init()
	self._input_query_queue = {}
	self._input_query_queue_n = 0
end

function DialogueQueryQueue:get_query(t)
	local found_time = math.huge
	local answer_query = nil

	for query_time, query in pairs(self._input_query_queue) do
		if query_time < t and query_time < found_time then
			found_time = query_time
			answer_query = query
		end
	end

	if answer_query then
		self._input_query_queue[found_time] = nil

		return answer_query
	end

	return nil
end

function DialogueQueryQueue:queue_query(target_time, query)
	self._input_query_queue[target_time] = query
end

return DialogueQueryQueue
