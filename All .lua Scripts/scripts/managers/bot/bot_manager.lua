local BotSynchronizerHost = require("scripts/bot/bot_synchronizer_host")
local BotSynchronizerClient = require("scripts/bot/bot_synchronizer_client")
local BotManagerTestify = GameParameters.testify and require("scripts/managers/bot/bot_manager_testify")
local BotManager = class("BotManager")

function BotManager:init()
	self._bot_synchronizer_client = nil
	self._bot_synchronizer_host = nil
end

function BotManager:destroy()
	self:_cleanup()
end

function BotManager:update(dt)
	if self._bot_synchronizer_host then
		self._bot_synchronizer_host:update(dt)
	end

	if GameParameters.testify then
		Testify:poll_requests_through_handler(BotManagerTestify, self)
	end
end

function BotManager:post_update(dt, t)
	if self._bot_synchronizer_host then
		self._bot_synchronizer_host:handle_queued_bot_removals()
	end
end

function BotManager:create_synchronizer_host()
	self:_cleanup()

	local network_delegate = Managers.connection:network_event_delegate()
	self._bot_synchronizer_host = BotSynchronizerHost:new(network_delegate)

	return self._bot_synchronizer_host
end

function BotManager:synchronizer_host()
	return self._bot_synchronizer_host
end

function BotManager:create_synchronizer_client(host_channel_id)
	self:_cleanup()

	local peer_id = Network.peer_id()
	local network_delegate = Managers.connection:network_event_delegate()
	self._bot_synchronizer_client = BotSynchronizerClient:new(peer_id, network_delegate, host_channel_id)

	return self._bot_synchronizer_client
end

function BotManager:synchronizer_client()
	return self._bot_synchronizer_client
end

function BotManager:_cleanup()
	if self._bot_synchronizer_host then
		self._bot_synchronizer_host:delete()

		self._bot_synchronizer_host = nil
	end

	if self._bot_synchronizer_client then
		self._bot_synchronizer_client:delete()

		self._bot_synchronizer_client = nil
	end
end

return BotManager
