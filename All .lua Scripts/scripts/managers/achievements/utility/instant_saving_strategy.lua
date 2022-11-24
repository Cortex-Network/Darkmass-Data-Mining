local AchievementStats = require("scripts/managers/stats/groups/achievement_stats")
local AchievementTypes = require("scripts/settings/achievements/achievement_types")
local Promise = require("scripts/foundation/utilities/promise")
local SavingStrategyInterface = require("scripts/managers/achievements/utility/saving_strategy_interface")
local StatFlags = require("scripts/settings/stats/stat_flags")
local InstantSavingStrategy = class("InstantSavingStrategy")

function InstantSavingStrategy:init(achievement_definitions)
	self._definitions = achievement_definitions
	self._promise = Promise.resolved()
	self._tracked_accounts = {}
	self._stats_by_player = {}
	self._unlocks_by_player = {}
end

function InstantSavingStrategy:destroy()
	if self._promise:is_pending() then
		self._promise:cancel()
	end
end

function InstantSavingStrategy:_add_player(account_id)
	local accounts = self._tracked_accounts

	if not table.array_contains(accounts, account_id) then
		accounts[#accounts + 1] = account_id
		self._stats_by_player[account_id] = {}
		self._unlocks_by_player[account_id] = {}
	end
end

function InstantSavingStrategy:_add_unlock(account_id, achievement_id)
	self:_add_player(account_id)

	local unlocks = self._unlocks_by_player[account_id]
	local size = #unlocks
	local achievement_definition = self._definitions.achievement_from_id(achievement_id)
	local type, triggers = achievement_definition:get_triggers()
	local stat_name = type == AchievementTypes.stat and triggers[1] or "none"
	unlocks[size + 1] = {
		complete = true,
		id = achievement_id,
		stat = stat_name
	}
end

function InstantSavingStrategy:_add_stat(account_id, trigger_id, trigger_value)
	self:_add_player(account_id)

	local stats = self._stats_by_player[account_id]
	local size = #stats

	for i = 1, size do
		if stats[i].stat == trigger_id then
			stats[i].value = trigger_value

			return
		end
	end

	stats[size + 1] = {
		isPlatformStat = false,
		stat = trigger_id,
		value = trigger_value
	}
end

function InstantSavingStrategy:_push_update()
	local updates = {}

	for i = 1, #self._tracked_accounts do
		local account_id = self._tracked_accounts[i]
		local stats = self._stats_by_player[account_id]
		local unlocks = self._unlocks_by_player[account_id]

		if #stats > 0 or #unlocks > 0 then
			updates[#updates + 1] = Managers.backend.interfaces.commendations:create_update(account_id, stats, unlocks)
		end
	end

	self._tracked_accounts = {}
	self._stats_by_player = {}
	self._unlocks_by_player = {}

	if #updates == 0 then
		self._promise = Promise.resolved()

		return
	end

	self._promise = Managers.backend.interfaces.commendations:bulk_update_commendations(updates):next(function ()
		self:_push_update()
	end)
end

function InstantSavingStrategy:track_player(account_id, player_data)
end

function InstantSavingStrategy:save_on_player_exit(_)
	return self._promise
end

function InstantSavingStrategy:save_on_all_exit()
	return self._promise
end

function InstantSavingStrategy:save_on_stat_change(account_id, trigger_id, trigger_value, ...)
	local defitinition = AchievementStats.definitions[trigger_id]

	if not defitinition or not defitinition:check_flag(StatFlags.save_to_backend) then
		return
	end

	self:_add_stat(account_id, trigger_id, trigger_value)

	if not self._promise:is_pending() then
		self:_push_update()
	end
end

function InstantSavingStrategy:save_on_achievement_unlock(account_id, achievement_id)
	self:_add_unlock(account_id, achievement_id)

	if not self._promise:is_pending() then
		self:_push_update()
	end
end

implements(InstantSavingStrategy, SavingStrategyInterface)

return InstantSavingStrategy
