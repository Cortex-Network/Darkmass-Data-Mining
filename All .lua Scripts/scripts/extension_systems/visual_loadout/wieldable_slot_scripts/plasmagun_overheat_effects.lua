local PlayerCharacterLoopingSoundAliases = require("scripts/settings/sound/player_character_looping_sound_aliases")
local PlasmagunOverheatEffects = class("PlasmagunOverheatEffects")
local SFX_ALIAS = "weapon_overload"
local LOOPING_SFX_ALIAS = "weapon_overload_loop"
local LOOPING_VFX_ALIAS = "weapon_overload_loop"
local LOOPING_SFX_CONFIG = PlayerCharacterLoopingSoundAliases[LOOPING_SFX_ALIAS]
local vfx_external_properties = {}
local sfx_external_properties = {}

function PlasmagunOverheatEffects:init(context, slot, weapon_template, fx_sources)
	local wwise_world = context.wwise_world
	local owner_unit = context.owner_unit
	local unit_data_extension = context.unit_data_extension
	local fx_extension = context.fx_extension
	local visual_loadout_extension = context.visual_loadout_extension
	local overheat_configuration = weapon_template.overheat_configuration
	local overheat_fx = overheat_configuration.fx
	self._owner_unit = owner_unit
	self._is_husk = context.is_husk
	self._is_local_unit = context.is_local_unit
	self._slot = slot
	self._world = context.world
	self._wwise_world = wwise_world
	self._fx_extension = fx_extension
	self._visual_loadout_extension = visual_loadout_extension
	self._inventory_slot_component = unit_data_extension:read_component(slot.name)
	self._overheat_configuration = overheat_configuration
	local vfx_source_name = fx_sources[overheat_fx.vfx_source_name]
	self._vfx_link_unit, self._vfx_link_node = fx_extension:vfx_spawner_unit_and_node(vfx_source_name)
	self._looping_low_threshold_vfx_name = overheat_fx.looping_low_threshold_vfx
	self._looping_high_threshold_vfx_name = overheat_fx.looping_high_threshold_vfx
	self._looping_critical_threshold_vfx_name = overheat_fx.looping_critical_threshold_vfx
	self._vfx_threshold_effect_ids = {}
	self._sfx_threshold_stages = {}
	self._looping_playing_ids = {}
	self._looping_stop_events = {}
	local sfx_source_name = fx_sources[overheat_fx.sfx_source_name]
	local sfx_link_unit, sfx_link_node = fx_extension:sfx_spawner_unit_and_node(sfx_source_name)
	self._sfx_source_id = WwiseWorld.make_manual_source(wwise_world, sfx_link_unit, sfx_link_node)
	self._looping_sound_parameter_name = overheat_fx.looping_sound_parameter_name
	self._looping_playing_id = nil
	self._looping_critical_playing_id = nil
	self._material_variable_name = overheat_fx.material_variable_name
	self._material_name = overheat_fx.material_name
	self._on_screen_effect = overheat_fx.on_screen_effect
	self._on_screen_cloud_name = overheat_fx.on_screen_cloud_name
	self._on_screen_variable_name = overheat_fx.on_screen_variable_name
	self._on_screen_effect_id = nil
end

function PlasmagunOverheatEffects:destroy()
	WwiseWorld.set_source_parameter(self._wwise_world, self._sfx_source_id, self._looping_sound_parameter_name, 0)
	self:_destroy_all_vfx()
	self:_stop_looping_sfx()
	self:_destroy_screenspace()
end

function PlasmagunOverheatEffects:fixed_update(unit, dt, t, frame)
end

function PlasmagunOverheatEffects:update(unit, dt, t)
	local inventory_slot_component = self._inventory_slot_component
	local overheat_percentage = inventory_slot_component.overheat_current_percentage
	local overheat_configuration = self._overheat_configuration

	self:_update_vfx(overheat_configuration, overheat_percentage)
	self:_update_threshold_sfx(overheat_configuration, overheat_percentage)
	self:_update_looping_sfx(overheat_configuration, overheat_percentage)
	self:_update_material(overheat_percentage)
	self:_update_screenspace(overheat_percentage)
end

