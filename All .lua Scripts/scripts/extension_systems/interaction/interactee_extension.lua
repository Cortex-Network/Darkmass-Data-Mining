local Interactions = require("scripts/settings/interaction/interactions")
local InteractionSettings = require("scripts/settings/interaction/interaction_settings")
local InteractionTemplates = require("scripts/settings/interaction/interaction_templates")
local MasterItems = require("scripts/backend/master_items")
local InteracteeExtension = class("InteracteeExtension")
local emissive_colors = InteractionSettings.emissive_colors
local interaction_results = InteractionSettings.results

function InteracteeExtension:init(extension_init_context, unit, extension_init_data, game_object_data, game_object_id)
	local is_server = extension_init_context.is_server
	self._is_server = is_server
	self._unit = unit
	self._used = false
	self._is_being_used = false
	self._active = not extension_init_data.start_inactive
	self._spawn_cooldown = extension_init_data.spawn_interaction_cooldown
	self._owner_system = extension_init_context.owner_system
	self._interactions = {}
	self._override_contexts = {}
	self._active_interaction_type = nil
	self._emissive_material_name = nil
	self._animation_extension = nil

	if is_server then
		local level_id = Managers.state.unit_spawner:level_index(unit)

		if level_id then
			self._unit_id = level_id
			self._is_level_unit = true
		end
	end

	self:set_interaction_context(extension_init_data.interaction_type, extension_init_data.override_context)
end

function InteracteeExtension:update(unit, dt, t)
	local spawn_cooldown = self._spawn_cooldown

	if spawn_cooldown then
		spawn_cooldown = spawn_cooldown - dt

		if spawn_cooldown <= 0 then
			spawn_cooldown = nil
		end

		self._spawn_cooldown = spawn_cooldown
	else
		self._owner_system:disable_update_function(self.__class_name, "update", self._unit, self)
	end
end

function InteracteeExtension:hot_join_sync(unit, sender, channel)
	local is_active = self._active

	if not is_active then
		local unit_id = self._unit_id
		local is_level_unit = self._is_level_unit
		local is_used = self._used

		RPC.rpc_interaction_hot_join(channel, unit_id, is_level_unit, is_active, is_used)
	end
end

function InteracteeExtension:game_object_initialized(session, game_object_id)
	if not self._is_level_unit then
		self._is_level_unit = false
		self._unit_id = game_object_id
	end
end

function InteracteeExtension:set_interaction_context(interaction_type, override_context)
	if interaction_type then
		local interactions = self._interactions

		if not interactions[interaction_type] then
			local interaction_template = InteractionTemplates[interaction_type]
			local interaction_class_name = interaction_template.interaction_class_name
			interactions[interaction_type] = Interactions[interaction_class_name]:new(interaction_template)
		end

		local override_contexts = self._override_contexts

		if not override_contexts[interaction_type] then
			override_contexts[interaction_type] = override_context
		end

		self._active_interaction_type = interaction_type
	end
end

function InteracteeExtension:setup_animation()
	self._animation_extension = ScriptUnit.has_extension(self._unit, "animation_system")
end

function InteracteeExtension:animation_event(anim_event)
	if self._is_server and self._animation_extension then
		self._animation_extension:anim_event(anim_event)
	end
end

function InteracteeExtension:can_interact(interactor_unit)
	if self._spawn_cooldown then
		return false
	end

	if self._used and self._active then
		self._active = false

		self:update_light()

		return false
	end

	local active_interaction_type = self._active_interaction_type

	if not active_interaction_type then
		return false
	end

	local active_override_context = self._override_contexts[active_interaction_type]
	local shared_interaction = active_override_context.shared_interaction
	local is_being_used = self._is_being_used and not shared_interaction and interactor_unit ~= self._interactor_unit

	if is_being_used then
		return false
	end

	local is_active = self._active

	if not is_active then
		return false
	end

	local interaction = self._interactions[active_interaction_type]

	return interaction:interactee_condition_func(self._unit)
end

