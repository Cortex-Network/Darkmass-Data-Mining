local LevelProps = require("scripts/settings/level_prop/level_props")
local HealthStationExtension = class("HealthStationExtension")
HealthStationExtension.MAX_CHARGES = 4

function HealthStationExtension:init(extension_init_context, unit)
	self._unit = unit
	self._world = extension_init_context.world
	self._is_server = extension_init_context.is_server
	self._charge_amount = 0
	self._health_per_charge = 0
	self._use_distribution_pool = true
	self._socket_prop = ""
	self._luggable_socket_extension = nil
	self._pickup_spawner_extension = nil
	self._animation_extension = nil
	self._socket_unit = nil
	self._battery_unit = nil
	self._battery_spawning_mode = "none"
	self._first_frame_setup = false
	self._point_of_interest_extension = nil
	self._interactee_extension = nil
end

function HealthStationExtension:destroy()
	self:unspawn_battery()
	self:_unspawn_socket()
end

function HealthStationExtension:setup_from_component(start_charge_amount, health_per_charge, use_distribution_pool, socket_prop, battery_spawning_mode)
	local unit = self._unit
	self._use_distribution_pool = use_distribution_pool
	self._socket_prop = socket_prop
	self._battery_spawning_mode = battery_spawning_mode
	self._health_per_charge = health_per_charge
	self._animation_extension = ScriptUnit.extension(unit, "animation_system")
	self._pickup_spawner_extension = ScriptUnit.extension(unit, "pickup_system")
	self._point_of_interest_extension = ScriptUnit.extension(unit, "point_of_interest_system")
	self._interactee_extension = ScriptUnit.has_extension(unit, "interactee_system")
	self._dialogue_extension = ScriptUnit.extension(unit, "dialogue_system")

	if battery_spawning_mode == "plugged" and not use_distribution_pool then
		self:set_charge_amount(start_charge_amount)
	else
		self:set_charge_amount(0)
	end
end

function HealthStationExtension:hot_join_sync(charge_amount, socket_unit, battery_unit)
	if socket_unit then
		self:register_socket_unit(socket_unit)
	end

	if battery_unit then
		self:register_battery_unit(battery_unit)
	end

	self:set_charge_amount(charge_amount)
	self:sync_animations()
end

function HealthStationExtension:sync_animations()
	if not self:battery_in_slot() then
		return
	end

	local charges = self:charge_amount()

	if charges > 0 then
		Unit.flow_event(self._unit, "sfx_open_finish")
	else
		Unit.flow_event(self._unit, "sfx_close_finish")
	end
end

function HealthStationExtension:fixed_update(unit, dt, t)
	if self._is_server then
		self:_check_battery_alive()

		if not self._first_frame_setup then
			self:_spawn_socket()

			local battery_spawning_mode = self._battery_spawning_mode
			local should_plug_after_distribution = battery_spawning_mode == "plugged_with_charge" and self._use_distribution_pool and self._charge_amount > 0
			local should_plug = battery_spawning_mode == "pickup_location" or battery_spawning_mode == "plugged"

			if should_plug or should_plug_after_distribution then
				self:spawn_battery()

				if battery_spawning_mode == "plugged" or battery_spawning_mode == "plugged_with_charge" then
					self:_teleport_battery_to_socket()
					self:socket_luggable(self._battery_unit)
					self:_update_indicators()
				end
			end

			self._first_frame_setup = true
		elseif not self:battery_in_slot() then
			local socket_ext = self._luggable_socket_extension
			local has_overlap, luggable_unit = socket_ext:is_overlapping_with_luggable()

			if has_overlap then
				self:socket_luggable(luggable_unit)
			end
		end
	end
end

function HealthStationExtension:start_healing()
	self:play_anim("heal")
end

