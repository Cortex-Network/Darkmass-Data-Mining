local MinigameSettings = require("scripts/settings/minigame/minigame_settings")
local DecoderDeviceExtension = class("DecoderDeviceExtension")
local minigame_states = MinigameSettings.states
local VISIBLE_STATES = table.enum("none", "ghost", "main")
local UNIT_MARKER_STATES = table.enum("shown", "hidden")

function DecoderDeviceExtension:init(extension_init_context, unit, extension_init_data, ...)
	self._unit = unit
	self._is_server = extension_init_context.is_server
	self._unit_is_enabled = false
	self._is_placed = false
	self._decoding_interrupted = false
	self._is_finished = false
	self._started_decode = false
	self._synchronizer = nil
	self._decoder_synchronizer_extension = nil
	self._mission_objective_target_extension = nil
	self._animation_extension = nil
	self._minigame_extension = nil
	self._interactee_extension = nil
	self._marker_state = UNIT_MARKER_STATES.hidden
	self._material_slot_name = ""
	self._materials = {}
	self._install_anim_event = ""

	self:_set_visible_state(VISIBLE_STATES.none)
end

function DecoderDeviceExtension:setup_from_component(material_slot_name, main_material, ghost_material, install_anim_event)
	self._material_slot_name = material_slot_name
	self._materials[VISIBLE_STATES.main] = main_material
	self._materials[VISIBLE_STATES.ghost] = ghost_material
	self._install_anim_event = install_anim_event
end

function DecoderDeviceExtension:extensions_ready(world, unit)
	self._minigame_extension = ScriptUnit.has_extension(unit, "minigame_system")
	self._animation_extension = ScriptUnit.has_extension(unit, "animation_system")
	local interactee_extension = ScriptUnit.extension(unit, "interactee_system")

	interactee_extension:activate_interaction("setup_decoding")

	self._interactee_extension = interactee_extension
	self._mission_objective_target_extension = ScriptUnit.extension(unit, "mission_objective_target_system")
end

function DecoderDeviceExtension:hot_join_sync(unit_is_enabled, is_placed, started_decode, decoding_interrupted, is_finished)
	self._unit_is_enabled = unit_is_enabled
	self._is_placed = is_placed
	self._started_decode = started_decode
	self._decoding_interrupted = decoding_interrupted
	local unit = self._unit

	if unit_is_enabled then
		self:_set_visible_state(VISIBLE_STATES.ghost)
		Unit.flow_event(unit, "lua_device_enabled")
	end

	if is_placed then
		self:_set_visible_state(VISIBLE_STATES.main)

		if not is_finished then
			if started_decode and not decoding_interrupted then
				Unit.flow_event(unit, "lua_decode")
			elseif started_decode and decoding_interrupted then
				Unit.flow_event(unit, "lua_decode_on_hold")
			end
		end
	end
end

function DecoderDeviceExtension:update(unit, dt, t)
	if self._is_server and self._decoding_interrupted then
		local minigame_extension = self._minigame_extension

		if minigame_extension then
			local current_minigame_state = minigame_extension:current_state()

			if current_minigame_state == minigame_states.none then
				self._interruption_ignored_timer = self._interruption_ignored_timer + dt

				if self._interruption_ignored_timer > 1 then
					self._interruption_ignored_timer = self._interruption_ignored_timer - 1

					if Managers.stats.can_record_stats() then
						Managers.stats:record_decoder_ignored()
					end
				end
			elseif current_minigame_state == minigame_states.completed then
				minigame_extension:stop()
				self._decoder_synchronizer_extension:unblock_decoding_progression()
			end
		end
	end

	self:_update_unit_marker_state()
end

function DecoderDeviceExtension:register_synchronizer(synchronizer_extension)
	self._decoder_synchronizer_extension = synchronizer_extension
	local unit = self._unit
	local interactee_extension = ScriptUnit.extension(unit, "interactee_system")

	interactee_extension:set_active(true)

	if self._is_server then
		local mission_objective_target_extension = self._mission_objective_target_extension

		mission_objective_target_extension:add_unit_marker()
	end
end

function DecoderDeviceExtension:enable_unit()
	self._unit_is_enabled = true

	self:_set_visible_state(VISIBLE_STATES.ghost)

	if self._is_server then
		local unit_id = Managers.state.unit_spawner:level_index(self._unit)

		Managers.state.game_session:send_rpc_clients("rpc_decoder_device_enable_unit", unit_id)
	end
end

function DecoderDeviceExtension:_set_device_state(device_state)
	self._device_state = device_state
end

