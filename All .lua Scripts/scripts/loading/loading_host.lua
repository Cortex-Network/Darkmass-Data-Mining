local Loader = require("scripts/loading/loader")
local LoadingHostStateMachine = require("scripts/loading/loading_host_state_machine")
local LoadingRemoteStateMachine = require("scripts/loading/loading_remote_state_machine")
local SpawnQueue = require("scripts/loading/spawn_queue")
local LoadingHost = class("LoadingHost")
LoadingHost.SPAWN_QUEUE_DELAY = 10

function LoadingHost:init(network_delegate, loaders)
	self._network_delegate = network_delegate
	self._loaders = loaders
	self._spawn_queue = SpawnQueue:new(LoadingHost.SPAWN_QUEUE_DELAY)
	self._mission = nil
	self._spawn_group = nil
	self._spawn_peers = nil
	self._state = "initial_spawn"

	function self._done_loading_level_func(spawn_group, peer_id)
		self._spawn_queue:loaded_level(spawn_group, peer_id)
	end

	self._level_state = "unloaded"
	self._level = nil
	self._clients = {}
	self._host = nil
	self._package_synchronizer_host = Managers.package_synchronization:synchronizer_host()
end

function LoadingHost:destroy()
	for _, client in pairs(self._clients) do
		client:destroy()
	end

	self._clients = nil

	if self._host then
		self._host:delete()

		self._host = nil
	end

	for _, loader in ipairs(self._loaders) do
		loader:cleanup()
		loader:delete()
	end

	table.clear(self._loaders)
	self._spawn_queue:delete()
end

function LoadingHost:update(dt)
	self._spawn_queue:update(dt)

	for _, client in pairs(self._clients) do
		client:update(dt)
	end

	if self._host then
		self._host:update(dt)
	end

	if not Managers.package_synchronization:is_ready() then
		return
	end

	local spawn_group = self._spawn_queue:ready_group()

	if spawn_group then
		local peers = self._spawn_queue:trigger_group(spawn_group)
		self._spawn_group = spawn_group
		self._spawn_peers = peers
		self._profile_loading_enabled = false
	end

	if self._spawn_group then
		local levels_loaded = self._spawn_queue:all_levels_loaded(self._spawn_group)
		local profile_loading_enabled = self._profile_loading_enabled

		if levels_loaded and not profile_loading_enabled then
			Log.info("LoadingHost", "[update] LoadingTimes: Spawn Group Finished Loading Level Breed and Hud Packages, Started Loading Player Profile Packages")
			self._package_synchronizer_host:enable_peers(self._spawn_peers)

			self._profile_loading_enabled = true
		end

		local profile_sync_host = Managers.profile_synchronization:synchronizer_host()
		local package_sync_host = self._package_synchronizer_host
		local profiles_loaded = profile_loading_enabled and profile_sync_host:profiles_synced(self._spawn_peers)
		local packages_loaded = profile_loading_enabled and package_sync_host:peers_synced(self._spawn_peers)
		local all_loaded = levels_loaded and profiles_loaded and packages_loaded

		if all_loaded then
			if self._state == "initial_spawn" then
				self._state = "wait_for_end_load"

				Log.info("LoadingHost", "[update] LoadingTimes: Spawn Group Finished Loading Required Player Profile Packages for Initial Spawn")
			elseif self._state == "hot_join" then
				self:_trigger_spawn_group()
				Log.info("LoadingHost", "[update] LoadingTimes: Spawn Group Finished Loading Required Player Profile Packages for Hot Join")
			end
		end
	end
end

function LoadingHost:add(client_channel_id)
	local client = LoadingRemoteStateMachine:new(self._network_delegate, client_channel_id, self._spawn_queue, self._done_loading_level_func)
	self._clients[client_channel_id] = client
end

function LoadingHost:remove(client_channel_id)
	local client = self._clients[client_channel_id]
	local client_peer_id = client:peer_id()

	client:delete()

	self._clients[client_channel_id] = nil

	self._spawn_queue:remove_from_queue(client_peer_id)

	if self._spawn_peers then
		local spawn_peer_index = table.find(self._spawn_peers, client_peer_id)

		if spawn_peer_index then
			table.remove(self._spawn_peers, spawn_peer_index)
		end

		if table.size(self._spawn_peers) == 1 then
			local _, remaining_peer_id = next(self._spawn_peers)

			if DEDICATED_SERVER and remaining_peer_id == Network.peer_id() then
				self._spawn_queue:retire_group(self._spawn_group)

				self._spawn_group = nil
				self._spawn_peers = nil
			end
		end
	end
end

function LoadingHost:failed(failed_peers)
	for channel_id, client in pairs(self._clients) do
		if client:state() == "failed" then
			failed_peers[#failed_peers + 1] = Network.peer_id(channel_id)
		end
	end
end

function LoadingHost:take_ownership_of_level()
	if self._host then
		return self._host:take_ownership_of_level()
	end
end

function LoadingHost:mission()
	return self._mission
end

function LoadingHost:load_mission(mission, level_editor_level, circumstance_name)
	self:stop_load_mission()

	self._mission = mission
	self._host = LoadingHostStateMachine:new(mission, level_editor_level, circumstance_name, self._spawn_queue, self._loaders, self._done_loading_level_func)

	self._package_synchronizer_host:set_mission_name(mission)
end

function LoadingHost:stop_load_mission()
	self._spawn_queue:reset()

	self._mission = nil
	local old_channels = {}

	for channel_id, client in pairs(self._clients) do
		old_channels[#old_channels + 1] = channel_id

		client:destroy()
	end

	table.clear(self._clients)

	if self._host then
		self._host:delete()

		self._host = nil
	end

	for _, channel_id in ipairs(old_channels) do
		local client = LoadingRemoteStateMachine:new(self._network_delegate, channel_id, self._spawn_queue, self._done_loading_level_func)
		self._clients[channel_id] = client
	end

	self._state = "initial_spawn"
end

function LoadingHost:first_group_ready()
	return self._state == "wait_for_end_load"
end

function LoadingHost:end_load()
	self:_trigger_spawn_group()
end

function LoadingHost:_trigger_spawn_group()
	for _, client in pairs(self._clients) do
		client:spawn_group_ready(self._spawn_group)
	end

	self._spawn_queue:retire_group(self._spawn_group)

	self._spawn_group = nil
	self._spawn_peers = nil
	self._state = "hot_join"
end

return LoadingHost