function HealthStationExtension:stop_healing(success)
	if success then
		self:use_charge()
	end

	if self._charge_amount == 1 then
		Unit.flow_event(self._unit, "one_charge_left")
	end

	if self._charge_amount == 0 then
		self:play_anim("close")
	else
		self:play_anim("idle")
	end
end

function HealthStationExtension:use_charge()
	local current_charge = self._charge_amount
	local new_charge = current_charge - 1
	new_charge = math.clamp(new_charge, 0, HealthStationExtension.MAX_CHARGES)

	if current_charge ~= new_charge then
		self:set_charge_amount(new_charge)

		if self._charge_amount <= 0 then
			self._point_of_interest_extension:set_tag("empty_health_station")
		end
	end

	if self._is_server then
		local station_level_id = Managers.state.unit_spawner:level_index(self._unit)
		local game_session_manager = Managers.state.game_session

		game_session_manager:send_rpc_clients("rpc_health_station_use", station_level_id)
	end
end

function HealthStationExtension:battery_in_slot()
	if self._luggable_socket_extension then
		return self._luggable_socket_extension:is_occupied()
	end

	return false
end

function HealthStationExtension:charge_amount()
	return self._charge_amount
end

function HealthStationExtension:use_distribution_pool()
	return self._use_distribution_pool
end

function HealthStationExtension:battery_spawning_mode()
	return self._battery_spawning_mode
end

function HealthStationExtension:max_amount_charges()
	return self._max_amount_charges
end

function HealthStationExtension:set_charge_amount(charges)
	self._charge_amount = charges

	self:_update_indicators()

	local point_of_interest_ext = self._point_of_interest_extension

	if self._charge_amount <= 0 then
		self:_set_block_text("loc_health_station_missing_battery")
		point_of_interest_ext:set_tag("chargeable_health_station")
	else
		self:_set_block_text(nil)
		point_of_interest_ext:set_tag("charged_health_station")
	end
end

function HealthStationExtension:_set_block_text(text)
	if self._interactee_extension then
		self._interactee_extension:set_block_text(text)
	end
end

function HealthStationExtension:play_anim(anim_event)
	self._animation_extension:anim_event(anim_event)
end

function HealthStationExtension:sync_charge_amount()
	local station_level_id = Managers.state.unit_spawner:level_index(self._unit)
	local game_session_manager = Managers.state.game_session

	game_session_manager:send_rpc_clients("rpc_health_station_sync_charges", station_level_id, self._charge_amount)
end

function HealthStationExtension:health_per_charge()
	return self._health_per_charge
end

function HealthStationExtension:_update_indicators()
	if not self:battery_in_slot() then
		Unit.set_scalar_for_materials(self._unit, "increase_color", -0.95)
	else
		local min_indicator_material = -1
		local max_indicator_material = 0.01
		local alpha = 1 - (HealthStationExtension.MAX_CHARGES - self._charge_amount) / HealthStationExtension.MAX_CHARGES
		local indicator_level = math.lerp(min_indicator_material, max_indicator_material, alpha)

		Unit.set_scalar_for_materials(self._unit, "increase_color", indicator_level)

		if self._charge_amount == 0 then
			Light.set_enabled(Unit.light(self._battery_unit, 1), false)
			Unit.set_scalar_for_materials(self._battery_unit, "emissive_multiplier", 0)
		end
	end
end

function HealthStationExtension:_spawn_socket()
	local unit = self._unit
	local socket_node = Unit.node(unit, "g_battery_socket")
	local socket_position = Unit.world_position(unit, socket_node)
	local socket_rotation = Unit.world_rotation(unit, socket_node)
	local socket_prop = self._socket_prop
	local props_settings = LevelProps[socket_prop]
	local socket_unit_name = props_settings.unit_name
	local unit_spawner_manager = Managers.state.unit_spawner
	local spawn_offset_boxed = props_settings.spawn_offset

	if spawn_offset_boxed then
		local spawn_offset = spawn_offset_boxed:unbox()
		local socket_pose = Unit.world_pose(unit, socket_node)
		socket_position = Matrix4x4.transform(socket_pose, spawn_offset)
	end

	local socket_unit, socket_unit_go_id = unit_spawner_manager:spawn_network_unit(socket_unit_name, "level_prop", socket_position, socket_rotation, nil, props_settings)

	self:register_socket_unit(socket_unit)

	local station_level_id = Managers.state.unit_spawner:level_index(self._unit)
	local game_session_manager = Managers.state.game_session

	game_session_manager:send_rpc_clients("rpc_health_station_on_socket_spawned", station_level_id, socket_unit_go_id)
