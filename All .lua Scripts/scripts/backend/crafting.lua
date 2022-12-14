local BackendUtilities = require("scripts/foundation/managers/backend/utilities/backend_utilities")
local Crafting = class("Crafting")

local function _send_crafting_operation(op)
	return BackendUtilities.make_account_title_request("account", BackendUtilities.url_builder("/crafting"), {
		method = "POST",
		body = op
	}):next(function (data)
		data.body._links = nil

		return data.body
	end)
end

function Crafting:get_crafting_costs()
	return Managers.backend:title_request(BackendUtilities.url_builder("/data/account/crafting/costs"):to_string()):next(function (data)
		return data.body.costs
	end)
end

function Crafting:upgrade_weapon_rarity(gear_id)
	return _send_crafting_operation({
		op = "upgradeWeaponRarity",
		gearId = gear_id
	})
end

function Crafting:upgrade_gadget_rarity(gear_id)
	return _send_crafting_operation({
		op = "upgradeGadgetRarity",
		gearId = gear_id
	})
end

function Crafting:extract_trait_from_weapon(gear_id, trait_index)
	return _send_crafting_operation({
		traitType = "traits",
		op = "extractTrait",
		gearId = gear_id,
		traitIndex = trait_index - 1
	})
end

function Crafting:extract_perk_from_weapon(gear_id, trait_index)
	return _send_crafting_operation({
		traitType = "perks",
		op = "extractTrait",
		gearId = gear_id,
		traitIndex = trait_index - 1
	})
end

function Crafting:replace_trait_in_weapon(gear_id, existing_trait_index, new_trait_id)
	return _send_crafting_operation({
		traitType = "traits",
		op = "replaceTrait",
		gearId = gear_id,
		traitIndex = existing_trait_index - 1,
		traitId = new_trait_id
	})
end

function Crafting:replace_perk_in_weapon(gear_id, existing_trait_index, new_trait_id)
	return _send_crafting_operation({
		traitType = "perks",
		op = "replaceTrait",
		gearId = gear_id,
		traitIndex = existing_trait_index - 1,
		traitId = new_trait_id
	})
end

function Crafting:reroll_perk_in_item(gear_id, existing_perk_index, is_gadget)
	return _send_crafting_operation({
		op = "rerollPerk",
		gearId = gear_id,
		perkIndex = existing_perk_index - 1,
		itemType = is_gadget and "gadget" or "weapon"
	})
end

function Crafting:fuse_traits(character_id, trait_ids)
	return _send_crafting_operation({
		op = "fuseTraits",
		traitIds = trait_ids,
		characterId = character_id
	})
end

return Crafting
