local MechanismBase = require("scripts/managers/mechanism/mechanisms/mechanism_base")
local MechanismSettings = require("scripts/settings/mechanism/mechanism_settings")
local StateTitle = require("scripts/game_states/game/state_title")
local Teams = require("scripts/managers/mechanism/teams")

for name, settings in pairs(MechanismSettings) do
	local class_file_name = settings.class_file_name

	require(class_file_name)
end

local MechanismManager = class("MechanismManager")
MechanismManager.LOOKUP = {}
local EVENT_TYPES = table.enum("all", "server", "locally")
MechanismManager.EVENTS = {
	game_mode_end = {
		rpc_name = "rpc_mechanism_event_game_mode_end",
		type = EVENT_TYPES.all,
		pack_function = function (self, result, session_id)
			return NetworkLookup.game_mode_outcomes[result], session_id
		end
	},
	all_players_ready = {
		rpc_name = "rpc_mechanism_event",
		type = EVENT_TYPES.all,
		pack_function = function (self, ...)
			return self.id
		end
	},
	victory_defeat_done = {
		rpc_name = "rpc_mechanism_event",
		type = EVENT_TYPES.all,
		pack_function = function (self, ...)
			return self.id
		end
	},
	game_score_done = {
		rpc_name = "rpc_mechanism_event",
		type = EVENT_TYPES.all,
		pack_function = function (self, ...)
			return self.id
		end
	},
	client_exit_gameplay = {
		type = EVENT_TYPES.locally
	},
	failed_fetching_session_report = {
		rpc_name = "rpc_mechanism_event_failed_fetching_session_report",
		type = EVENT_TYPES.server,
		pack_function = function (self, peer_id)
			return peer_id
		end
	},
	game_score_end_time = {
		rpc_name = "rpc_mechanism_event_game_score_end_time",
		type = EVENT_TYPES.all,
		pack_function = function (self, time)
			return time
		end
	}
}
MechanismManager.EVENT_LOOKUP = {}
MechanismManager.CLIENT_RPCS = {
	"rpc_set_mechanism"
}
MechanismManager.SERVER_RPCS = {}
local i = 1
local lookup = MechanismManager.LOOKUP

for name, mechanism_settings in pairs(MechanismSettings) do
	local mechanism_class = CLASSES[mechanism_settings.class_name]

	assert_interface(mechanism_class, MechanismBase.INTERFACE)

	lookup[name] = i
	lookup[i] = name
	i = i + 1
end

local j = 1
local client_rpcs = {}
local server_rpcs = {}

for event_name, event_config in pairs(MechanismManager.EVENTS) do
	local rpc_name = event_config.rpc_name
	local event_type = event_config.type
	local local_side = event_type == EVENT_TYPES.locally

	if not local_side then
		event_config.id = j
		MechanismManager.EVENT_LOOKUP[j] = event_name
		j = j + 1

		if event_type == EVENT_TYPES.all then
			client_rpcs[rpc_name] = true
		else
			server_rpcs[rpc_name] = true
		end
	end
end

