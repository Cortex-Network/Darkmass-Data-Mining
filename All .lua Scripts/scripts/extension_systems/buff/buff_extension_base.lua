local BuffClasses = require("scripts/settings/buff/buff_classes")
local BuffExtensionInterface = require("scripts/extension_systems/buff/buff_extension_interface")
local BuffSettings = require("scripts/settings/buff/buff_settings")
local BuffTemplates = require("scripts/settings/buff/buff_templates")
local FixedFrame = require("scripts/utilities/fixed_frame")
local PortableRandom = require("scripts/foundation/utilities/portable_random")
local BUFF_TARGETS = BuffSettings.targets
local MIN_PROC_EVENTS_SIZE = BuffSettings.min_proc_events_size
local MAX_PROC_EVENTS = BuffSettings.max_proc_events
local PROC_EVENTS_STRIDE = BuffSettings.proc_events_stride
local BuffExtensionBase = class("BuffExtensionBase")
local Unit_world_position = Unit.world_position
local WwiseWorld_set_source_position = WwiseWorld.set_source_position
local RPCS = {
	"rpc_add_buff",
	"rpc_remove_buff",
	"rpc_buff_proc_set_active_time"
}
local _stat_buff_base_values = BuffSettings.stat_buff_type_base_values
local _stat_buff_lazy_mt = {
	__index = function (self, key)
		local val = _stat_buff_base_values[key]
		self[key] = val

		return val
	end
}

function BuffExtensionBase:init(extension_init_context, unit, extension_init_data, game_object_data_or_game_session, nil_or_game_object_id)
	local is_server = extension_init_context.is_server
	self._is_server = is_server
	self._unit = unit
	local seed = extension_init_data.buff_seed
	self._portable_random = PortableRandom:new(seed)
	self._local_portable_random = PortableRandom:new(seed)
	self._buff_context = {
		world = extension_init_context.world,
		physics_world = extension_init_context.physics_world,
		wwise_world = extension_init_context.wwise_world,
		unit = unit,
		player = extension_init_data.player,
		buff_extension = self,
		is_local_unit = extension_init_data.is_local_unit,
		is_server = is_server,
		breed = extension_init_data.breed
	}
	self._index = 0
	self._buffs = {}
	self._muted_external_buffs = {}
	self._buff_instance_id = 0
	self._stacking_buffs = {}
	self._buffs_by_index = {}
	self._stat_buffs = setmetatable({
		_modified_stats = {}
	}, _stat_buff_lazy_mt)
	self._keywords = {}
	self._active_vfx = {}
	self._active_wwise_node_sources = {}
	self._proc_event_param_tables = {}
	self._num_proc_events = 0
	self._param_table_index = 0
	self._unique_frame_proc = {}

	if self._pre_allocate_event_param_tables then
		self._proc_events = Script.new_array(MAX_PROC_EVENTS * PROC_EVENTS_STRIDE)

		for i = 1, MAX_PROC_EVENTS do
			self._proc_event_param_tables[i] = {}
		end
	else
		self._proc_events = Script.new_array(MIN_PROC_EVENTS_SIZE * PROC_EVENTS_STRIDE)
	end

	if is_server then
		self._buffs_added_before_game_object_creation = {}
		local initial_buffs = extension_init_data.initial_buffs

		if initial_buffs then
			local t = FixedFrame.get_latest_fixed_time()

			for i = 1, #initial_buffs do
				local buff_name = initial_buffs[i]

				self:add_internally_controlled_buff(buff_name, t)
			end
		end
	else
		local network_event_delegate = extension_init_context.network_event_delegate
		self._network_event_delegate = network_event_delegate
		self._game_object_id = nil_or_game_object_id

		network_event_delegate:register_session_unit_events(self, nil_or_game_object_id, unpack(RPCS))

		self._rpcs_registered = true
		self._buff_index_map = {}
	end
end