function InteracteeExtension:show_marker(interactor_unit)
	local active_interaction_type = self._active_interaction_type

	if not active_interaction_type then
		return false
	end

	local interaction = self._interactions[active_interaction_type]

	return interaction:interactee_show_marker_func(interactor_unit, self._unit)
end

function InteracteeExtension:set_active(is_active)
	if self._is_server then
		local unit_id = self._unit_id
		local is_level_unit = self._is_level_unit

		Managers.state.game_session:send_rpc_clients("rpc_interaction_set_active", unit_id, is_level_unit, is_active)
	end

	self._active = not not is_active

	self:update_light()
end

function InteracteeExtension:set_emissive_material_name(material_name)
	self._emissive_material_name = material_name

	self:update_light()
end

function InteracteeExtension:update_light()
	if not self._emissive_material_name then
		return
	end

	local color_box = nil

	if self._used then
		color_box = emissive_colors.used
	elseif self._active then
		color_box = emissive_colors.active
	else
		color_box = emissive_colors.inactive
	end

	local color = color_box:unbox()

	Unit.set_vector3_for_material(self._unit, self._emissive_material_name, "emissive_color", color)
end

function InteracteeExtension:hot_join_setup(is_active, is_used)
	self._active = is_active
	self._used = is_used

	self:update_light()
end

function InteracteeExtension:set_used()
	self._used = true
	self._active = false

	self:update_light()
end

function InteracteeExtension:used()
	return self._used
end

function InteracteeExtension:active()
	return self._active
end

function InteracteeExtension:interaction_type()
	local active_interaction_type = self._active_interaction_type

	if not active_interaction_type then
		return "none"
	end

	local interaction = self._interactions[active_interaction_type]

	return interaction:type()
end

function InteracteeExtension:interaction_length()
	local active_interaction_type = self._active_interaction_type

	if not active_interaction_type then
		return 0
	end

	local override_context = self._override_contexts[active_interaction_type]
	local interaction = self._interactions[active_interaction_type]

	return override_context.duration or interaction:duration()
end

function InteracteeExtension:display_start_event()
	local active_interaction_type = self._active_interaction_type

	if not active_interaction_type then
		return false
	end

	local override_context = self._override_contexts[active_interaction_type]

	return override_context.display_start_event or false
end

function InteracteeExtension:disable_display_start_event()
	local active_interaction_type = self._active_interaction_type

	if not active_interaction_type then
		return
	end

	local override_context = self._override_contexts[active_interaction_type]
	override_context.display_start_event = false
end

function InteracteeExtension:ui_interaction_type()
	local active_interaction_type = self._active_interaction_type

	if not active_interaction_type then
		return
	end

	local override_context = self._override_contexts[active_interaction_type]
	local interaction = self._interactions[active_interaction_type]

	return override_context.ui_interaction_type or interaction:ui_interaction_type()
end

function InteracteeExtension:interaction_icon()
	local active_interaction_type = self._active_interaction_type

	if not active_interaction_type then
		return
	end

	local override_context = self._override_contexts[active_interaction_type]
	local interaction = self._interactions[active_interaction_type]

	return override_context.interaction_icon or interaction:interaction_icon()
end

function InteracteeExtension:set_action_text(text)
	local active_interaction_type = self._active_interaction_type

	if active_interaction_type then
		local override_context = self._override_contexts[active_interaction_type]
		override_context.action_text = text
	end
end

function InteracteeExtension:action_text()
	local active_interaction_type = self._active_interaction_type

	if not active_interaction_type then
		return
	end

	local override_context = self._override_contexts[active_interaction_type]
	local interaction = self._interactions[active_interaction_type]

	return override_context.action_text or interaction:action_text()
end

function InteracteeExtension:set_description(description)
	local active_interaction_type = self._active_interaction_type

	if active_interaction_type then
		local override_context = self._override_contexts[active_interaction_type]
		override_context.description = description
	end
end

function InteracteeExtension:set_duration(duration)
	local active_interaction_type = self._active_interaction_type

	if active_interaction_type then
		local override_context = self._override_contexts[active_interaction_type]
		override_context.duration = duration
	end
