local Missions = require("scripts/settings/mission/mission_templates")
local LoadingManager = class("LoadingManager")

function LoadingManager:init()
	self._loading_client = nil
	self._loading_host = nil
	self._shelved_loading_clients = {}
end

function LoadingManager:destroy()
	self:cleanup()
	self:_cleanup_shelved_loading_clients()
end

function LoadingManager:_cleanup_shelved_loading_clients()
	local loading_clients = self._shelved_loading_clients

	for i = 1, #loading_clients do
		local loading_client = loading_clients[i]

		loading_client:delete()
		Log.info("LoadingManager", "Deleting shelved loading client")
	end

	table.clear(loading_clients)
end

function LoadingManager:update(dt)
	if self._loading_client then
		self._loading_client:update(dt)
	end

	if self._loading_host then
		self._loading_host:update(dt)
	end
end

function LoadingManager:cleanup()
	if self._loading_client then
		self:_shelve_loading_client()

		self._loading_client = nil
	end

	if self._loading_host then
		self._loading_host:delete()

		self._loading_host = nil
	end
end

function LoadingManager:_shelve_loading_client()
	local loading_client = self._loading_client
	local loading_clients = self._shelved_loading_clients
	loading_clients[#loading_clients + 1] = loading_client
end

function LoadingManager:is_alive()
	return self._loading_client ~= nil or self._loading_host ~= nil
end

function LoadingManager:is_client()
	return self._loading_client ~= nil
end

function LoadingManager:is_host()
	return self._loading_host ~= nil
end

function LoadingManager:set_client(loading_client)
	self:cleanup()

	self._loading_client = loading_client
end

function LoadingManager:set_host(loading_host)
	self:cleanup()

	self._loading_host = loading_host
end

function LoadingManager:failed()
	return self._loading_client:state() == "failed"
end

function LoadingManager:add_client(channel_id)
	self._loading_host:add(channel_id)
end

function LoadingManager:remove_client(channel_id)
	self._loading_host:remove(channel_id)
end

function LoadingManager:failed_clients(failed_clients)
	self._loading_host:failed(failed_clients)
end

function LoadingManager:load_mission(mission_name, level_name, circumstance_name)
	if mission_name then
		level_name = level_name or Missions[mission_name].level
	end

	if self._loading_host then
		self:_cleanup_shelved_loading_clients()
		self._loading_host:load_mission(mission_name, level_name, circumstance_name)
	end

	if self._loading_client then
		self:_cleanup_shelved_loading_clients()
		self._loading_client:load_mission(mission_name, level_name, circumstance_name)
	end
end

function LoadingManager:stop_load_mission()
	if self._loading_host then
		self._loading_host:stop_load_mission()
	end

	if self._loading_client then
		self._loading_client:stop_load_mission()
	end
end

function LoadingManager:no_level_needed()
	if self._loading_client then
		self._loading_client:no_level_needed()
	end
end

function LoadingManager:load_finished()
	if self._loading_host then
		return self._loading_host:first_group_ready()
	elseif self._loading_client then
		return self._loading_client:load_finished()
	end
end

function LoadingManager:end_load()
	self._loading_host:end_load()
end

function LoadingManager:take_ownership_of_level()
	if self._loading_host then
		return self._loading_host:take_ownership_of_level()
	end

	if self._loading_client then
		return self._loading_client:take_ownership_of_level()
	end
end

function LoadingManager:mission()
	if self._loading_host then
		return self._loading_host:mission()
	end

	if self._loading_client then
		return self._loading_client:mission()
	end
end

function LoadingManager:spawn_group_id()
	if self._loading_client then
		return self._loading_client:spawn_group()
	end

	return nil
end

local function instant_easing_function()
	return 1
end

function LoadingManager:show_instant_black_screen()
	local local_player = Managers.player:local_player(1)

	Managers.event:trigger("event_cutscene_fade_in", local_player, 0.1, instant_easing_function)

	self.black_screen = true
end

function LoadingManager:hide_instant_black_screen()
	local local_player = Managers.player:local_player(1)

	Managers.event:trigger("event_cutscene_fade_out", local_player, 0.1, instant_easing_function)

	self.black_screen = false
end

return LoadingManager
