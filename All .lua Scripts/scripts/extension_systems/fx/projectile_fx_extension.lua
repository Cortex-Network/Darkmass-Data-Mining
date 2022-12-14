local ImpactEffect = require("scripts/utilities/attack/impact_effect")
local NetworkLookup = require("scripts/network_lookup/network_lookup")
local ProjectileLocomotionSettings = require("scripts/settings/projectile_locomotion/projectile_locomotion_settings")
local ProjectileTemplates = require("scripts/settings/projectile/projectile_templates")
local SurfaceMaterialSettings = require("scripts/settings/surface_material_settings")
local locomotion_states = ProjectileLocomotionSettings.states
local surface_hit_types = SurfaceMaterialSettings.hit_types
local WWISE_PARAMETER_NAME_SPEED = "projectile_speed"
local SYNC_EFFECT = {
	impact = true,
	build_up_start = true,
	build_up_stop = true,
	stick = true,
	fuse = true,
	spawn = false
}
local ProjectileFxExtension = class("ProjectileFxExtension")

function ProjectileFxExtension:init(extension_init_context, unit, extension_init_data, game_object_data_or_game_session, nil_or_game_object_id)
	local wwise_world = extension_init_context.wwise_world
	local is_server = extension_init_context.is_server
	self._world = extension_init_context.world
	self._physics_world = World.physics_world(self._world)
	self._wwise_world = wwise_world
	self._is_server = is_server
	self._charge_level = extension_init_data.charge_level
	local projectile_template_name = extension_init_data.projectile_template_name
	local projectile_template = ProjectileTemplates[projectile_template_name]
	local effects = projectile_template.effects
	self._projectile_template = projectile_template
	self._effects = effects
	self._unit = unit
	self._life_time = 0
	self._life_times = {}
	self._looping_playing_ids = {}
	self._effect_ids = {}
	self._source_id = WwiseWorld.make_manual_source(wwise_world, unit)
	self._speed_parameter_value = 0
end

function ProjectileFxExtension:extensions_ready(world, unit)
	local locomotion_extension = ScriptUnit.extension(unit, "locomotion_system")
	self._locomotion_extension = locomotion_extension
	local effects = self._effects

	if effects and effects.spawn then
		local locomotion_state = locomotion_extension:current_state()

		if locomotion_state == locomotion_states.sleep then
			self._wait_with_spawn_effects_until_not_sleeping = true
		else
			self:start_fx("spawn")

			self._life_times.spawn = 0
		end
	end
end

function ProjectileFxExtension:game_object_initialized(session, id)
	self._game_object_id = id
end

function ProjectileFxExtension:destroy()
	if self._source_id then
		for effect_type, settings in pairs(self._effects) do
			local sfx = settings.sfx

			if sfx then
				local source_id = self._source_id
				local playing_id = self._looping_playing_ids[effect_type]
				local stop_event_name = sfx.looping_stop_event_name

				if playing_id and WwiseWorld.is_playing(self._wwise_world, playing_id) then
					if stop_event_name then
						WwiseWorld.trigger_resource_event(self._wwise_world, stop_event_name, source_id)
					else
						WwiseWorld.stop_event(self._wwise_world, playing_id)
					end

					self._looping_playing_ids[effect_type] = nil
				end
			end
		end

		WwiseWorld.destroy_manual_source(self._wwise_world, self._source_id)

		self._source_id = nil
	end
end

function ProjectileFxExtension:update(unit, dt, t)
	local effects = self._effects

	if not effects then
		return
	end

	if self._wait_with_spawn_effects_until_not_sleeping then
		self:_handle_spawn_effects_waiting()
	end

	for effect_type, settings in pairs(effects) do
		local life_time = self._life_times[effect_type]

		if life_time then
			life_time = life_time + dt
			self._life_times[effect_type] = life_time
		end

		local sfx = settings.sfx

		if sfx then
			local source_id = self._source_id
			local playing_id = self._looping_playing_ids[effect_type]
			local looping_stop_time = sfx.looping_stop_time
			local stop_event_name = sfx.looping_stop_event_name

			if playing_id and WwiseWorld.is_playing(self._wwise_world, playing_id) then
				if looping_stop_time and looping_stop_time <= life_time then
					if stop_event_name then
						WwiseWorld.trigger_resource_event(self._wwise_world, stop_event_name, source_id)
					end

					self._looping_playing_ids[effect_type] = nil
				end
			else
				self._looping_playing_ids[effect_type] = nil
			end
		end
	end
end

function ProjectileFxExtension:_handle_spawn_effects_waiting()
	local locomotion_state = self._locomotion_extension:current_state()

	if locomotion_state == locomotion_states.sleep then
		return
	end

	self:start_fx("spawn")

	self._life_times.spawn = 0
	self._wait_with_spawn_effects_until_not_sleeping = nil
end

local IMPACT_FX_DATA = {}

function ProjectileFxExtension:on_impact(hit_position, hit_actor, hit_direction, hit_normal, current_speed)
	local is_server = self._is_server
	local effects = self._effects
	local impact_fx = effects and effects.impact

	if impact_fx and not self._has_impacted then
		self:start_fx("impact")

		self._life_times.impact = 0
	end

	local impact_damage_type = self._projectile_template.impact_damage_type
	local hit_unit = Actor.unit(hit_actor)

	if is_server and impact_damage_type and not HEALTH_ALIVE[hit_unit] then
		local attacker_unit = self._unit

		ImpactEffect.play_surface_effect(self._physics_world, attacker_unit, hit_position, hit_normal, hit_direction, impact_damage_type, surface_hit_types.stop, IMPACT_FX_DATA)
	end

	self._has_impacted = true
