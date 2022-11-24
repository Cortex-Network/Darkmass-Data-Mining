local GrowQueue = class("GrowQueue")

function GrowQueue:init()
	self.queue = {}
	self.first = 1
	self.last = 0
end

function GrowQueue:push_back(item)
	self.last = self.last + 1
	self.queue[self.last] = item
end

function GrowQueue:pop_first()
	if self.last < self.first then
		return
	end

	local item = self.queue[self.first]
	self.queue[self.first] = nil

	if self.first == self.last then
		self.first = 0
		self.last = 0
	end

	self.first = self.first + 1

	return item
end

function GrowQueue:contains(item)
	local first = self.first
	local last = self.last
	local queue = self.queue

	for i = first, last do
		local queued_item = queue[i]

		if item == queued_item then
			return true
		end
	end

	return false
end

function GrowQueue:size()
	return self.last - self.first + 1
end

function GrowQueue:get_first()
	return self.queue[self.first]
end

function GrowQueue:get_last()
	return self.queue[self._last]
end

function GrowQueue:print_items(s)
	local s = (s or "") .. " queue: [" .. self.first .. "->" .. self.last .. "] --> "

	for i = self.first, self.last do
		s = s .. tostring(self.queue[i]) .. ","
	end

	print(s)
end

return GrowQueue
