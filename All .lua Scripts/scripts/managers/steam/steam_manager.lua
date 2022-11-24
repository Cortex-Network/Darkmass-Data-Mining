local SteamManager = class("SteamManager")

function SteamManager:init()
	self.callbacks = {}
	self.micro_txn_data = {}
end

function SteamManager:update(t, dt)
	if HAS_STEAM then
		Steam.run_callbacks(self)
	end
end

function SteamManager:on_overlay_activated(enabled)
	Log.info("SteamManager", "on_overlay_activated %s", enabled)
end

function SteamManager:on_micro_txn(authorized, order_id)
	Log.info("SteamManager", "on_micro_txn %s %s", authorized, order_id)

	local callback = self.callbacks[order_id]

	if callback then
		callback(authorized, order_id)

		self.callbacks[order_id] = nil
	else
		self.micro_txn_data[order_id] = {
			authorized = authorized
		}
	end
end

function SteamManager:register_micro_txn_callback(order_id, callback)
	if self.micro_txn_data[order_id] then
		callback(self.micro_txn_data[order_id].authorized, order_id)

		self.micro_txn_data[order_id] = nil
	else
		self.callbacks[order_id] = callback
	end
end

return SteamManager
