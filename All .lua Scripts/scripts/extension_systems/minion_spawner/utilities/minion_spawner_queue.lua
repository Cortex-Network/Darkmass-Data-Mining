local MinionSpawnerQueue = class("MinionSpawnerQueue")

function MinionSpawnerQueue:init()
	self._queue = {}
	self._queue_id = 1
end

local function _queue_index_from_id(queue, queue_id)
	for i = 1, #queue do
		if queue[i].queue_id == queue_id then
			return i
		end
	end

	return nil
end

function MinionSpawnerQueue:enqueue(breed_list, spawn_data)
	local queue_id = self._queue_id
	self._queue_id = queue_id + 1
	local queue = self._queue
	queue[#queue + 1] = {
		breed_list_index = 1,
		queue_id = queue_id,
		breed_list = breed_list,
		breed_list_size = #breed_list,
		spawn_data = table.set_readonly(spawn_data)
	}

	return queue_id
end

function MinionSpawnerQueue:dequeue()
	local queue = self._queue
	local head_item = queue[1]

	if not head_item then
		return nil, , 
	end

	local breed_list = head_item.breed_list
	local breed_list_index = head_item.breed_list_index
	local breed_list_size = head_item.breed_list_size
	local spawn_data = head_item.spawn_data
	local queue_id = head_item.queue_id
	local breed = breed_list[breed_list_index]

	if breed_list_index == breed_list_size then
		table.remove(queue, 1)
	else
		head_item.breed_list_index = breed_list_index + 1
	end

	return breed, spawn_data, queue_id
end

function MinionSpawnerQueue:remove(queue_id)
	local queue = self._queue
	local queue_index = _queue_index_from_id(queue, queue_id)

	if queue_index then
		table.remove(queue, queue_index)
	end
end

function MinionSpawnerQueue:clear()
	table.clear(self._queue)
end

function MinionSpawnerQueue:is_empty()
	return #self._queue == 0
end

local debug_info = {}

function MinionSpawnerQueue:get_debug_info()
	table.clear(debug_info)

	local queue = self._queue

	for i = 1, #queue do
		local item = queue[i]
		local queue_id = item.queue_id
		local breed_list = item.breed_list
		local spawn_data = item.spawn_data

		for j = item.breed_list_index, item.breed_list_size do
			local breed = breed_list[j]
			debug_info[#debug_info + 1] = {
				queue_id = queue_id,
				breed = breed,
				spawn_data = spawn_data
			}
		end
	end

	return debug_info
end

return MinionSpawnerQueue