function PlasmagunOverheatEffects:_update_vfx(overheat_configuration, overheat_percentage)
	local world = self._world
	local vfx_link_unit = self._vfx_link_unit
	local vfx_link_node = self._vfx_link_node
	local threshold_effect_ids = self._vfx_threshold_effect_ids
	local visual_loadout_extension = self._visual_loadout_extension

	for stage, threshold in pairs(overheat_configuration.thresholds) do
		local current_effect_id = threshold_effect_ids[stage]
		local was_above_threshold = not not current_effect_id
		local is_above_threshold = threshold < overheat_percentage

		if is_above_threshold and not was_above_threshold then
			vfx_external_properties.stage = stage
			local resolved, effect_name = visual_loadout_extension:resolve_gear_particle(LOOPING_VFX_ALIAS, vfx_external_properties)

			if resolved then
				local new_effect_id = World.create_particles(world, effect_name, Vector3.zero())

				World.link_particles(world, new_effect_id, vfx_link_unit, vfx_link_node, Matrix4x4.identity(), "stop")

				threshold_effect_ids[stage] = new_effect_id
			end
		elseif was_above_threshold and not is_above_threshold then
			World.stop_spawning_particles(world, current_effect_id)

			threshold_effect_ids[stage] = nil
		end
	end
end

function PlasmagunOverheatEffects:_update_threshold_sfx(overheat_configuration, overheat_percentage)
	local is_husk = self._is_husk
	local is_local_unit = self._is_local_unit
	local wwise_world = self._wwise_world
	local sfx_source_id = self._sfx_source_id
	local threshold_stages = self._sfx_threshold_stages
	local visual_loadout_extension = self._visual_loadout_extension
	local use_husk_event = is_husk or not is_local_unit

	for stage, threshold in pairs(overheat_configuration.thresholds) do
		local was_above_threshold = not not threshold_stages[stage]
		local is_above_threshold = threshold < overheat_percentage

		if not was_above_threshold and is_above_threshold then
			sfx_external_properties.stage = stage
			local resolved, event_name, has_husk_events = visual_loadout_extension:resolve_gear_sound(SFX_ALIAS, sfx_external_properties)

			if resolved then
				if use_husk_event and has_husk_events then
					event_name = event_name .. "_husk" or event_name
				end

				WwiseWorld.trigger_resource_event(wwise_world, event_name, sfx_source_id)
			end
		end

		threshold_stages[stage] = is_above_threshold
	end
end

function PlasmagunOverheatEffects:_update_looping_sfx(overheat_configuration, overheat_percentage)
	local wwise_world = self._wwise_world
	local sfx_source_id = self._sfx_source_id
	local critical_threshold = overheat_configuration.thresholds.critical

	self:_update_sfx_loop(overheat_percentage, "base", 0)
	self:_update_sfx_loop(overheat_percentage, "critical", critical_threshold)
	WwiseWorld.set_source_parameter(wwise_world, sfx_source_id, self._looping_sound_parameter_name, overheat_percentage)
end

function PlasmagunOverheatEffects:_update_sfx_loop(overheat_percentage, stage, threshold)
	local current_playing_id = self._looping_playing_ids[stage]
	local should_play = not current_playing_id and threshold < overheat_percentage
	local should_stop = current_playing_id and overheat_percentage <= threshold

	if should_play then
		self:_start_sfx_loop(stage)
	elseif should_stop and current_playing_id then
		self:_stop_sfx_loop(stage)
	end
end

function PlasmagunOverheatEffects:_update_material(overheat_percentage)
	local material_variable_name = self._material_variable_name
	local material_name = self._material_name
	local slot = self._slot
	local attachments_1p = slot.attachments_1p
	local attachments_3p = slot.attachments_3p

	for i = 1, #attachments_1p do
		local attachment_unit = attachments_1p[i]

		Unit.set_scalar_for_material(attachment_unit, material_name, material_variable_name, math.lerp(0, 0.2, overheat_percentage))
	end

	for i = 1, #attachments_3p do
		local attachment_unit = attachments_3p[i]

		Unit.set_scalar_for_material(attachment_unit, material_name, material_variable_name, math.lerp(0, 0.2, overheat_percentage))
	end
