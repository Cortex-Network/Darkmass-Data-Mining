local CharacterStateMachine = class("CharacterStateMachine")

function CharacterStateMachine:init(unit, is_server, states, start_state, dt, t)
	self._unit = unit
	self._params = {}
	self._is_server = is_server
	self._states = states
	self._state_current = {
		name = "dummy",
		fixed_update = function ()
			return start_state
		end,
		on_exit = function ()
		end,
		extensions_ready = function ()
		end,
		game_object_initialized = function ()
		end
	}
	local unit_data_extension = ScriptUnit.extension(unit, "unit_data_system")
	self._unit_data_extension = unit_data_extension
	local character_state_component = unit_data_extension:write_component("character_state")
	self._character_state_component = character_state_component
	character_state_component.previous_state_name = "dummy"
	character_state_component.state_name = is_server and start_state or "dummy"
	character_state_component.entered_t = t

	if is_server then
		self._init_context = {
			dt = dt,
			t = t,
			start_state = start_state
		}
	end
end

function CharacterStateMachine:extensions_ready(world, unit)
	for name, state in pairs(self._states) do
		state:extensions_ready(world, unit)
	end
end

function CharacterStateMachine:game_object_initialized(game_session, game_object_id)
	for name, state in pairs(self._states) do
		state:game_object_initialized(game_session, game_object_id)
	end

	local init_context = self._init_context
	local dt = init_context.dt
	local t = init_context.t
	local start_state = init_context.start_state

	self:_change_state(self._unit, dt, t, start_state, self._params)
	table.clear(self._init_context)

	self._init_context = nil
end

function CharacterStateMachine:server_correction_occurred(unit)
	local component_state_name = self._character_state_component.state_name
	local current_state_name = self._state_current.name

	if component_state_name ~= current_state_name then
		local state = self._states[component_state_name]

		if state.on_enter_server_corrected_state then
			state:on_enter_server_corrected_state(unit)
		end

		self._state_current = state
	end
end

function CharacterStateMachine:fixed_update(unit, dt, t, frame, ...)
	local params = self._params
	local next_state = nil
	next_state = self._state_current:fixed_update(unit, dt, t, params, frame, ...)

	if next_state ~= nil then
		self:_change_state(unit, dt, t, next_state, self._params)
	end
end

function CharacterStateMachine:pre_update(unit, dt, t, ...)
	local update_func = self._state_current.pre_update

	if update_func then
		update_func(self._state_current, unit, dt, t, ...)
	end
end

function CharacterStateMachine:update(unit, dt, t, ...)
	local update_func = self._state_current.update

	if update_func then
		update_func(self._state_current, unit, dt, t, ...)
	end
end

function CharacterStateMachine:exit_current_state()
	if self._state_current then
		local t = Managers.time:time("gameplay")
		local next_state = nil

		self._state_current:on_exit(self._unit, t, next_state)

		self._state_current = nil
	end
end

function CharacterStateMachine:current_state()
	return self._state_current and self._state_current.name or "none"
end

function CharacterStateMachine:set_state(unit, dt, t, next_state, params)
	self:_change_state(unit, dt, t, next_state, params)
end

function CharacterStateMachine:_change_state(unit, dt, t, next_state, params)
	self._state_current:on_exit(unit, t, next_state)

	local old_state_name = self._state_current.name
	local new_state = self._states[next_state]
	local character_state_component = self._character_state_component
	character_state_component.previous_state_name = old_state_name
	character_state_component.state_name = new_state.name
	character_state_component.entered_t = t

	new_state:on_enter(unit, dt, t, old_state_name, params)
	table.clear(params)

	self._state_current = new_state
end

return CharacterStateMachine