end

function InteracteeExtension:description()
	local active_interaction_type = self._active_interaction_type

	if not active_interaction_type then
		return
	end

	local override_context = self._override_contexts[active_interaction_type]
	local interaction = self._interactions[active_interaction_type]

	return override_context.description or interaction:description()
end

function InteracteeExtension:set_block_text(text, block_text_context)
	local active_interaction_type = self._active_interaction_type

	if active_interaction_type then
		local override_context = self._override_contexts[active_interaction_type]
		override_context.block_text = text
		override_context.block_text_context = block_text_context
	end
end

function InteracteeExtension:block_text()
	local active_interaction_type = self._active_interaction_type

	if not active_interaction_type then
		return
	end

	local override_context = self._override_contexts[active_interaction_type]

	if not override_context.block_text then
		return
	end

	return override_context.block_text, override_context.block_text_context
end

function InteracteeExtension:hold_required()
	return self:interaction_length() > 0
end

function InteracteeExtension:interactor_item_to_equip()
	local active_interaction_type = self._active_interaction_type

	if not active_interaction_type then
		return nil
	end

	local override_context = self._override_contexts[active_interaction_type]
	local item_to_equip = override_context.interactor_item_to_equip

	if item_to_equip and item_to_equip ~= "" then
		local item = MasterItems.get_item(item_to_equip)

		if not item then
			Log.error("InteracteeExtension", "missing inventory item: %s for interaction: %s", item, active_interaction_type)

			return MasterItems.find_fallback_item("slot_device")
		end

		return item
	end

	return nil
end

function InteracteeExtension:ui_interaction()
	local active_interaction_type = self._active_interaction_type

	if not active_interaction_type then
		return nil
	end

	local override_context = self._override_contexts[active_interaction_type]
	local interaction = self._interactions[active_interaction_type]

	return override_context.ui_view_name or interaction:ui_view_name()
end

function InteracteeExtension:started(interactor_unit)
	if self._is_server then
		local unit_id = self._unit_id
		local is_level_unit = self._is_level_unit
		local interactor_object_id = Managers.state.unit_spawner:game_object_id(interactor_unit)

		Managers.state.game_session:send_rpc_clients("rpc_interaction_started", unit_id, is_level_unit, interactor_object_id)
	end

	self._is_being_used = true
	self._interactor_unit = interactor_unit

	Unit.set_flow_variable(self._unit, "lua_interactor_unit", interactor_unit)
	self:_trigger_flow_event("lua_interaction_start")
end

function InteracteeExtension:stopped(result)
	if self._is_server then
		local unit_id = self._unit_id
		local is_level_unit = self._is_level_unit
		local result_id = NetworkLookup.interaction_result[result]

		Managers.state.game_session:send_rpc_clients("rpc_interaction_stopped", unit_id, is_level_unit, result_id)
	end

	if result == interaction_results.success then
		local player_unit_spawn_manager = Managers.state.player_unit_spawn
		local player = player_unit_spawn_manager:owner(self._interactor_unit)

		if player and not player.remote then
			self:_trigger_flow_event("lua_interaction_success_local")
		end

		self:_trigger_flow_event("lua_interaction_success_network_synced")

		local active_interaction_type = self._active_interaction_type

		if active_interaction_type then
			local override_context = self._override_contexts[active_interaction_type]
			local interaction = self._interactions[active_interaction_type]
			local only_once = override_context.only_once or interaction:only_once()

			if only_once then
				self:set_used()
			end
		end
	else
		self:_trigger_flow_event("lua_interaction_cancelled")
	end

	self._interactor_unit = nil
	self._is_being_used = false
end

function InteracteeExtension:_trigger_flow_event(event_name)
	Unit.flow_event(self._unit, event_name)
end

function InteracteeExtension:activate_interaction(interaction_type)
	self._active_interaction_type = interaction_type

	if not self._interactions[self._active_interaction_type] or not self._override_contexts[self._active_interaction_type] then
		self._active_interaction_type = nil
	end
end

return InteracteeExtension