end

function PlasmagunOverheatEffects:_update_screenspace(overheat_percentage)
	local overheat_configuration = self._overheat_configuration
	local low_threshold = overheat_configuration.thresholds.low

	if self._is_local_unit and not self._on_screen_effect_id and low_threshold < overheat_percentage then
		self._on_screen_effect_id = World.create_particles(self._world, self._on_screen_effect, Vector3(0, 0, 1))
	elseif self._on_screen_effect_id and overheat_percentage <= low_threshold then
		World.destroy_particles(self._world, self._on_screen_effect_id)

		self._on_screen_effect_id = nil
	end

	if self._on_screen_effect_id and self._on_screen_cloud_name and self._on_screen_variable_name then
		local scalar = overheat_percentage * 0.9

		World.set_particles_material_scalar(self._world, self._on_screen_effect_id, self._on_screen_cloud_name, self._on_screen_variable_name, scalar)
	end
end

function PlasmagunOverheatEffects:_destroy_all_vfx()
	local world = self._world
	local vfx_threshold_effect_ids = self._vfx_threshold_effect_ids

	for _, effect_id in pairs(vfx_threshold_effect_ids) do
		World.destroy_particles(world, effect_id)
	end

	table.clear(vfx_threshold_effect_ids)
end

function PlasmagunOverheatEffects:_stop_looping_sfx()
	self:_stop_sfx_loop("base")
	self:_stop_sfx_loop("critical")
end

function PlasmagunOverheatEffects:_destroy_screenspace()
	if self._on_screen_effect_id then
		World.destroy_particles(self._world, self._on_screen_effect_id)
	end

	self._on_screen_effect_id = nil
end

function PlasmagunOverheatEffects:update_first_person_mode(first_person_mode)
end

function PlasmagunOverheatEffects:wield()
end

function PlasmagunOverheatEffects:unwield()
	WwiseWorld.set_source_parameter(self._wwise_world, self._sfx_source_id, self._looping_sound_parameter_name, 0)
	self:_destroy_all_vfx()
	self:_stop_looping_sfx()
	self:_destroy_screenspace()
end

function PlasmagunOverheatEffects:_start_sfx_loop(stage)
	local is_husk = self._is_husk
	local is_local_unit = self._is_local_unit
	local wwise_world = self._wwise_world
	local sfx_source_id = self._sfx_source_id
	local visual_loadout_extension = self._visual_loadout_extension
	local use_husk_event = is_husk or not is_local_unit
	local start_config = LOOPING_SFX_CONFIG.start
	local stop_config = LOOPING_SFX_CONFIG.stop
	local start_event_alias = start_config.event_alias
	local stop_event_alias = stop_config.event_alias
	local resolved, has_husk_events, event_name = nil
	sfx_external_properties.stage = stage
	resolved, event_name, has_husk_events = visual_loadout_extension:resolve_gear_sound(start_event_alias, sfx_external_properties)

	if resolved then
		if use_husk_event and has_husk_events then
			event_name = event_name .. "_husk" or event_name
		end

		local new_playing_id = WwiseWorld.trigger_resource_event(wwise_world, event_name, sfx_source_id)
		self._looping_playing_ids[stage] = new_playing_id
		resolved, event_name, has_husk_events = visual_loadout_extension:resolve_gear_sound(stop_event_alias, sfx_external_properties)

		if resolved then
			if use_husk_event and has_husk_events then
				event_name = event_name .. "_husk" or event_name
			end

			self._looping_stop_events[stage] = event_name
		end
	end
end

function PlasmagunOverheatEffects:_stop_sfx_loop(stage)
	local wwise_world = self._wwise_world
	local sfx_source_id = self._sfx_source_id
	local current_playing_id = self._looping_playing_ids[stage]
	local stop_event_name = self._looping_stop_events[stage]

	if stop_event_name and sfx_source_id then
		WwiseWorld.trigger_resource_event(wwise_world, stop_event_name, sfx_source_id)
	else
		WwiseWorld.stop_event(wwise_world, current_playing_id)
	end

	self._looping_playing_ids[stage] = nil
	self._looping_stop_events[stage] = nil
end

return PlasmagunOverheatEffects