function BuffExtensionBase:destroy()
	local buffs = self._buffs_by_index

	for index, _ in pairs(buffs) do
		self:_remove_buff(index)
	end

	local is_server = self._is_server

	if not is_server and self._rpcs_registered then
		self._network_event_delegate:unregister_unit_events(self._game_object_id, unpack(RPCS))

		self._rpcs_registered = false
	end
end

function BuffExtensionBase:game_object_initialized(game_session, game_object_id)
	self._game_object_id = game_object_id
	local buffs_added_before_game_object_cration = self._buffs_added_before_game_object_creation

	if buffs_added_before_game_object_cration then
		for i = 1, #buffs_added_before_game_object_cration do
			local buff_added_before_game_object_cration = buffs_added_before_game_object_cration[i]
			local buff_template_id = buff_added_before_game_object_cration.buff_template_id
			local index = buff_added_before_game_object_cration.index
			local optional_lerp_value = buff_added_before_game_object_cration.optional_lerp_value
			local optional_slot_id = buff_added_before_game_object_cration.optional_slot_id
			local optional_parent_buff_template_id = buff_added_before_game_object_cration.optional_parent_buff_template_id

			Managers.state.game_session:send_rpc_clients("rpc_add_buff", game_object_id, buff_template_id, index, optional_lerp_value, optional_slot_id, optional_parent_buff_template_id)
		end

		self._buffs_added_before_game_object_creation = nil
	end
end

function BuffExtensionBase:set_unit_local()
	local buff_context = self._buff_context
	buff_context.is_local_unit = true
	local buffs = self._buffs_by_index

	for index, buff_instance in pairs(buffs) do
		self:_remove_buff(index)
	end

	local is_server = self._is_server

	if not is_server and self._rpcs_registered then
		self._network_event_delegate:unregister_unit_events(self._game_object_id, unpack(RPCS))

		self._rpcs_registered = false
	end
end

function BuffExtensionBase:hot_join_sync(unit, sender, channel)
	ferror("Buff extension is using base implementation of hot_join_sync, it shouldn't")
end

function BuffExtensionBase:_update_buffs(dt, t)
	local buffs = self._buffs
	local portable_random = self._portable_random

	for i = 1, #buffs do
		buffs[i]:update(dt, t, portable_random)
	end

	for index, buff_instance in pairs(self._buffs_by_index) do
		local finished = buff_instance:finished()
		local should_remove_stack, last_stack = buff_instance:should_remove_stack()

		if finished or should_remove_stack then
			self:_remove_internally_controlled_buff(index)
		end

		if not last_stack and should_remove_stack then
			buff_instance:removed_stack_by_request()
		end
	end
end

function BuffExtensionBase:progressbar()
	local buffs = self._buffs

	for i = 1, #buffs do
		local buff = buffs[i]
		local progress_bar = buff:progressbar()

		if progress_bar then
			return progress_bar
		end
	end

	return nil
end

function BuffExtensionBase:_move_looping_sfx_sources(unit)
	local wwise_world = self._buff_context.wwise_world
	local active_wwise_node_sources = self._active_wwise_node_sources

	for attach_node, source in pairs(active_wwise_node_sources) do
		WwiseWorld_set_source_position(wwise_world, source.wwise_source_id, Unit_world_position(unit, attach_node))
	end
end

function BuffExtensionBase:_update_proc_events(t)
	local num_proc_events = self._num_proc_events

	if num_proc_events > 0 then
		local proc_events = self._proc_events
		local buffs = self._buffs
		local portable_random = self._portable_random
		local local_portable_random = self._local_portable_random
		local is_server = self._is_server

		for i = 1, #buffs do
			local buff = buffs[i]
			local is_predicted = buff:is_predicted()
			local force_prediction = buff:force_predicted_proc()

			if buff and buff.update_proc_events and (is_server or is_predicted or force_prediction) then
				local activated_proc = buff:update_proc_events(t, proc_events, num_proc_events, portable_random, local_portable_random)

				if activated_proc and is_server and not is_predicted then
					local server_index = self:_find_local_index(buff)
					local game_object_id = self._game_object_id

					Managers.state.game_session:send_rpc_clients("rpc_buff_proc_set_active_time", game_object_id, server_index, t)
				end
			end
		end

		table.clear(proc_events)

		self._num_proc_events = 0
	end

	for i = 1, self._param_table_index do
		table.clear(self._proc_event_param_tables[i])
	end

	self._param_table_index = 0

	table.clear(self._unique_frame_proc)
