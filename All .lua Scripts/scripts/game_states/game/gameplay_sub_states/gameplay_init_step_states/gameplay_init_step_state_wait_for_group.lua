local GameplayInitStepInterface = require("scripts/game_states/game/gameplay_sub_states/gameplay_init_step_states/gameplay_init_step_state_interface")
local GameplayInitStepStateLast = require("scripts/game_states/game/gameplay_sub_states/gameplay_init_step_states/gameplay_init_step_state_last")
local GameplayInitStepStateWaitForGroup = class("GameplayInitStepStateWaitForGroup")
local CLIENT_RPCS = {
	"rpc_group_loaded"
}

function GameplayInitStepStateWaitForGroup:on_enter(parent, params)
	local shared_state = params.shared_state
	self._shared_state = shared_state
	self._ready_to_spawn = true
	local is_server = shared_state.is_server
	self._is_server = is_server

	if not is_server then
		local connection_manager = Managers.connection
		local spawn_group_id = shared_state.spawn_group_id
		local host_channel_id = connection_manager:host_channel()

		if host_channel_id then
			RPC.rpc_finished_loading_level(host_channel_id, spawn_group_id)

			local network_event_delegate = connection_manager:network_event_delegate()

			network_event_delegate:register_session_events(self, unpack(CLIENT_RPCS))

			self._network_events_registered = true
		end

		self._ready_to_spawn = false
	end

	Managers.event:trigger("event_loading_resources_finished")
end

function GameplayInitStepStateWaitForGroup:on_exit()
	local connection_manager = Managers.connection
	local network_event_delegate = connection_manager:network_event_delegate()

	if self._network_events_registered then
		network_event_delegate:unregister_events(unpack(CLIENT_RPCS))
	end
end

function GameplayInitStepStateWaitForGroup:update(main_dt, main_t)
	if not self._shared_state.is_server then
		local lost_connection = not Managers.connection:host_channel()

		if lost_connection then
			local next_step_params = {
				shared_state = self._shared_state
			}

			return GameplayInitStepStateLast, next_step_params
		end
	end

	if self._ready_to_spawn then
		local next_step_params = {
			shared_state = self._shared_state
		}

		return GameplayInitStepStateLast, next_step_params
	end

	return nil, 
end

function GameplayInitStepStateWaitForGroup:rpc_group_loaded(channel_id, spawn_group)
	local expected_spawn_group = self._shared_state.spawn_group_id

	if spawn_group == expected_spawn_group then
		self._ready_to_spawn = true
	end
end

implements(GameplayInitStepStateWaitForGroup, GameplayInitStepInterface)

return GameplayInitStepStateWaitForGroup
