local BackendUtilities = require("scripts/foundation/managers/backend/utilities/backend_utilities")
local Promise = require("scripts/foundation/utilities/promise")
local StoreFront = class("StoreFront")

function StoreFront:personal_offers()
	return self.data.personal
end

function StoreFront:public_offers()
	return self.data.public_filtered
end

function StoreFront:_find_matching_entitlement_and_currency(offer_list, offer)
	for i, v in ipairs(offer_list) do
		if v.entitlement.id == offer.entitlement.id and v.price.amount.type == offer.price.amount.type then
			return i, v
		end
	end

	return nil, 
end

function StoreFront:update_valid_offers(now)
	self.data.public_filtered = {}

	for _, v in ipairs(self.data.public) do
		if v:is_valid_at(now) then
			local index, matching = self:_find_matching_entitlement_and_currency(self.data.public_filtered, v)

			if not matching then
				table.insert(self.data.public_filtered, v)
			elseif matching.price.priority < v.price.priority then
				self.data.public_filtered[index] = v
			end
		end

		self:_decorate_offer(v, false)
	end
end

function StoreFront:init(data, account_id, character_id, wallet_owner)
	self.data = data
	self.account_id = account_id
	self.character_id = character_id
	self.wallet_owner = wallet_owner

	for _, v in ipairs(data.personal) do
		self:_decorate_offer(v, true)
	end

	for _, v in ipairs(data.public) do
		self:_decorate_offer(v, false)
	end
end

function StoreFront:_decorate_offer(offer, is_personal)
	local store_front = self
	offer.description.gear_id = offer.description.gearId

	function offer:is_personal()
		return is_personal
	end

	function offer:seconds_remaining(now)
		return self.price.validTo and (tonumber(self.price.validTo) - now) / 1000 or 0
	end

	function offer:is_valid_at(now)
		return (self.price.validFrom == nil or tonumber(self.price.validFrom) < now) and (self.price.validTo == nil or now < tonumber(self.price.validTo))
	end

	function offer:reject()
		local builder = BackendUtilities.url_builder():path("/store/storefront/"):path(store_front.data.name):path("/offers/"):path(self.offerId):query("accountId", store_front.account_id):query("characterId", store_front.character_id)

		return Managers.backend:title_request(builder:to_string(), {
			method = "DELETE"
		})
	end

	function offer:make_purchase(wallet)
		local offer_id, price_id = nil

		if is_personal then
			offer_id = offer.offerId
		else
			price_id = offer.price.id
		end

		local purchase_request = {
			storeName = store_front.data.name,
			catalogId = store_front.data.catalog.id,
			priceId = price_id,
			offerId = offer_id,
			characterId = store_front.character_id,
			latestTransactionId = wallet.lastTransactionId
		}
		local builder = BackendUtilities.url_builder():path("/store/"):path(store_front.account_id):path("/wallets/"):path(store_front.wallet_owner):path("/purchases")

		return Managers.backend:title_request(builder:to_string(), {
			method = "POST",
			body = purchase_request
		}):next(function (purchase_result)
			wallet.balance.amount = wallet.balance.amount - purchase_result.body.amount.amount
			wallet.lastTransactionId = (wallet.lastTransactionId or 0) + 1
			local result = purchase_result.body
			local items = result.items

			for i = 1, #items do
				items[i].gear_id = items[i].gearId
				items[i].gearId = nil
			end

			return result
		end)
	end
end

function StoreFront:get_config()
	return Managers.backend:title_request(self.data._links.config.href):next(function (data)
		local config = data.body

		if data.body._links.layout then
			return Managers.backend:title_request(data.body._links.layout.href):next(function (data)
				config.layout = data.body
				config._links = nil
				config.layout._links = nil

				return config
			end)
		else
			return config
		end
	end)
end

function StoreFront:get_seconds_to_rotation_end(t)
	return (self.data.currentRotationEnd - Managers.backend:get_server_time(t)) / 1000
end

