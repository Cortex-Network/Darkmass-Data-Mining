local SessionStats = require("scripts/managers/stats/groups/session_stats")
local CriteriaParser = require("scripts/managers/contracts/utility/criteria_parser")
local LocalContractTasks = require("scripts/settings/contracts/local_contract_tasks")
local ContractsManager = class("ContractsManager")
local CLIENT_RPCS = {
	"rpc_notify_contract_task_complete"
}

function ContractsManager:init(is_server, event_delegate)
	self._is_server = is_server
	self._network_event_delegate = event_delegate

	if is_server then
		self:_start_tracking()
	else
		self._is_client = true

		self._network_event_delegate:register_connection_events(self, unpack(CLIENT_RPCS))
	end
end

function ContractsManager:destroy()
	if self._is_client then
		self._network_event_delegate:unregister_events(unpack(CLIENT_RPCS))
	end
end

function ContractsManager:_start_tracking()
	self._is_tracker = true
	self._tracking = {}
	self._stat_id = {}
end

function ContractsManager:_stop_tracking()
	self:untrack_all()

	self._is_tracker = false
	self._tracking = nil
	self._stat_id = nil
end

function ContractsManager:client_start_tracking()
	self:_start_tracking()
	Log.info("ContractsManager", "client started tracking contracts")
end

function ContractsManager:client_stop_tracking()
	self:_stop_tracking()
	Log.info("ContractsManager", "client stopped tracking contracts")
end

function ContractsManager:_add_player(player)
	local character_id = player:character_id()
	local player_data = {
		character_id = character_id,
		account_id = player:account_id(),
		connection_channel = player:connection_channel_id(),
		contracts_loaded = false,
		stat_id = Managers.stats:add_tracker(self, player, SessionStats, ContractsManager._on_stat_change),
		triggers = {},
		remote_player = player.remote
	}
	self._stat_id[player_data.stat_id] = character_id
	self._tracking[character_id] = player_data
end

function ContractsManager:_parse_backend_criteria(backend_task)
	local criteria = CriteriaParser.parse_backend_criteria(backend_task.criteria)

	if LocalContractTasks[criteria.task_type] then
		return true, criteria
	end

	return false
end

function ContractsManager:_parse_backend_contract(data)
	local tasks = data.tasks
	local tasks_left = {}

	for i = 1, #tasks do
		local backend_task = tasks[i]
		local fulfilled = backend_task.fulfilled

		if not fulfilled then
			local should_track, criteria = self:_parse_backend_criteria(backend_task)

			if should_track then
				tasks_left[#tasks_left + 1] = {
					uuid = backend_task.id,
					criteria = criteria
				}
			end
		end
	end

	return tasks_left
end

function ContractsManager:_pull_contracts(character_id)
	local player_data = self._tracking[character_id]
	local account_id = player_data.account_id

	return Managers.backend.interfaces.contracts:get_current_contract(character_id, account_id, false):next(function (data)
		player_data.contracts_loaded = true
		local tasks_left = self:_parse_backend_contract(data)

		for i = 1, #tasks_left do
			local task = tasks_left[i]
			local stat_id = LocalContractTasks[task.criteria.task_type].stat_id
			local triggered_by = player_data.triggers[stat_id] or {}
			triggered_by[#triggered_by + 1] = task
			player_data.triggers[stat_id] = triggered_by
		end
	end):catch(function ()
		Log.warning("ContractsManager", "Failed to download contracts for '%s'. Untracking contrackts for player.", character_id)
		self:untrack_player(character_id)
	end)
end

function ContractsManager:track_player(player)
	local character_id = player:character_id()

	if not math.is_uuid(character_id) then
		Log.warning("ContractsManager", "Can't track '%s'. Invalid character id.", character_id)

		return false
	end

	if self._tracking[character_id] then
		Log.warning("ContractsManager", "Can't track '%s'. Already tracking them.", character_id)

		return false
	end

	self:_add_player(player)

	return true, self:_pull_contracts(character_id)
end

function ContractsManager:untrack_player(character_id)
	local player_data = self._tracking[character_id]

	if not player_data then
		Log.warning("ContractsManager", "Can't untrack player '%s'. Player isn't tracked.")

		return false
	end

	self._stat_id[player_data.stat_id] = nil
	self._tracking[character_id] = nil

	Managers.stats:remove_tracker(player_data.stat_id)

	return true
end

function ContractsManager:untrack_all()
	for character_id, _ in pairs(self._tracking) do
		self:untrack_player(character_id)
	end
end

function ContractsManager:_complete_task(character_id, task)
	local player_data = self._tracking[character_id]
	local remote_player = player_data.remote_player
	local rpc_channel = player_data.connection_channel

	if remote_player then
		RPC.rpc_notify_contract_task_complete(rpc_channel, task.uuid)
	else
		self:notify_contract_task_complete(task.uuid)
	end
end

function ContractsManager:_on_stat_change(id, trigger_id, trigger_value, ...)
	local character_id = self._stat_id[id]

	if not character_id then
		Log.warning("ContractsManager", "Recieved stat change for non-tracked player.")

		return
	end

	local player_data = self._tracking[character_id]
	local tasks = player_data.triggers[trigger_id]

	if not tasks then
		return
	end

	for i = 1, #tasks do
		local task = tasks[i]
		local criteria = task.criteria
		local checker = LocalContractTasks[criteria.task_type].checker

		if checker(criteria.specifiers, ...) and trigger_value >= criteria.target - criteria.at then
			self:_complete_task(character_id, task)

			tasks[i] = false
		end
	end

	local i = 1
	local size = #tasks

	while i <= size do
		if not tasks[i] then
			tasks[i] = tasks[size]
			tasks[size] = nil
			size = size - 1
		else
			i = i + 1
		end
	end

	if #tasks == 0 then
		player_data.triggers[trigger_id] = nil
	end
end

local function _get_character_id()
	local player_id = 1
	local player = Managers.player:local_player(player_id)
	local player_profile = player:profile()

	return player_profile.character_id
end

function ContractsManager:rpc_notify_contract_task_complete(channel_id, task_id)
	self:notify_contract_task_complete(task_id)
end

function ContractsManager:notify_contract_task_complete(task_id)
	Managers.backend.interfaces.contracts:get_current_task(_get_character_id(), task_id):next(function (data)
		Managers.event:trigger("event_add_notification_message", "contract", data)
	end)
end

return ContractsManager