end

function ProjectileFxExtension:on_fuse_started()
	self._fuse_started = true
	local effects = self._effects

	if effects and effects.fuse then
		self:start_fx("fuse")

		self._life_times.fuse = 0
	end
end

function ProjectileFxExtension:on_target_aquired()
	local effects = self._effects

	if effects and effects.target_aquired then
		self:start_fx("target_aquired")
	end
end

function ProjectileFxExtension:on_stick()
	local effects = self._effects

	if effects and effects.stick then
		self:start_fx("stick")
	end
end

function ProjectileFxExtension:on_build_up_start()
	local effects = self._effects

	if effects and effects.build_up_start then
		self:start_fx("build_up_start")
	end
end

function ProjectileFxExtension:on_build_up_stop()
	local effects = self._effects

	if effects and effects.build_up_stop then
		self:start_fx("build_up_stop")
	end
end

function ProjectileFxExtension:on_cluster()
	local effects = self._effects

	if effects and effects.cluster then
		self:start_fx("cluster")
	end
end

function ProjectileFxExtension:start_fx(effect_type)
	local effects = self._effects[effect_type]
	local sfx = effects.sfx
	local vfx = effects.vfx

	if sfx then
		local wwise_world = self._wwise_world
		local source_id = self._source_id
		local looping_event_name = sfx.looping_event_name

		if looping_event_name then
			local playing_id = WwiseWorld.trigger_resource_event(wwise_world, looping_event_name, source_id)
			self._looping_playing_ids[effect_type] = playing_id
		end

		local event_name = sfx.event_name

		if event_name then
			WwiseWorld.trigger_resource_event(wwise_world, event_name, source_id)
		end
	end

	if vfx then
		local world = self._world
		local unit = self._unit
		local particle_name = vfx.particle_name

		if particle_name then
			local node_name = vfx.node_name
			local node_index = node_name and Unit.node(unit, node_name) or 1
			local position = Unit.world_position(unit, node_index)
			local rotation = Quaternion.identity()
			local effect_id = World.create_particles(world, particle_name, position, rotation)
			self._effect_ids[effect_type] = effect_id

			if vfx.link then
				local orphaned_policy = vfx.orphaned_policy
				local pose = Matrix4x4.identity()

				World.link_particles(world, effect_id, unit, node_index, pose, orphaned_policy)
			end

			if vfx.use_charge_level then
				local charge_level = self._charge_level
				local start_charge_level = vfx.min_charge_level or 0
				local max_charge_level = vfx.max_charge_level or 1
				local dif = max_charge_level - start_charge_level
				local fraction = charge_level * dif
				local variable_charge_level = start_charge_level + fraction
				local variable_index = World.find_particles_variable(self._world, particle_name, "charge_level")

				World.set_particles_variable(world, effect_id, variable_index, Vector3(variable_charge_level, variable_charge_level, variable_charge_level))
			end
		end

		local set_group_invisible = vfx.set_group_invisible

		if set_group_invisible then
			Unit.set_visibility(unit, set_group_invisible, false)
		end
	end

	if self._is_server and self._game_object_id then
		local should_sync = SYNC_EFFECT[effect_type]

		if should_sync then
			local effect_type_id = NetworkLookup.projectile_template_effects[effect_type]

			Managers.state.game_session:send_rpc_clients("rpc_projectile_trigger_fx", self._game_object_id, effect_type_id)
		end
	end
end

function ProjectileFxExtension:_stop_fx(effect_type)
	local effects = self._effects[effect_type]
	local sfx = effects.sfx
	local playing_id = self._looping_playing_ids[effect_type]

	if playing_id and WwiseWorld.is_playing(self._wwise_world, playing_id) then
		local stop_event_name = sfx and sfx.looping_stop_event_name

		if stop_event_name then
			local source_id = self._source_id

			WwiseWorld.trigger_resource_event(self._wwise_world, stop_event_name, source_id)
		else
			WwiseWorld.stop_event(self._wwise_world, playing_id)
		end

		self._looping_playing_ids[effect_type] = nil
	end

	local particle_id = self._effect_ids[effect_type]

	if particle_id then
		World.destroy_particles(self._world, particle_id)

		self._effect_ids[effect_type] = nil
	end
end

function ProjectileFxExtension:start_and_link_vfx(effect_name, orphaned_policy)
	local unit = self._unit
	local world = self._world
	local node_index = 1
	local position = Unit.world_position(unit, node_index)
	local rotation = Unit.world_rotation(unit, node_index)
	local scale = Vector3.one()
	local effect_id = World.create_particles(world, effect_name, position, rotation, scale)
	local pose = Matrix4x4.identity()

	World.link_particles(world, effect_id, unit, node_index, pose, orphaned_policy)

	return effect_id
end

function ProjectileFxExtension:play_one_off_sound(sound_name)
	local unit = self._unit
	local fx_system = Managers.state.extension:system("fx_system")

	fx_system:trigger_wwise_event(sound_name, nil, unit)
end

local PARAMETER_RESOLUTION = 0.01

function ProjectileFxExtension:set_speed_paramater(speed)
	local prev_speed = self._speed_parameter_value
	local delta = math.abs(prev_speed - speed)

	if PARAMETER_RESOLUTION < delta then
		self._speed_parameter_value = speed

		WwiseWorld.set_source_parameter(self._wwise_world, self._source_id, WWISE_PARAMETER_NAME_SPEED, speed)
	end
end

function ProjectileFxExtension:should_play_husk_effect()
	return false
end

return ProjectileFxExtension