function StoreFront:get_refund_cost(config, rerolls_this_week)
	local reroll_config = config.temporaryGoodsConfig.rerolls

	if reroll_config.rollLimit <= rerolls_this_week then
		return nil
	end

	local cost = {
		amount = reroll_config.cost.amount + reroll_config.costScalingFactor * rerolls_this_week * reroll_config.cost.amount,
		type = reroll_config.cost.type
	}

	return cost
end

local Store = class("Store")

function Store:get_veteran_credits_store(t, character_id)
	return self:_get_storefront(t, "credits_store_veteran", character_id, character_id, true)
end

function Store:get_zealot_credits_store(t, character_id)
	return self:_get_storefront(t, "credits_store_zealot", character_id, character_id, true)
end

function Store:get_psyker_credits_store(t, character_id)
	return self:_get_storefront(t, "credits_store_psyker", character_id, character_id, true)
end

function Store:get_ogryn_credits_store(t, character_id)
	return self:_get_storefront(t, "credits_store_ogryn", character_id, character_id, true)
end

function Store:get_veteran_credits_cosmetics_store(t, character_id)
	return self:_get_storefront(t, "credits_cosmetics_store_veteran", character_id, character_id, true)
end

function Store:get_zealot_credits_cosmetics_store(t, character_id)
	return self:_get_storefront(t, "credits_cosmetics_store_zealot", character_id, character_id, true)
end

function Store:get_psyker_credits_cosmetics_store(t, character_id)
	return self:_get_storefront(t, "credits_cosmetics_store_psyker", character_id, character_id, true)
end

function Store:get_ogryn_credits_cosmetics_store(t, character_id)
	return self:_get_storefront(t, "credits_cosmetics_store_ogryn", character_id, character_id, true)
end

function Store:get_veteran_credits_weapon_cosmetics_store(t, character_id)
	return self:_get_storefront(t, "credits_weapon_cosmetics_store_veteran", character_id, character_id, false)
end

function Store:get_zealot_credits_weapon_cosmetics_store(t, character_id)
	return self:_get_storefront(t, "credits_weapon_cosmetics_store_zealot", character_id, character_id, false)
end

function Store:get_psyker_credits_weapon_cosmetics_store(t, character_id)
	return self:_get_storefront(t, "credits_weapon_cosmetics_store_psyker", character_id, character_id, false)
end

function Store:get_ogryn_credits_weapon_cosmetics_store(t, character_id)
	return self:_get_storefront(t, "credits_weapon_cosmetics_store_ogryn", character_id, character_id, false)
end

function Store:get_veteran_marks_store(t, character_id)
	return self:_get_storefront(t, "marks_store_veteran", character_id, character_id, true)
end

function Store:get_zealot_marks_store(t, character_id)
	return self:_get_storefront(t, "marks_store_zealot", character_id, character_id, true)
end

function Store:get_psyker_marks_store(t, character_id)
	return self:_get_storefront(t, "marks_store_psyker", character_id, character_id, true)
end

function Store:get_ogryn_marks_store(t, character_id)
	return self:_get_storefront(t, "marks_store_ogryn", character_id, character_id, true)
end

function Store:get_debug_store(t, character_id)
	return self:_get_storefront(t, "debug_store", character_id, character_id)
end

function Store:_get_storefront(t, store_name, wallet_owner, character_id, include_personal_offers)
	return Managers.backend:authenticate():next(function (account)
		local builder = BackendUtilities.url_builder():path("/store/storefront/"):path(store_name):query("accountId", account.sub)

		if character_id then
			builder:query("characterId", character_id)

			if include_personal_offers then
				builder:query("personal", include_personal_offers)
			end
		end

		return Managers.backend:title_request(builder:to_string()):next(function (data)
			data.accountId = account.sub
			local storefront = StoreFront:new(data.body, data.accountId, character_id, wallet_owner or data.accountId)

			storefront:update_valid_offers(Managers.backend:get_server_time(t))

			return storefront
		end)
	end)
end

return Store
