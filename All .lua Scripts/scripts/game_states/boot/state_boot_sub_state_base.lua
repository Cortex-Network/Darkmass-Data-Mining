local StateBootSubStateBase = class("StateBootSubStateBase")
StateBootSubStateBase.ENFORCED_INTERFACE = {
	"update",
	"_state_update"
}

function StateBootSubStateBase:on_enter(parent, params)
	self._parent = parent
	self._params = params
end

function StateBootSubStateBase:_state_params()
	return self._params.states[self._params.sub_state_index][2]
end

function StateBootSubStateBase:update()
	local done, error = self:_state_update()
	local params = self._params

	if error then
		return StateError, {
			error
		}
	elseif done then
		local next_index = params.sub_state_index + 1
		params.sub_state_index = next_index
		local next_state_data = params.states[next_index]

		if next_state_data then
			return next_state_data[1], self._params
		else
			self._parent:sub_states_done()
		end
	end
end

return StateBootSubStateBase
