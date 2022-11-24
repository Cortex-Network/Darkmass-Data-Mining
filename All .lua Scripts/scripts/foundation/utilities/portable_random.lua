local PortableRandom = class("PortableRandom")

function PortableRandom:init(seed)
	self:set_seed(seed)
end

function PortableRandom:next_random()
	local seed, random_value = math.next_random(self._seed)
	self._seed = seed

	return random_value
end

function PortableRandom:random_range(min, max)
	local seed, random_value = math.next_random(self._seed, min, max)
	self._seed = seed

	return random_value
end

function PortableRandom:seed()
	return self._seed
end

function PortableRandom:set_seed(seed)
	self._seed = seed
end

return PortableRandom