function DecoderDeviceExtension:_update_unit_marker_state()
	if self._is_server then
		local mission_objective_target_extension = self._mission_objective_target_extension
		local should_show = self:wait_for_setup() or self:wait_for_restart()
		local marker_state = self._marker_state

		if marker_state == UNIT_MARKER_STATES.shown and not should_show then
			mission_objective_target_extension:remove_unit_marker()

			self._marker_state = UNIT_MARKER_STATES.hidden
		elseif marker_state == UNIT_MARKER_STATES.hidden and should_show then
			mission_objective_target_extension:add_unit_marker()

			self._marker_state = UNIT_MARKER_STATES.shown
		end
	end
end

function DecoderDeviceExtension:_set_visible_state(visible_state)
	local unit = self._unit
	local material_name = self._materials[visible_state]
	local material_slot_name = self._material_slot_name

	if visible_state == VISIBLE_STATES.none then
		Unit.set_unit_visibility(unit, false)
	elseif visible_state == VISIBLE_STATES.ghost then
		Unit.set_unit_visibility(unit, true)

		if material_name ~= "" and material_slot_name ~= "" then
			Unit.set_material(unit, material_slot_name, material_name)
		end
	elseif visible_state == VISIBLE_STATES.main then
		Unit.set_unit_visibility(unit, true)

		if material_name ~= "" and material_slot_name ~= "" then
			Unit.set_material(unit, material_slot_name, material_name)
		end
	end
end

function DecoderDeviceExtension:decoder_setup_success()
	if not self._is_placed then
		self:place_unit()
		self._decoder_synchronizer_extension:unblock_decoding_progression()
	end
end

function DecoderDeviceExtension:place_unit()
	if self._is_server and self._install_anim_event ~= "" then
		local unit_id = Managers.state.unit_spawner:level_index(self._unit)

		Managers.state.game_session:send_rpc_clients("rpc_decoder_device_place_unit", unit_id)
		self:_play_anim(self._install_anim_event)
	end

	self:_set_visible_state(VISIBLE_STATES.main)

	self._is_placed = true

	Unit.flow_event(self._unit, "lua_device_placed")

	local interactee_extension = self._interactee_extension

	interactee_extension:activate_interaction("decoding")
end

function DecoderDeviceExtension:start_decode()
	if self._started_decode and not self._decoding_interrupted then
		return
	end

	if self._is_server then
		local unit_id = Managers.state.unit_spawner:level_index(self._unit)

		Managers.state.game_session:send_rpc_clients("rpc_decoder_device_start_decode", unit_id)
	end

	self._decoding_interrupted = false
	self._started_decode = true

	Unit.flow_event(self._unit, "lua_decode")
end

function DecoderDeviceExtension:decode_interrupt()
	if self._is_server then
		local unit_id = Managers.state.unit_spawner:level_index(self._unit)

		Managers.state.game_session:send_rpc_clients("rpc_decoder_device_decode_interrupt", unit_id)
	end

	self._decoding_interrupted = true
	self._interruption_ignored_timer = 0

	Unit.flow_event(self._unit, "lua_decode_on_hold")
end

function DecoderDeviceExtension:finished()
	if self._is_server then
		local unit_id = Managers.state.unit_spawner:level_index(self._unit)

		Managers.state.game_session:send_rpc_clients("rpc_decoder_device_finished", unit_id)
	end

	self._is_finished = true

	Unit.flow_event(self._unit, "lua_finished")
end

function DecoderDeviceExtension:unit_is_enabled()
	return self._unit_is_enabled
end

function DecoderDeviceExtension:is_placed()
	return self._is_placed
end

function DecoderDeviceExtension:started_decode()
	return self._started_decode
end

function DecoderDeviceExtension:decoding_interrupted()
	return self._decoding_interrupted
end

function DecoderDeviceExtension:is_finished()
	return self._is_finished
end

function DecoderDeviceExtension:wait_for_setup()
	local minigame_extension = self._minigame_extension
	local current_minigame_state = minigame_extension and minigame_extension:current_state() or minigame_states.none
	local decode_interaction = not self._started_decode and not self._is_placed

	return self._unit_is_enabled and decode_interaction and current_minigame_state ~= minigame_states.active
end

function DecoderDeviceExtension:wait_for_restart()
	local minigame_extension = self._minigame_extension
	local current_minigame_state = minigame_extension and minigame_extension:current_state() or minigame_states.none
	local decode_interaction = self._is_placed and self._started_decode and self._decoding_interrupted

	return self._unit_is_enabled and decode_interaction and current_minigame_state ~= minigame_states.active
end

function DecoderDeviceExtension:_play_anim(anim_event)
	local animation_extension = self._animation_extension

	if animation_extension then
		animation_extension:anim_event(anim_event)
	end
end

return DecoderDeviceExtension
