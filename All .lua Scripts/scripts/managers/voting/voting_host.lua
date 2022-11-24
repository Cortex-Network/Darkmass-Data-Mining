local VotingHost = class("VotingHost")

local function _info(...)
	Log.info("VotingHost", ...)
end

local STATES = table.enum("in_progress", "completed", "aborted")

function VotingHost:init(voting_id, initiator_peer, template, optional_params)
	self._voting_id = voting_id
	self._initiator_peer = initiator_peer
	self._template = template
	local params = optional_params or {}
	self._params = params
	local network_interface = template.network_interface()
	self._network_interface = network_interface
	local duration = template.duration
	self._duration = duration
	self._time = 0
	self._member_list = {}
	self._votes = {}
	self._result = nil
	self._abort_reason = nil
	self._state = STATES.in_progress
	local member_list = network_interface:member_peers()

	if not DEDICATED_SERVER then
		member_list[#member_list + 1] = Network.peer_id()
	end

	local initial_votes_by_peer = {}

	if template.initial_votes then
		initial_votes_by_peer = template.initial_votes(params, initiator_peer)
	end

	local initial_votes_list = {}

	for i = 1, #member_list do
		local peer_id = member_list[i]
		self._member_list[i] = peer_id
		local initial_vote_option = initial_votes_by_peer[peer_id]

		if initial_vote_option then
			self._votes[peer_id] = initial_vote_option
			initial_votes_list[i] = NetworkLookup.voting_options[initial_vote_option]

			_info("Auto-voted %q for %s", initial_vote_option, peer_id)
		else
			self._votes[peer_id] = StrictNil
			initial_votes_list[i] = NetworkLookup.voting_options["nil"]
		end
	end

	local rpc_start_voting = template.rpc_start_voting
	local template_id = NetworkLookup.voting_templates[template.name]

	if initiator_peer == Network.peer_id() then
		self:_send_rpc_members(rpc_start_voting, voting_id, template_id, initiator_peer, member_list, initial_votes_list, duration, template.pack_params(params))
		_info("Initiated voting %q (%s), params: %s", voting_id, template.name, table.tostring(params))
	else
		self:_send_rpc_members_except(rpc_start_voting, initiator_peer, voting_id, template_id, initiator_peer, member_list, initial_votes_list, duration, template.pack_params(params))

		local channel_id = network_interface:peer_to_channel(initiator_peer)

		RPC.rpc_voting_accepted(channel_id, voting_id, member_list, initial_votes_list, duration)
		_info("Accepted voting %q (%s) initiated by %s, params: %s", voting_id, template.name, initiator_peer, table.tostring(params))
	end
end

function VotingHost:destroy()
	self._template = nil
	self._params = nil
	self._member_list = nil
	self._votes = nil
end

function VotingHost:is_host()
	return true
end

function VotingHost:state()
	return self._state
end

function VotingHost:on_member_joined(peer_id)
	local member_list = self._member_list
	member_list[#member_list + 1] = peer_id
	local votes = self._votes
	votes[peer_id] = StrictNil
	local votes_list_lookup = {}

	for i = 1, #member_list do
		local member_peer_id = member_list[i]
		local vote_option = votes[member_peer_id]

		if vote_option == StrictNil then
			votes_list_lookup[i] = NetworkLookup.voting_options["nil"]
		else
			votes_list_lookup[i] = NetworkLookup.voting_options[vote_option]
		end
	end

	local template = self._template
	local rpc_start_voting = template.rpc_start_voting
	local channel_id = self._network_interface:peer_to_channel(peer_id)
	local voting_id = self._voting_id
	local template_id = NetworkLookup.voting_templates[template.name]
	local initiator_peer = self._initiator_peer
	local time_left = self._duration and math.max(self._duration - self._time, 0) or nil
	local params = self._params

	RPC[rpc_start_voting](channel_id, voting_id, template_id, initiator_peer, member_list, votes_list_lookup, time_left, template.pack_params(params))
	self:_send_rpc_members_except("rpc_voting_member_joined", peer_id, self._voting_id, peer_id)
	_info("Voting member %s joined voting %q", peer_id, self._voting_id)
end

function VotingHost:on_member_left(peer_id)
	local member_list = self._member_list
	local index = table.index_of(member_list, peer_id)

	table.remove(member_list, index)

	self._votes[peer_id] = nil

	self:_send_rpc_members("rpc_voting_member_left", self._voting_id, peer_id)
	_info("Voting member %s left voting %q", peer_id, self._voting_id)
end

function VotingHost:on_voting_aborted(reason, disconnected_peer_id)
	self._state = STATES.aborted
	self._abort_reason = reason

	if disconnected_peer_id then
		local member_list = self._member_list
		local index = table.index_of(member_list, disconnected_peer_id)

		table.remove(member_list, index)

		self._votes[disconnected_peer_id] = nil
	end

	self:_send_rpc_members("rpc_voting_aborted", self._voting_id, reason)
	_info("Voting %q aborted, reason: %s", self._voting_id, reason)
end

function VotingHost:has_member(peer_id)
	return table.index_of(self._member_list, peer_id) ~= -1
end

function VotingHost:has_voted(peer_id)
	return self._votes[peer_id] ~= StrictNil
end

function VotingHost:has_option(option)
	return table.contains(self._template.options, option)
end

function VotingHost:network_interface()
	return self._network_interface
end

function VotingHost:template()
	return self._template
end

function VotingHost:params()
	return self._params
end

local member_list_copy = {}

function VotingHost:member_list()
	table.clear(member_list_copy)

	local member_list = self._member_list

	for i = 1, member_list do
		member_list_copy[i] = member_list[i]
	end

	return member_list_copy
end

local votes_copy = {}

function VotingHost:votes()
	table.clear(votes_copy)

	for peer_id, vote in pairs(self._votes) do
		votes_copy[peer_id] = vote
	end

	return votes_copy
end

function VotingHost:time_left()
	local duration = self._duration

	if not duration then
		return nil, 
	end

	local time_left = math.max(self._duration - self._time, 0)
	local time_left_normalized = math.max(time_left / duration, 0)

	return time_left, time_left_normalized
end

function VotingHost:register_vote(voter_peer_id, option)
	self._votes[voter_peer_id] = option
	local option_id = NetworkLookup.voting_options[option]
	local voting_id = self._voting_id

	self:_send_rpc_members("rpc_register_vote", voting_id, voter_peer_id, option_id)

	local template = self._template

	_info("Registered vote %q casted by %s in voting %q (%s)", option, voter_peer_id, voting_id, template.name)
end

function VotingHost:update(dt, t)
	if self._state ~= STATES.in_progress then
		return
	end

	local time = self._time + dt
	self._time = time
	local template = self._template
	local evaluate_delay = template.evaluate_delay

	if evaluate_delay and time < evaluate_delay then
		return
	end

	local duration = self._duration

	if duration then
		local time_left = duration - time

		if time_left <= 0 then
			_info("Voting %q timed out", self._voting_id)
			self:_handle_undecided_votes()
		end
	end

	local result = template.evaluate(self._votes)

	if result then
		self._state = STATES.completed
		self._result = result
		local result_id = NetworkLookup.voting_results[result]
		local voting_id = self._voting_id

		self:_send_rpc_members("rpc_voting_completed", voting_id, result_id)
		_info("Voting %q (%s) completed, result: %s, votes: %s", voting_id, template.name, result, table.tostring(self._votes))
	end
end

function VotingHost:complete_vote()
	local template = self._template
	local result = template.complete_vote(self._votes)
	self._result = result
	self._state = STATES.completed
	local result_id = NetworkLookup.voting_results[result]
	local voting_id = self._voting_id

	self:_send_rpc_members("rpc_voting_completed", voting_id, result_id)
	_info("Voting %q (%s) force completed, result: %s, votes: %s", voting_id, template.name, result, table.tostring(self._votes))
end

function VotingHost:_handle_undecided_votes()
	local timeout_option = self._template.timeout_option
	local force_timeout_option = self._template.force_timeout_option
	local votes = self._votes

	for voter_peer_id, vote in pairs(votes) do
		if vote == StrictNil then
			_info("Casting timeout option %q for undecided member %s", timeout_option, voter_peer_id)
			self:register_vote(voter_peer_id, timeout_option)
		elseif force_timeout_option and vote ~= force_timeout_option then
			_info("Casting force timeout option %q for member %s, previous vote was", force_timeout_option, voter_peer_id, vote)
			self:register_vote(voter_peer_id, timeout_option)
		end
	end
end

function VotingHost:result()
	return self._result
end

function VotingHost:abort_reason()
	return self._abort_reason
end

function VotingHost:_send_rpc_members(rpc_name, ...)
	local rpc = RPC[rpc_name]
	local local_peer_id = Network.peer_id()
	local network_interface = self._network_interface
	local member_list = self._member_list

	for i = 1, #member_list do
		local peer_id = member_list[i]

		if peer_id ~= local_peer_id then
			local channel_id = network_interface:peer_to_channel(peer_id)

			rpc(channel_id, ...)
		end
	end
end

function VotingHost:_send_rpc_members_except(rpc_name, except_peer_id, ...)
	local rpc = RPC[rpc_name]
	local local_peer_id = Network.peer_id()
	local network_interface = self._network_interface
	local member_list = self._member_list

	for i = 1, #member_list do
		local peer_id = member_list[i]

		if peer_id ~= local_peer_id and peer_id ~= except_peer_id then
			local channel_id = network_interface:peer_to_channel(peer_id)

			rpc(channel_id, ...)
		end
	end
end

return VotingHost
