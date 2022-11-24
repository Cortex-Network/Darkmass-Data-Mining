local Promise = require("scripts/foundation/utilities/promise")
local PartyImmateriumConnection = class("PartyImmateriumConnection")

local function _info(...)
	Log.info("PartyImmateriumManager", ...)
end

local empty_object = {}

function PartyImmateriumConnection:init(join_parameter, compatibility_string, resolve_optional_ticket_promise_func)
	self._requested_join_parameter = join_parameter
	self._compatibility_string = compatibility_string
	self._resolve_optional_ticket_promise_func = resolve_optional_ticket_promise_func
	self._started = false
	self._aborted = false
	self._party_operation = nil
	self._optional_matchmaking_ticket = nil
	self._join_promises = {}
	self._error = nil
	self._event_buffer = {}
	self._party = empty_object
	self._party_version = 0
	self._party_vote = empty_object
	self._party_vote_version = 0
	self._game_state = empty_object
	self._game_state_version = 0
	self._invite_list = nil
	self._invite_list_version = 0
end

function PartyImmateriumConnection:destroy()
end

function PartyImmateriumConnection:_internal_start(optional_matchmaking_ticket)
	if self._aborted then
		return
	end

	local party_id = nil
	local context_account_id = ""
	local invite_token = ""

	if self._party.party_id then
		party_id = self._party.party_id
		context_account_id = ""
		invite_token = ""
	else
		party_id = self._requested_join_parameter.party_id
		context_account_id = self._requested_join_parameter.context_account_id or ""
		invite_token = self._requested_join_parameter.invite_token or ""
	end

	local promise, operation_id = Managers.grpc:join_party(party_id, context_account_id, invite_token, self._compatibility_string, optional_matchmaking_ticket)
	self._party_operation = operation_id

	promise:next(function ()
		self._party_operation = nil

		if self._aborted then
			return
		end

		return Managers.grpc:delay_with_jitter_and_backoff("party_stream"):next(function ()
			return self:_internal_start()
		end)
	end):catch(function (error)
		self._party_operation = nil

		if self._aborted then
			return
		end

		if Managers.grpc:should_retry(error) then
			return Managers.grpc:delay_with_jitter_and_backoff("party_stream"):next(function ()
				return self:_internal_start()
			end)
		else
			local session_id = self:_requires_mission_hot_join_ticket_error(error)

			if session_id then
				return self._resolve_optional_ticket_promise_func(session_id):next(function (ticket)
					return self:_internal_start(ticket)
				end):catch(function (error)
					self:_on_error(error)
				end)
			else
				self:_on_error(error)
			end
		end
	end)
end

function PartyImmateriumConnection:abort()
	if not self._aborted then
		if self._party_operation then
			Managers.grpc:abort_operation(self._party_operation)
		end

		self:_on_error({
			aborted = true,
			error_details = "ABORTED"
		})
	end
end

function PartyImmateriumConnection:_on_error(error)
	self._aborted = true
	self._error = error

	if self._join_promises then
		for _, join_promise in ipairs(self._join_promises) do
			join_promise:reject(error)
		end

		self._join_promises = nil
	end
end

function PartyImmateriumConnection:party()
	return self._party
end

function PartyImmateriumConnection:party_vote()
	return self._party_vote
end

function PartyImmateriumConnection:party_game_state()
	return self._game_state
end

function PartyImmateriumConnection:party_invite_list()
	return self._invite_list
end

function PartyImmateriumConnection:event_buffer()
	return self._event_buffer
end

function PartyImmateriumConnection:error()
	return self._error
end

function PartyImmateriumConnection:reset_event_buffer()
	table.clear(self._event_buffer)
end

function PartyImmateriumConnection:join_promise()
	if not self._join_promises then
		return Promise.resolved(self)
	end

	local promise = Promise:new()

	table.insert(self._join_promises, promise)

	return promise
end

function PartyImmateriumConnection:start()
	if self._aborted then
		return Promise.rejected(self._error)
	end

	self._started = true

	self:_internal_start()
end

function PartyImmateriumConnection:update(dt)
	if self._party_operation then
		local party_events = Managers.grpc:get_party_events(self._party_operation)

		if party_events then
			for i, event in ipairs(party_events) do
				self:_handle_party_event(event)
			end
		end
	end
end

function PartyImmateriumConnection:_requires_mission_hot_join_ticket_error(error)
	local prefix = "REQUIRES_MISSION_HOT_JOIN_TICKET:"

	if type(error) == "table" and error.error_details and string.starts_with(error.error_details, prefix) then
		return string.sub(error.error_details, #prefix + 1, #error.error_details)
	end

	return nil
end

function PartyImmateriumConnection:_handle_party_event(event)
	Managers.grpc:reset_retry_count("party_stream")

	if event.event_type == "party_update" then
		self:_handle_party_update_event(event)
	elseif event.event_type == "party_vote_update" then
		self:_handle_party_vote_update_event(event)
	elseif event.event_type == "party_game_state_update" then
		self:_handle_party_game_state_update_event(event)
	elseif event.event_type == "party_invite_list_update" then
		self:_handle_party_invite_list_update_event(event)
	else
		table.insert(self._event_buffer, event)
	end
end

function PartyImmateriumConnection:_handle_party_update_event(event)
	if event.version < self._party_version then
		return
	end

	self._party = event
	self._party_version = event.version

	if self._join_promises then
		for _, join_promise in ipairs(self._join_promises) do
			join_promise:resolve(self)
		end

		self._join_promises = nil
	end

	table.insert(self._event_buffer, event)
end

function PartyImmateriumConnection:_handle_party_vote_update_event(event)
	if event.version < self._party_vote_version then
		return
	end

	self._party_vote = event
	self._party_vote_version = event.version

	table.insert(self._event_buffer, event)
end

function PartyImmateriumConnection:_handle_party_game_state_update_event(event)
	if event.version < self._game_state_version then
		return
	end

	self._game_state = event
	self._game_state_version = event.version

	table.insert(self._event_buffer, event)
end

function PartyImmateriumConnection:_handle_party_invite_list_update_event(event)
	if event.version < self._invite_list_version then
		return
	end

	self._invite_list = event
	self._invite_list_version = event.version

	table.insert(self._event_buffer, event)
end

return PartyImmateriumConnection