end

function BuffExtensionBase:_set_proc_active_start_time(index, activation_time)
	local buffs_by_index = self._buffs_by_index
	local buff_instance = buffs_by_index[index]

	if buff_instance and buff_instance.set_active_start_time then
		buff_instance:set_active_start_time(activation_time)
	end
end

function BuffExtensionBase:_reset_stat_buffs()
	local stat_buff_base_values = BuffSettings.stat_buff_type_base_values
	local current_stat_buffs = self._stat_buffs
	local stats_to_reset = current_stat_buffs._modified_stats

	for key in pairs(stats_to_reset) do
		current_stat_buffs[key] = stat_buff_base_values[key]
	end

	table.clear(stats_to_reset)
end

function BuffExtensionBase:_update_stat_buffs_and_keywords(t)
	self:_reset_stat_buffs()

	local keywords = self._keywords

	table.clear(keywords)

	local buffs = self._buffs
	local current_stat_buffs = self._stat_buffs

	for i = 1, #buffs do
		local buff = buffs[i]

		if buff then
			buff:update_stat_buffs(current_stat_buffs, t)
			buff:update_keywords(keywords, t)
		end
	end
end

function BuffExtensionBase:_check_keywords(template)
	local forbidden_keywords = template.forbidden_keywords

	if forbidden_keywords then
		for i = 1, #forbidden_keywords do
			local keyword = forbidden_keywords[i]

			if self:has_keyword(keyword) then
				return false
			end
		end
	end

	local required_keywords = template.required_keywords

	if required_keywords then
		for i = 1, #required_keywords do
			local keyword = required_keywords[i]

			if not self:has_keyword(keyword) then
				return false
			end
		end
	end

	return true
end

function BuffExtensionBase:_can_add_internally_controlled_buff(template, t)
	local can_add_buff = self:_is_valid_target(template)

	if not can_add_buff then
		return false
	end

	can_add_buff = self:_handle_unique_buffs(template)

	if not can_add_buff then
		return false
	end

	can_add_buff = self:_check_max_stacks_cap(template, t)

	if not can_add_buff then
		return false
	end

	can_add_buff = self:_check_keywords(template)

	if not can_add_buff then
		return false
	end

	return true
end

function BuffExtensionBase:add_internally_controlled_buff_with_stacks(template_name, number_of_stacks, t, ...)
	for i = 1, number_of_stacks do
		self:add_internally_controlled_buff(template_name, t, ...)
	end
end

function BuffExtensionBase:add_internally_controlled_buff(template_name, t, ...)
	ferror("Buff extension is using base implementation of add_internally_controlled_buff, it shouldn't")
end

function BuffExtensionBase:add_externally_controlled_buff(template_name, t, ...)
	ferror("Buff extension is using base implementation of add_externally_controlled_buff, it shouldn't")
end