end

function HealthStationExtension:_unspawn_socket()
	if self._is_server then
		local unit_spawner_manager = Managers.state.unit_spawner
		local socket_unit = self._socket_unit

		if socket_unit then
			unit_spawner_manager:mark_for_deletion(socket_unit)
		end
	end
end

function HealthStationExtension:socket_unit()
	return self._socket_unit
end

function HealthStationExtension:socket_luggable(luggable_unit)
	self._luggable_socket_extension:socket_luggable(luggable_unit)

	local battery_spawning_mode = self._battery_spawning_mode
	local has_plugged_after_distribution = battery_spawning_mode == "plugged_with_charge" and self._use_distribution_pool and self._charge_amount > 0

	if battery_spawning_mode ~= "plugged" and not has_plugged_after_distribution then
		self:set_charge_amount(HealthStationExtension.MAX_CHARGES)
		self:sync_charge_amount()
	end

	local charges = self:charge_amount()

	if charges > 0 then
		Managers.event:trigger("on_health_station_activated")
		self:play_anim("open")
	end
end

function HealthStationExtension:battery_unit()
	return self._battery_unit
end

function HealthStationExtension:spawn_battery()
	if self._is_server and self._battery_unit == nil then
		local battery_unit, battery_id = self._pickup_spawner_extension:spawn_item()
		local battery_is_level_unit = false

		self:register_battery_unit(battery_unit)

		local point_of_interest_ext = self._point_of_interest_extension

		if self._charge_amount <= 0 then
			point_of_interest_ext:set_tag("chargeable_health_station")
		else
			point_of_interest_ext:set_tag("charged_health_station")
		end

		local station_level_id = Managers.state.unit_spawner:level_index(self._unit)
		local game_session_manager = Managers.state.game_session

		game_session_manager:send_rpc_clients("rpc_health_station_on_battery_spawned", station_level_id, battery_id, battery_is_level_unit)
	end
end

function HealthStationExtension:unspawn_battery()
	if self._is_server then
		self:_check_battery_alive()

		if self._battery_unit ~= nil then
			local battery_unit = self._battery_unit

			self._pickup_spawner_extension:unspawn_item(battery_unit)

			self._battery_unit = nil
		end
	end
end

function HealthStationExtension:_check_battery_alive()
	if self._battery_unit ~= nil and not ALIVE[self._battery_unit] then
		self._battery_unit = nil
	end
end

function HealthStationExtension:_teleport_battery_to_socket()
	local unit = self._unit
	local socket_node = Unit.node(unit, "g_battery_socket")
	local socket_position = Unit.world_position(unit, socket_node)
	local socket_rotation = Unit.world_rotation(unit, socket_node)
	local battery_unit = self._battery_unit
	local battery_locomotion_ext = ScriptUnit.extension(battery_unit, "locomotion_system")

	battery_locomotion_ext:switch_to_sleep(socket_position, socket_rotation)
end

function HealthStationExtension:register_socket_unit(socket_unit)
	self._socket_unit = socket_unit
	self._luggable_socket_extension = ScriptUnit.extension(socket_unit, "luggable_socket_system")
end

function HealthStationExtension:register_battery_unit(battery_unit)
	self._battery_unit = battery_unit
end

return HealthStationExtension
