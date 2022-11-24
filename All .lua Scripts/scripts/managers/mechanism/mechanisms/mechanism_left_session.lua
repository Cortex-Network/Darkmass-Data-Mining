local MechanismBase = require("scripts/managers/mechanism/mechanisms/mechanism_base")
local StateExitToMainMenu = require("scripts/game_states/game/state_exit_to_main_menu")
local StateLoading = require("scripts/game_states/game/state_loading")
local Promise = require("scripts/foundation/utilities/promise")
local MechanismLeftSession = class("MechanismLeftSession", "MechanismBase")
local TIMEOUT = 10

function MechanismLeftSession:init(...)
	MechanismLeftSession.super.init(self, ...)

	local reason = self._context.left_session_reason

	Log.info("MechanismLeftSession", "Entered with reason %s", reason)

	self._leave_party_promise = Promise.resolved()

	if DEDICATED_SERVER then
		return
	end

	if reason == "leave_mission" then
		self:_leave_party()
	elseif reason == "skip_end_of_round" then
		-- Nothing
	elseif reason == "leave_to_hub" then
		-- Nothing
	elseif reason == "failed_fetching_session_report" then
		self:_leave_party()
	elseif reason == "session_completed" then
		self:_leave_party()
	else
		self._next_state = StateExitToMainMenu
	end
end

function MechanismLeftSession:_leave_party()
	self._leave_party_promise = Managers.party_immaterium:leave_party()
end

function MechanismLeftSession:sync_data()
	ferror("Somebody joined you while in left session mechanism. This means you are hosting while in the left session mechanism.")
end

function MechanismLeftSession:failed_fetching_session_report(peer_id)
end

function MechanismLeftSession:game_mode_end(reason, session_id)
end

function MechanismLeftSession:wanted_transition()
	if self._left_session_done then
		return false
	end

	if self._next_state then
		self._left_session_done = true

		return false, self._next_state, {}
	end

	if self._timeout_at then
		local t = Managers.time:time("main")

		if self._timeout_at < t then
			self._left_session_done = true

			return false, StateExitToMainMenu, {}
		end
	end

	local state = self._state

	if state == "init" then
		if GameParameters.prod_like_backend then
			self._leave_party_promise:next(function ()
				self._leave_party_done = true
			end):catch(function (error)
				self._leave_party_done = true
			end)
			self:_set_state("wait_for_session")

			local t = Managers.time:time("main")
			self._timeout_at = t + TIMEOUT

			return false, StateLoading, {}
		end
	elseif state == "search_for_session" then
		local next_state, context = Managers.multiplayer_session:find_available_session()

		if next_state then
			self._left_session_done = true

			return false, next_state, context
		end
	elseif state == "wait_for_session" and self._leave_party_done then
		local next_state, context = Managers.multiplayer_session:find_available_session()

		if next_state then
			self._left_session_done = true

			return false, next_state, context
		end
	end

	return false
end

function MechanismLeftSession:is_allowed_to_reserve_slots(peer_ids)
	return false
end

function MechanismLeftSession:peers_reserved_slots(peer_ids)
	ferror("Someone is connecting while we are leaving session. Problem?")
end

function MechanismLeftSession:peer_freed_slot(peer_id)
end

implements(MechanismLeftSession, MechanismBase.INTERFACE)

return MechanismLeftSession
