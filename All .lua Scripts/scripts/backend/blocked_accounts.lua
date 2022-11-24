local Promise = require("scripts/foundation/utilities/promise")
local BackendError = require("scripts/foundation/managers/backend/backend_error")
local BlockedAccounts = class("BlockedAccounts")

function BlockedAccounts:init()
	self._temp_block_list = {}
end

function BlockedAccounts:add(account_id)
	return Promise.delay(2):next(function ()
		self._temp_block_list[account_id] = true
	end)
end

function BlockedAccounts:remove(account_id)
	return Promise.delay(2):next(function ()
		self._temp_block_list[account_id] = nil
	end)
end

function BlockedAccounts:fetch()
	return Promise.delay(2):next(function ()
		return table.clone(self._temp_block_list)
	end)
end

return BlockedAccounts
