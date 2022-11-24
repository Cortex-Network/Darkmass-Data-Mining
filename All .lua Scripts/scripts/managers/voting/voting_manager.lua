local Promise = require("scripts/foundation/utilities/promise")
local VotingTemplates = require("scripts/settings/voting/voting_templates")
local VotingByNetworkImpl = require("scripts/managers/voting/voting_by_network_impl")
local VotingByImmateriumPartyImpl = require("scripts/managers/voting/voting_by_immaterium_party_impl")
local VotingManager = class("VotingManager")

function VotingManager:init(network_event_delegate)
	self._network_voting_impl = VotingByNetworkImpl:new(network_event_delegate)
	self._immaterium_party_voting_impl = VotingByImmateriumPartyImpl:new()
end

function VotingManager:_get_impl_by_template(template)
	if template.voting_impl == "network" then
		return self._network_voting_impl
	elseif template.voting_impl == "party_immaterium" then
		return self._immaterium_party_voting_impl
	elseif template.voting_impl then
		-- Nothing
	end
end

function VotingManager:_get_impl_by_vote_id(vote_id)
	if string.find(vote_id, "immaterium_party:") == 1 then
		return self._immaterium_party_voting_impl
	else
		return self._network_voting_impl
	end
end

function VotingManager:can_start_voting(template_name, params)
	local template = VotingTemplates[template_name]

	if not template then
		return false, string.format("voting template %s not found", template_name)
	end

	local required_params = template.required_params

	if required_params then
		for i = 1, #required_params do
			local param_name = required_params[i]

			if params[param_name] == nil then
				return false, string.format("required voting param %s not found", param_name)
			end
		end
	end

	local result, message = self:_get_impl_by_template(template):can_start_voting(template_name, params)

	if not result then
		return false, message
	end

	if template.can_start then
		return template.can_start()
	end

	return true
end

function VotingManager:start_voting(template_name, params)
	local success, fail_reason = self:can_start_voting(template_name, params)

	if not success then
		return Promise.rejected({
			fail_reason
		})
	end

	local template = VotingTemplates[template_name]

	return self:_get_impl_by_template(template):start_voting(template_name, params)
end

function VotingManager:can_cast_vote(voting_id, option, voter_peer_id)
	return self:_get_impl_by_vote_id(voting_id):can_cast_vote(voting_id, option, voter_peer_id)
end

function VotingManager:cast_vote(voting_id, option)
	return self:_get_impl_by_vote_id(voting_id):cast_vote(voting_id, option)
end

function VotingManager:update(dt, t)
	self._network_voting_impl:update(dt, t)
	self._immaterium_party_voting_impl:update(dt, t)
end

function VotingManager:complete_vote(voting_id)
	self:_get_impl_by_vote_id(voting_id):complete_vote(voting_id)
end

function VotingManager:member_list(voting_id)
	return self:_get_impl_by_vote_id(voting_id):member_list(voting_id)
end

function VotingManager:votes(voting_id)
	return self:_get_impl_by_vote_id(voting_id):votes(voting_id)
end

function VotingManager:time_left(voting_id)
	return self:_get_impl_by_vote_id(voting_id):time_left(voting_id)
end

function VotingManager:voting_template(voting_id)
	return self:_get_impl_by_vote_id(voting_id):voting_template(voting_id)
end

function VotingManager:voting_exists(voting_id)
	return self:_get_impl_by_vote_id(voting_id):voting_exists(voting_id)
end

function VotingManager:voting_result(voting_id)
	return self:_get_impl_by_vote_id(voting_id):voting_result(voting_id)
end

function VotingManager:has_voted(voting_id, voter_peer_id)
	return self:_get_impl_by_vote_id(voting_id):has_voted(voting_id, voter_peer_id)
end

function VotingManager:is_host(voting_id)
	return self:_get_impl_by_vote_id(voting_id):is_host(voting_id)
end

return VotingManager
