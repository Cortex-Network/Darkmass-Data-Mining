local BackendUtilities = require("scripts/foundation/managers/backend/utilities/backend_utilities")
local Promise = require("scripts/foundation/utilities/promise")
local Wallet = class("Wallet")

function Wallet:get_currency_configuration()
	return Managers.backend:title_request("/store/currencies", {
		method = "GET"
	}):next(function (data)
		return data.body
	end)
end

function Wallet:_decorate_wallets(wallets)
	local wallets = {
		wallets = wallets,
		by_type = function (self, wallet_type)
			for _, v in ipairs(self.wallets) do
				if v.balance.type == wallet_type then
					return v
				end
			end

			return nil
		end
	}

	return wallets
end

function Wallet:combined_wallets(character_id)
	return Promise.all(BackendUtilities.make_account_title_request("characters", BackendUtilities.url_builder():path(character_id):path("/wallets")), BackendUtilities.make_account_title_request("account", BackendUtilities.url_builder():path("wallets"))):next(function (result)
		local character_wallet_data = result[1]
		local account_wallet_data = result[2]
		local character_wallet = character_wallet_data.body.wallets
		local account_wallet = account_wallet_data.body.wallets
		local wallets = {}

		for i = 1, #character_wallet do
			wallets[#wallets + 1] = character_wallet[i]
		end

		for i = 1, #account_wallet do
			wallets[#wallets + 1] = account_wallet[i]
		end

		return self:_decorate_wallets(wallets)
	end)
end

function Wallet:character_wallets(character_id)
	return BackendUtilities.make_account_title_request("characters", BackendUtilities.url_builder():path(character_id):path("/wallets")):next(function (data)
		local wallets = data.body.wallets

		return self:_decorate_wallets(wallets)
	end)
end

function Wallet:account_wallets()
	return BackendUtilities.make_account_title_request("account", BackendUtilities.url_builder():path("wallets")):next(function (data)
		local wallets = data.body.wallets

		return self:_decorate_wallets(wallets)
	end)
end

return Wallet
