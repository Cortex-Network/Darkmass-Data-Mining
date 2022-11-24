local Team = class("Team")

function Team:init(team_config)
	self._name = team_config.name
	self._info_prefix = string.format("Team(%q)", self._name)
	self._num_slots = team_config.num_slots
	self._slots = Script.new_array(self._num_slots)
	self._peer_to_slot_lookup = {}
	self._num_occupied_slots = 0
end

function Team:add_peer(peer_id)
	local slot_id = 0

	for i = 1, self._num_slots do
		if not self._slots[i] then
			slot_id = i

			break
		end
	end

	self._slots[slot_id] = peer_id
	self._peer_to_slot_lookup[peer_id] = slot_id
	self._num_occupied_slots = self._num_occupied_slots + 1

	self:_info("Added peer %q", peer_id)
end

function Team:remove_peer(peer_id)
	local slot_id = self._peer_to_slot_lookup[peer_id]
	self._slots[slot_id] = nil
	self._peer_to_slot_lookup[peer_id] = nil
	self._num_occupied_slots = self._num_occupied_slots - 1

	self:_info("Removed peer %q", peer_id)
end

function Team:has_space()
	return self._num_occupied_slots < self._num_slots
end

function Team:num_unoccupied_slots()
	return self._num_slots - self._num_occupied_slots
end

function Team:name()
	return self._name
end

function Team:_info(...)
	Log.info(self._info_prefix, ...)
end

return Team