function BuffExtensionBase:_add_rpc_synced_buff(template, t, ...)
	local index = self:_add_buff(template, t, ...)
	local game_object_id = self._game_object_id
	local template_name = template.name
	local buff_template_id = NetworkLookup.buff_templates[template_name]
	local buff_instance = self._buffs_by_index[index]
	local optional_lerp_value = buff_instance:buff_lerp_value()
	local optional_item_slot = buff_instance:item_slot_name()
	local optional_slot_id = optional_item_slot and NetworkLookup.player_inventory_slot_names[optional_item_slot]
	local optional_parent_buff_template = buff_instance.parent_buff_template and buff_instance:parent_buff_template()
	local optional_parent_buff_template_id = optional_parent_buff_template and NetworkLookup.buff_templates[optional_parent_buff_template]

	if game_object_id then
		Managers.state.game_session:send_rpc_clients("rpc_add_buff", game_object_id, buff_template_id, index, optional_lerp_value, optional_slot_id, optional_parent_buff_template_id)
	else
		local buff_added_before_game_object_cration = {
			buff_template_id = buff_template_id,
			index = index,
			optional_lerp_value = optional_lerp_value,
			optional_slot_id = optional_slot_id,
			optional_parent_buff_template_id = optional_parent_buff_template_id
		}
		local buffs_added_before_game_object_cration = self._buffs_added_before_game_object_creation
		buffs_added_before_game_object_cration[#buffs_added_before_game_object_cration + 1] = buff_added_before_game_object_cration
	end

	return index
end

function BuffExtensionBase:_next_local_index()
	local local_index = self._index + 1
	self._index = local_index

	return local_index
end

function BuffExtensionBase:_add_buff(template, t, ...)
	local local_index = self:_next_local_index()
	local template_name = template.name
	local can_stack = template.max_stacks and true or false
	local buff_instance = nil

	if can_stack then
		local existing_buff_instance = self._stacking_buffs[template_name]

		if existing_buff_instance then
			local previous_stack_count = existing_buff_instance:stack_count()

			existing_buff_instance:add_stack()

			if template.refresh_duration_on_stack then
				existing_buff_instance:set_start_time(t)
				existing_buff_instance:refresh_func(t, previous_stack_count)
			end

			buff_instance = existing_buff_instance
		end
	end

	if not buff_instance then
		local class_name = template.class_name
		local buff_class = BuffClasses[class_name]
		local buff_context = self._buff_context
		local buff_instance_id = self._buff_instance_id + 1
		buff_instance = buff_class:new(buff_context, template, t, buff_instance_id, ...)

		self:_start_fx(buff_instance_id, template)
		self:_on_add_buff(buff_instance)

		if can_stack then
			self._stacking_buffs[template_name] = buff_instance
		end

		self._buffs[#self._buffs + 1] = buff_instance
		self._buff_instance_id = buff_instance_id
	end

	self._buffs_by_index[local_index] = buff_instance

	return local_index
end

function BuffExtensionBase:is_valid_target(template_name)
	local template = BuffTemplates[template_name]

	return self:_is_valid_target(template)
end

function BuffExtensionBase:_is_valid_target(template)
	local buff_context = self._buff_context
	local is_player = buff_context.player and true or false
	local player_only = template.target == BUFF_TARGETS.player_only and is_player
	local minion_only = template.target == BUFF_TARGETS.minion_only and not is_player
	local any = template.target == nil or template.target == BUFF_TARGETS.any

	return player_only or minion_only or any
end

function BuffExtensionBase:_handle_unique_buffs(new_template)
	local can_add_buff = true
	local unique_buff_id = new_template.unique_buff_id

	if unique_buff_id then
		local buffs_by_index = self._buffs_by_index

		for index, buff_instance in pairs(buffs_by_index) do
			local template = buff_instance:template()
			local unique_id = template.unique_buff_id

			if unique_buff_id == unique_id then
				local new_buff_priority = new_template.unique_buff_priority
				local current_buff_priority = template.unique_buff_priority

				if not new_buff_priority or new_buff_priority <= current_buff_priority then
					self:_remove_internally_controlled_buff(index)

					break
				end

				can_add_buff = false

				break
			end
		end
	end

	return can_add_buff
end

function BuffExtensionBase:_check_max_stacks_cap(template, t)
	local max_stacks_cap = template.max_stacks_cap
	local template_name = template.name
	local buff_instance = self._stacking_buffs[template_name]

	if not max_stacks_cap or not buff_instance then
		return true
	end

	local stack_count = buff_instance:stack_count()

	if stack_count ~= max_stacks_cap then
		return true
	end

	if template.refresh_duration_on_stack then
		buff_instance:set_start_time(t)
	end

	local previous_stack_count = stack_count

	buff_instance:refresh_func(t, previous_stack_count)

	return false
end

function BuffExtensionBase:refresh_duration_of_stacking_buff(buff_name, t)
	local buff_instance = self._stacking_buffs[buff_name]

	buff_instance:set_start_time(t)
end

function BuffExtensionBase:current_stacks(buff_name)
	local buff_instance = self._stacking_buffs[buff_name]

	return buff_instance and buff_instance:stack_count() or 0
end

function BuffExtensionBase:remove_externally_controlled_buff(local_index)
	ferror("Buff extension is using base implementation of remove_externally_controlled_buff, it shouldn't")
end

function BuffExtensionBase:_remove_internally_controlled_buff(local_index)
	ferror("Buff extension is using base implementation of _remove_internally_controlled_buff, it shouldn't")
end

function BuffExtensionBase:_remove_rpc_synced_buff(index)
	local game_object_id = self._game_object_id

	self:_remove_buff(index)
	Managers.state.game_session:send_rpc_clients("rpc_remove_buff", game_object_id, index)
end

function BuffExtensionBase:_remove_buff(index)
	local buffs_by_index = self._buffs_by_index
	local buff_instance = buffs_by_index[index]

	if buff_instance.__deleted then
		Log.exception("BuffExtensionBase", "Tried removing buff that had already been deleted. %d", index)

		self._buffs_by_index[index] = nil

		return
	end

	local template = buff_instance:template()
	local current_stack_count = buff_instance:stack_count()

	if current_stack_count > 1 then
		buff_instance:remove_stack()
	else
		local can_stack = template.max_stacks and true or false

		if can_stack then
			local template_name = template.name
			self._stacking_buffs[template_name] = nil
		end

		local buffs = self._buffs
		local instance_index = nil

		for i = 1, #buffs do
			local instance = buffs[i]

			if instance == buff_instance then
				instance_index = i

				break
			end
		end

		local instance_id = buff_instance:instance_id()

		self:_stop_fx(instance_id, template)
		self:_on_remove_buff(buff_instance)
		table.remove(buffs, instance_index)
		buff_instance:delete()
		self:_post_on_remove_buff(buff_instance)
	end

	self._buffs_by_index[index] = nil
end

function BuffExtensionBase:_on_add_buff(buff_instance)
end

function BuffExtensionBase:_on_remove_buff(buff_instance)
end

function BuffExtensionBase:_post_on_remove_buff(buff_instance)
end

function BuffExtensionBase:has_buff_id(buff_id)
	local buffs = self._buffs

	for i = 1, #buffs do
		local buff_instance = buffs[i]
		local intance_template = buff_instance:template()
		local instance_buff_name = intance_template.buff_id

		if instance_buff_name == buff_id then
			return true
		end
	end

	return false
end

function BuffExtensionBase:has_unique_buff_id(unique_buff_id)
	local buffs = self._buffs

	for i = 1, #buffs do
		local buff_instance = buffs[i]
		local intance_template = buff_instance:template()
		local instance_buff_id = intance_template.unique_buff_id

		if instance_buff_id == unique_buff_id then
			return true
		end
	end

	return false
end

function BuffExtensionBase:has_buff_id_with_owner(buff_id, owner_unit)
	local buffs = self._buffs

	for i = 1, #buffs do
		local buff_instance = buffs[i]
		local intance_template = buff_instance:template()
		local instance_buff_name = intance_template.buff_id
		local buff_context = buff_instance:template_context()
		local buff_owner_unit = buff_context.owner_unit

		if instance_buff_name == buff_id and buff_owner_unit == owner_unit then
			return true
		end
	end

	return false
end

function BuffExtensionBase:has_keyword(keyword)
	return not not self._keywords[keyword]
end

function BuffExtensionBase:keywords()
	return self._keywords
end

function BuffExtensionBase:stat_buffs()
	return self._stat_buffs
end

function BuffExtensionBase:buffs()
	return self._buffs
end

function BuffExtensionBase:set_frame_unique_proc(event, unique_key)
	if not self._unique_frame_proc[event] then
		self._unique_frame_proc[event] = {}
	end

	self._unique_frame_proc[event][unique_key] = true
end

function BuffExtensionBase:is_frame_unique_proc(event, unique_key)
	return not self._unique_frame_proc[event] or not self._unique_frame_proc[event][unique_key]
end

function BuffExtensionBase:request_proc_event_param_table()
	local param_table_index = self._param_table_index + 1

	if MAX_PROC_EVENTS <= param_table_index then
		Log.warning("BuffExtensionBase", "Out of proc event tables, ignoring proc!")

		return nil
	end

	local param_table = self._proc_event_param_tables[param_table_index]

	if not param_table then
		param_table = Script.new_map(32)
		self._proc_event_param_tables[param_table_index] = param_table
	end

	self._param_table_index = param_table_index

	return param_table
end

function BuffExtensionBase:add_proc_event(event, params)
	local num_proc_events = self._num_proc_events
	local proc_events = self._proc_events
	proc_events[num_proc_events * PROC_EVENTS_STRIDE + 1] = event
	proc_events[num_proc_events * PROC_EVENTS_STRIDE + 2] = params
	self._num_proc_events = num_proc_events + 1
end

function BuffExtensionBase:_find_local_index(buff_instance)
	for local_index, indexed_buff_instance in pairs(self._buffs_by_index) do
		if indexed_buff_instance == buff_instance then
			return local_index
		end
	end

	return nil
end

function BuffExtensionBase:_start_fx(index, template)
	if not self._active_vfx[index] then
		self._active_vfx[index] = {}
	end

	local active_vfx = self._active_vfx[index]
	local shared_effects = template.effects

	if shared_effects then
		local node_effects = shared_effects.node_effects

		if node_effects then
			local buff_context = self._buff_context
			local world = buff_context.world
			local wwise_world = buff_context.wwise_world
			local unit = buff_context.unit

			self:_start_node_effects(node_effects, unit, world, wwise_world, active_vfx)
		end
	end
end

function BuffExtensionBase:_stop_fx(index, template)
	local buff_context = self._buff_context
	local world = buff_context.world
	local shared_effects = template.effects

	if shared_effects then
		local shared_node_effects = shared_effects.node_effects

		if shared_node_effects then
			self:_stop_node_effects(shared_node_effects)
		end
	end

	local active_vfx = self._active_vfx[index]

	for i = 1, #active_vfx do
		local effect = active_vfx[i]
		local particle_id = effect.particle_id
		local stop_type = effect.stop_type

		if stop_type == "stop" then
			World.stop_spawning_particles(world, particle_id)
		else
			World.destroy_particles(world, particle_id)
		end
	end

	table.clear(active_vfx)
end

function BuffExtensionBase:_start_node_effects(node_effects, unit, world, wwise_world, active_vfx)
	local active_wwise_node_sources = self._active_wwise_node_sources
	local num_effects = #node_effects

	for i = 1, num_effects do
		local effect = node_effects[i]
		local node_name = effect.node_name
		local attach_node = Unit.node(unit, node_name)
		local sfx = effect.sfx

		if sfx then
			if not active_wwise_node_sources[attach_node] then
				local position = Unit_world_position(unit, attach_node)
				local wwise_source_id = WwiseWorld.make_manual_source(wwise_world, position, Quaternion.identity())
				active_wwise_node_sources[attach_node] = {
					wwise_source_id = wwise_source_id,
					active_sfx_events = {}
				}
			end

			local active_node_source = active_wwise_node_sources[attach_node]
			local wwise_source_id = active_node_source.wwise_source_id
			local active_sfx_events = active_node_source.active_sfx_events
			local looping_wwise_start_event = sfx.looping_wwise_start_event
			local ref_count = active_sfx_events[looping_wwise_start_event]

			if not ref_count then
				WwiseWorld.trigger_resource_event(wwise_world, looping_wwise_start_event, wwise_source_id)
			end

			active_sfx_events[looping_wwise_start_event] = (ref_count or 0) + 1
		end

		local vfx = effect.vfx

		if vfx then
			local orphaned_policy = vfx.orphaned_policy or "destroy"
			local particle_effect = vfx.particle_effect
			local position = Unit_world_position(unit, attach_node)
			local effect_id = World.create_particles(world, particle_effect, position)

			if vfx.material_emission then
				local mesh_name_or_nil = vfx.emission_mesh_name
				local material_name_or_nil = vfx.emission_material_name
				local apply_for_children = true

				World.set_particles_surface_effect(world, effect_id, unit, mesh_name_or_nil, material_name_or_nil, apply_for_children)
			else
				World.link_particles(world, effect_id, unit, attach_node, Matrix4x4.identity(), orphaned_policy)
			end

			local stop_type = vfx.stop_type or "destroy"

			table.insert(active_vfx, {
				particle_id = effect_id,
				stop_type = stop_type
			})
		end
	end
end

function BuffExtensionBase:_stop_node_effects(node_effects)
	local buff_context = self._buff_context
	local wwise_world = buff_context.wwise_world

	for i = 1, #node_effects do
		local effect = node_effects[i]
		local sfx = effect.sfx

		if sfx then
			local node_name = effect.node_name
			local attach_node = Unit.node(self._unit, node_name)
			local active_node_source = self._active_wwise_node_sources[attach_node]
			local wwise_source_id = active_node_source.wwise_source_id
			local active_sfx_events = active_node_source.active_sfx_events
			local looping_wwise_start_event = sfx.looping_wwise_start_event
			local new_ref_count = active_sfx_events[looping_wwise_start_event] - 1
			active_sfx_events[looping_wwise_start_event] = new_ref_count

			if new_ref_count < 1 then
				local looping_wwise_stop_event = sfx.looping_wwise_stop_event

				WwiseWorld.trigger_resource_event(wwise_world, looping_wwise_stop_event, wwise_source_id)

				active_sfx_events[looping_wwise_start_event] = nil
			end

			if next(active_sfx_events) == nil then
				WwiseWorld.destroy_manual_source(wwise_world, wwise_source_id)

				self._active_wwise_node_sources[attach_node] = nil
			end
		end
	end
end

function BuffExtensionBase:rpc_add_buff(channel_id, game_object_id, buff_template_id, server_index, optional_lerp_value, optional_item_slot_id, optional_parent_buff_template_id)
	local template_name = NetworkLookup.buff_templates[buff_template_id]
	local template = BuffTemplates[template_name]
	local t = Managers.time:time("gameplay")
	local optional_item_slot_name = optional_item_slot_id and NetworkLookup.player_inventory_slot_names[optional_item_slot_id]
	local optional_parent_buff_template = optional_parent_buff_template_id and NetworkLookup.buff_templates[optional_parent_buff_template_id]
	local index = self:_add_buff(template, t, "buff_lerp_value", optional_lerp_value, "item_slot_name", optional_item_slot_name, "parent_buff_template", optional_parent_buff_template)
	self._buff_index_map[server_index] = index
end

function BuffExtensionBase:rpc_remove_buff(channel_id, game_object_id, server_index)
	local index = self._buff_index_map[server_index]

	self:_remove_buff(index)

	self._buff_index_map[server_index] = nil
end

function BuffExtensionBase:rpc_buff_proc_set_active_time(channel_id, game_object_id, server_index, activation_time)
	local index = self._buff_index_map[server_index]

	self:_set_proc_active_start_time(index, activation_time)
end

implements(BuffExtensionBase, BuffExtensionInterface)

return BuffExtensionBase