for rpc_name in pairs(client_rpcs) do
	MechanismManager.CLIENT_RPCS[#MechanismManager.CLIENT_RPCS + 1] = rpc_name
end

for rpc_name in pairs(server_rpcs) do
	MechanismManager.SERVER_RPCS[#MechanismManager.SERVER_RPCS + 1] = rpc_name
end

local function _info(...)
	Log.info("MechanismManager", ...)
end

function MechanismManager:init(network_event_delegate, initial_mechanism_name, server_context)
	self._mechanism_name = nil
	self._clients = {}
	self._network_event_delegate = network_event_delegate

	if initial_mechanism_name then
		self:change_mechanism(initial_mechanism_name, server_context)
	else
		_info("Initialized without mechanism")
	end
end

function MechanismManager:leave_mechanism()
	if self._mechanism then
		_info("Leaving mechanism %q", self._mechanism.name)
		self._mechanism:delete()

		self._mechanism = nil
		self._mechanism_name = nil
	end

	if self._teams then
		self._teams:delete()

		self._teams = nil
	end
end

function MechanismManager:mechanism_name()
	return self._mechanism_name
end

function MechanismManager:player_package_synchronization_settings()
	local package_settings = nil

	if self._mechanism then
		local settings = self._mechanism:settings()
		package_settings = settings.player_package_synchronization_settings
	end

	return package_settings
end

function MechanismManager:add_client(channel_id)
	local lookup_id = self.LOOKUP[self._mechanism_name]

	RPC.rpc_set_mechanism(channel_id, lookup_id)
	self._mechanism:sync_data(channel_id)

	self._clients[channel_id] = true

	self._network_event_delegate:register_connection_channel_events(self, channel_id, unpack(MechanismManager.SERVER_RPCS))
end

function MechanismManager:remove_client(channel_id)
	self._clients[channel_id] = nil

	self._network_event_delegate:unregister_channel_events(channel_id, unpack(MechanismManager.SERVER_RPCS))
end

function MechanismManager:clients()
	return self._clients
end

function MechanismManager:is_allowed_to_reserve_slots(peer_ids)
	if not self._mechanism then
		Log.warning("MechanismManager", "No mechanism set yet, can't decide")

		return false
	end

	return self._mechanism:is_allowed_to_reserve_slots(peer_ids)
end

function MechanismManager:peers_reserved_slots(peer_ids)
	self._mechanism:peers_reserved_slots(peer_ids)
end

function MechanismManager:peer_freed_slot(peer_id)
	self._mechanism:peer_freed_slot(peer_id)
end

function MechanismManager:connect_to_host(channel_id)
	_info("Connecting to mechanism host on channel %i", channel_id)

	self._mechanism_host_channel = channel_id

	self._network_event_delegate:register_connection_channel_events(self, channel_id, unpack(MechanismManager.CLIENT_RPCS))
end

function MechanismManager:disconnect(channel_id)
	_info("Disconnecting from mechanism host on channel %i", channel_id)

	self._mechanism_host_channel = nil

	self._network_event_delegate:unregister_channel_events(channel_id, unpack(MechanismManager.CLIENT_RPCS))
	self:leave_mechanism()
end

function MechanismManager:rpc_set_mechanism(channel_id, lookup_id)
	local mechanism_name = self.LOOKUP[lookup_id]

	_info("Received mechanism %q from host.", mechanism_name)
	self:change_mechanism(mechanism_name, {
		server_channel = channel_id
	})
end

function MechanismManager:change_mechanism(mechanism_name, context)
	local old_mechanism = self._mechanism

	if old_mechanism then
		_info("Change mechanism %q->%q", old_mechanism.name, mechanism_name)
		self:leave_mechanism()
	else
		_info("Change mechanism <none>->%q", mechanism_name)
	end

	local settings = MechanismSettings[mechanism_name]
	local lookup_id = self.LOOKUP[mechanism_name]

	for channel_id in pairs(self._clients) do
		RPC.rpc_set_mechanism(channel_id, lookup_id)
	end

	self._mechanism_name = mechanism_name
	local team_settings = settings.team_settings

	if team_settings then
		self._teams = Teams:new(team_settings)
	end

	local mechanism_class = CLASSES[settings.class_name]

	assert_interface(mechanism_class, MechanismBase.INTERFACE)

	self._mechanism = mechanism_class:new(mechanism_name, self._network_event_delegate, context, self._teams)

	for channel_id in pairs(self._clients) do
		self._mechanism:sync_data(channel_id)
	end

	Managers.event:trigger("mechanism_changed")
end

function MechanismManager:wanted_transition()
	if not self._mechanism then
		return nil, 
	end

	local done, next_state, next_state_context = self._mechanism:wanted_transition()

	if done then
		if self._mechanism_host_channel then
			self:leave_mechanism()
		elseif Managers.connection:is_dedicated_mission_server() then
			self:leave_mechanism()
		else
			self:change_mechanism("hub", {})

			done, next_state, next_state_context = self._mechanism:wanted_transition()
		end
	end

	return next_state, next_state_context
end

local function _send_event_rpc(rpc_name, clients, ...)
	local rpc = RPC[rpc_name]

	for channel_id in pairs(clients) do
		rpc(channel_id, ...)
	end
end

function MechanismManager:trigger_event(event, ...)
	local host_channel = self._mechanism_host_channel
	local event_data = self.EVENTS[event]

	if host_channel and event_data.type == EVENT_TYPES.all then
		return
	end

	local mechanism = self._mechanism

	if not mechanism then
		return
	end

	local event_function = mechanism[event]

	if event_data.type == EVENT_TYPES.locally then
		event_function(mechanism, ...)
	elseif event_data.type == EVENT_TYPES.server then
		if host_channel then
			local rpc_name = event_data.rpc_name

			RPC[rpc_name](host_channel, event_data:pack_function(...))
		else
			event_function(mechanism, ...)
		end
	else
		local is_client = host_channel

		if is_client then
			Log.warning("MechanismManager", "trying to trigger host event as client")
		end

		local rpc_name = event_data.rpc_name

		_send_event_rpc(rpc_name, self._clients, event_data:pack_function(...))
		event_function(mechanism, ...)
	end
end

function MechanismManager:rpc_mechanism_event_game_mode_end(channel_id, result_id, session_id)
	local mechanism = self._mechanism
	local reason = NetworkLookup.game_mode_outcomes[result_id]

	mechanism:game_mode_end(reason, session_id)
	_info("session_id %s", session_id)
end

function MechanismManager:rpc_mechanism_event(channel_id, event_id)
	local event_name = self.EVENT_LOOKUP[event_id]
	local mechanism = self._mechanism
	local event_function = mechanism[event_name]

	event_function(mechanism)
end

function MechanismManager:rpc_mechanism_event_failed_fetching_session_report(channel_id, peer_id)
	local mechanism = self._mechanism

	mechanism:failed_fetching_session_report(peer_id)
end

function MechanismManager:rpc_mechanism_event_game_score_end_time(channel_id, end_time)
	local mechanism = self._mechanism

	if mechanism.game_score_end_time then
		mechanism:game_score_end_time(end_time)
	elseif not Managers.progression:is_using_dummy_report() then
		-- Nothing
	end
end

function MechanismManager:end_result()
	local end_result = self._mechanism and self._mechanism._mechanism_data.end_result or false

	return end_result
end

function MechanismManager:mechanism_state()
	local mechanism_state = self._mechanism and self._mechanism._state or false

	return mechanism_state
end

function MechanismManager:singleplay_type()
	local mechanism = self._mechanism

	return mechanism and mechanism.singleplay_type and mechanism:singleplay_type()
end

function MechanismManager:backend_mission_id()
	local backend_mission_id = self._mechanism and self._mechanism._mechanism_data and self._mechanism._mechanism_data.backend_mission_id

	return backend_mission_id
end

return MechanismManager
