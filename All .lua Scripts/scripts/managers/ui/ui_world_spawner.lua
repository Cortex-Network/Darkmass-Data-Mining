local ScriptWorld = require("scripts/foundation/utilities/script_world")
local ScriptViewport = require("scripts/foundation/utilities/script_viewport")
local UIUnitSpawner = require("scripts/managers/ui/ui_unit_spawner")
local ExtensionManager = require("scripts/foundation/managers/extension/extension_manager")
local WorldRenderUtils = require("scripts/utilities/world_render")
local VOSourcesCache = require("scripts/extension_systems/dialogue/vo_sources_cache")
local UIWorldSpawner = class("UIWorldSpawner")

function UIWorldSpawner:init(world_name, world_layer, timer_name, optional_view_name)
	self._world_name = world_name
	local world = self:_create_world(world_name, world_layer, timer_name, optional_view_name)
	self._storyteller = World.storyteller(world)

	World.set_data(world, "__world_name", world_name)
	World.set_data(world, "__is_ui_world", true)

	self._unit_spawner = UIUnitSpawner:new(world)
	self._world = world
	self._default_animation_data = {
		x = {
			value = 0
		},
		y = {
			value = 0
		},
		z = {
			value = 0
		}
	}
	self._camera_rotation_animation_data = table.clone(self._default_animation_data)
	self._camera_position_animation_data = table.clone(self._default_animation_data)
end

function UIWorldSpawner:play_story(story_name, start_time, play_backwards)
	if self:is_playing_story() then
		self:stop_active_story()
	end

	local level = self._level
	local storyteller = self._storyteller
	local story_id = storyteller:play_level_story(level, story_name)
	self._active_story_id = story_id

	if start_time then
		storyteller:set_time(story_id, start_time)
	end

	if play_backwards then
		local length = storyteller:length(story_id)

		if not start_time then
			storyteller:set_time(story_id, length)
		end

		storyteller:set_speed(story_id, -1)
	end

	return story_id
end

function UIWorldSpawner:story_time(story_id)
	return self._storyteller:time(story_id)
end

function UIWorldSpawner:story_length_by_name(story_name)
	return self._storyteller:length_from_name(story_name)
end

function UIWorldSpawner:stop_story(story_id)
	self._storyteller:stop(story_id)

	self._active_story_id = nil

	return story_id
end

function UIWorldSpawner:stop_active_story()
	if self:is_playing_story() then
		self._storyteller:stop(self._active_story_id)

		self._active_story_id = nil
	end
end

function UIWorldSpawner:active_story_id()
	if self:is_playing_story() then
		return self._active_story_id
	end
end

function UIWorldSpawner:is_playing_story()
	if self._active_story_id then
		local active = self._storyteller:is_playing(self._active_story_id)

		if not active then
			self._active_story_id = nil
		end

		return active
	end

	return false
end

function UIWorldSpawner:spawn_level(level_name, object_sets, position, rotation, ignore_level_background)
	self._level_name = level_name
	local world = self._world
	local spawn_units = true

	self:_setup_extension_manager()

	local level = ScriptWorld.spawn_level(world, level_name, object_sets, position, rotation, spawn_units, ignore_level_background)
	self._level = level
	local level_units = Level.units(level, true)
	local category_name = "level_spawned"

	self._extension_manager:add_and_register_units(world, level_units, nil, category_name)
	Level.trigger_level_spawned(level)
	self._extension_manager:on_gameplay_post_init(level)
end

function UIWorldSpawner:level()
	return self._level
end

function UIWorldSpawner:world()
	return self._world
end

function UIWorldSpawner:world_name()
	return self._world_name
end

function UIWorldSpawner:unit_spawner()
	return self._unit_spawner
end

function UIWorldSpawner:camera()
	return self._camera
end

function UIWorldSpawner:camera_unit()
	local camera = self._camera
	local camera_unit = Camera.get_data(camera, "unit")

	return camera_unit
end

function UIWorldSpawner:_setup_extension_manager()
	local world = self._world
	local physics_world = World.physics_world(world)
	local wwise_world = Managers.world:wwise_world(world)
	local level_name = self._level_name
	local is_server = nil
	local unit_templates = require("scripts/extension_systems/unit_templates")

	require("scripts/extension_systems/cinematic_scene/cinematic_scene_system")
	require("scripts/extension_systems/cutscene_character/cutscene_character_system")
	require("scripts/extension_systems/component/component_extension")
	require("scripts/extension_systems/component/component_system")
	require("scripts/extension_systems/dialogue/dialogue_context_system")
	require("scripts/extension_systems/dialogue/dialogue_system")
	require("scripts/extension_systems/light_controller/light_controller_system")

	local system_config = {
		{
			"component_system",
			"ComponentSystem",
			false,
			false,
			false,
			true,
			false,
			{
				"ComponentExtension"
			}
		},
		{
			"dialogue_system",
			"DialogueSystem",
			false,
			false,
			true,
			true,
			false
		},
		{
			"dialogue_context_system",
			"DialogueContextSystem",
			false,
			false,
			false,
			true,
			false
		},
		{
			"cutscene_character_system",
			"CutsceneCharacterSystem",
			false,
			false,
			false,
			true,
			false,
			{
				"CutsceneCharacterExtension"
			}
		},
		{
			"cinematic_scene_system",
			"CinematicSceneSystem",
			false,
			false,
			false,
			true,
			false,
			{
				"CinematicSceneExtension"
			}
		},
		{
			"light_controller_system",
			"LightControllerSystem",
			false,
			false,
			false,
			true,
			false,
			{
				"LightControllerExtension"
			}
		}
	}
	local vo_sources_cache = VOSourcesCache:new()
	local system_init_data = {
		dialogue_context_system = {},
		dialogue_system = {
			is_rule_db_enabled = false,
			vo_sources_cache = vo_sources_cache
		},
		cinematic_scene_system = {
			mission = {}
		},
		light_controller_system = {
			mission = {}
		}
	}
	local unit_categories = {
		"flow_spawned",
		"level_spawned",
		"cinematic"
	}
	local circumstance_name = "default"
	local use_time_slice = false
	self._extension_manager = ExtensionManager:new(world, physics_world, wwise_world, nil, , level_name, circumstance_name, is_server, unit_templates, system_config, system_init_data, unit_categories, nil, , , {}, use_time_slice)

	Managers.ui:register_world_extension_manager_lookup(world, self._extension_manager)
end

function UIWorldSpawner:_create_world(world_name, layer, timer_name, optional_view_name, optional_flags)
	if not optional_flags then
		local flags = {
			Application.ENABLE_MOC,
			Application.ENABLE_VOLUMETRICS
		}
	end

	local ui_manager = Managers.ui
	local world = ui_manager:create_world(world_name, layer, timer_name, optional_view_name, flags)

	World.set_flow_callback_table(world, "FlowCallbacks", "UIFlowCallbacks")

	return world
end

function UIWorldSpawner:create_viewport(camera_unit, viewport_name, viewport_type, viewport_layer, shading_environment, shading_callback, render_targets)
	local world = self._world
	shading_callback = shading_callback or callback(self, "_shading_callback")
	local viewport = ScriptWorld.create_viewport(world, viewport_name, viewport_type, viewport_layer, camera_unit, nil, , , shading_environment, shading_callback, nil, render_targets)
	self._viewport = viewport
	self._viewport_name = viewport_name
	local camera = ScriptViewport.camera(viewport)
	camera_unit = camera_unit or Camera.get_data(camera, "unit")
	self._camera = camera
	self._camera_unit = camera_unit
	local camera_position = Unit.world_position(camera_unit, 1)
	local camera_rotation = Unit.world_rotation(camera_unit, 1)
	self._boxed_camera_start_position = Vector3Box(camera_position)
	self._boxed_camera_start_rotation = QuaternionBox(camera_rotation)

	ScriptWorld.activate_viewport(world, viewport)

	self._initial_fov = Camera.vertical_fov(camera) / math.pi * 180

	return viewport
end

function UIWorldSpawner:change_camera_unit(camera_unit, add_shadow_cull_camera)
	local viewport = self._viewport

	ScriptWorld.change_camera_unit(viewport, camera_unit, add_shadow_cull_camera)

	local camera = ScriptViewport.camera(viewport)
	self._camera = camera
	self._camera_unit = camera_unit
	local camera_position = Unit.world_position(camera_unit, 1)
	local camera_rotation = Unit.world_rotation(camera_unit, 1)

	Vector3Box.store(self._boxed_camera_start_position, camera_position)
	QuaternionBox.store(self._boxed_camera_start_rotation, camera_rotation)
end

function UIWorldSpawner:sync_camera_to_camera_unit(camera_unit)
	local camera_position = Unit.world_position(camera_unit, 1)
	local camera_rotation = Unit.world_rotation(camera_unit, 1)

	self:set_camera_position(camera_position)
	self:set_camera_rotation(camera_rotation)
end

function UIWorldSpawner:set_camera_position(position)
	local camera_unit = self._camera_unit

	Unit.set_local_position(camera_unit, 1, position)
	Vector3Box.store(self._boxed_camera_start_position, position)
end

function UIWorldSpawner:set_camera_rotation(rotation)
	local camera_unit = self._camera_unit

	Unit.set_local_rotation(camera_unit, 1, rotation)
	QuaternionBox.store(self._boxed_camera_start_rotation, rotation)
end

function UIWorldSpawner:set_viewport_position(x_scale, y_scale)
	self._viewport_x_scale = x_scale or self._viewport_x_scale or 0
	self._viewport_y_scale = y_scale or self._viewport_y_scale or 0

	self:_update_viewport_rect()
end

function UIWorldSpawner:set_viewport_size(width_scale, height_scale)
	self._viewport_width_scale = width_scale or self._viewport_width_scale or 1
	self._viewport_height_scale = height_scale or self._viewport_height_scale or 1

	self:_update_viewport_rect()
end

function UIWorldSpawner:_update_viewport_rect()
	local x_scale = math.min(self._viewport_x_scale or 0, 1)
	local y_scale = math.min(self._viewport_y_scale or 0, 1)
	local width_scale = math.min(self._viewport_width_scale or 0, 1)
	local height_scale = math.min(self._viewport_height_scale or 0, 1)

	Viewport.set_rect(self._viewport, x_scale, y_scale, width_scale, height_scale)
end

function UIWorldSpawner:_set_fov(fov)
	Camera.set_vertical_fov(self._camera, math.pi * fov / 180)
end

function UIWorldSpawner:boxed_camera_start_position()
	return self._boxed_camera_start_position
end

function UIWorldSpawner:boxed_camera_start_rotation()
	return self._boxed_camera_start_rotation
end

function UIWorldSpawner:_shading_callback(world, shading_env, viewport, default_shading_environment_name)
	local gamma = Application.user_setting("gamma") or 0

	ShadingEnvironment.set_scalar(shading_env, "exposure_compensation", ShadingEnvironment.scalar(shading_env, "exposure_compensation") + gamma)

	local blur_value = World.get_data(world, "fullscreen_blur") or 0

	if blur_value > 0 then
		ShadingEnvironment.set_scalar(shading_env, "fullscreen_blur_enabled", 1)
		ShadingEnvironment.set_scalar(shading_env, "fullscreen_blur_amount", math.clamp(blur_value, 0, 1))
	else
		World.set_data(world, "fullscreen_blur", nil)
		ShadingEnvironment.set_scalar(shading_env, "fullscreen_blur_enabled", 0)
	end

	local greyscale_value = World.get_data(world, "greyscale") or 0

	if greyscale_value > 0 then
		ShadingEnvironment.set_scalar(shading_env, "grey_scale_enabled", 1)
		ShadingEnvironment.set_scalar(shading_env, "grey_scale_amount", math.clamp(greyscale_value, 0, 1))
		ShadingEnvironment.set_vector3(shading_env, "grey_scale_weights", Vector3(0.33, 0.33, 0.33))
	else
		World.set_data(world, "greyscale", nil)
		ShadingEnvironment.set_scalar(shading_env, "grey_scale_enabled", 0)
	end
end

function UIWorldSpawner:set_camera_rotation_axis_offset(axis, value, animation_time, func_ptr)
	self:_animate_axis(self._camera_rotation_animation_data, axis, value, animation_time, func_ptr)
end

function UIWorldSpawner:set_camera_position_axis_offset(axis, value, animation_time, func_ptr)
	self:_animate_axis(self._camera_position_animation_data, axis, value, animation_time, func_ptr)
end

function UIWorldSpawner:camera_position_axis_offset(axis)
	return self._camera_position_animation_data[axis].value
end

function UIWorldSpawner:_animate_axis(source, axis, value, animation_time, func_ptr, optional_start_time)
	local data = source[axis]
	data.from = animation_time and data.value or value
	data.to = value
	data.total_time = animation_time
	data.time = optional_start_time or 0
	data.func = func_ptr
	data.value = data.from
end

function UIWorldSpawner:set_camera_blur(blur_amount, duration, anim_func)
	if not self._blur_animation_data and blur_amount == self._current_blur then
		return
	end

	local current_blur = self._current_blur or 0
	local blur_difference = blur_amount - current_blur
	self._blur_animation_data = {
		time = 0,
		start_value = current_blur,
		end_value = blur_amount,
		value_difference = blur_difference,
		anim_func = anim_func,
		duration = math.abs(blur_difference) * (duration or 1)
	}
end

function UIWorldSpawner:_set_world_blur_value(blur_amount)
	local world = self._world

	World.set_data(world, "fullscreen_blur", 0.75 * blur_amount)

	self._world_blurred = blur_amount ~= 0
	local world_name = self._world_name
	local viewport_name = self._viewport_name

	if self._world_blurred then
		WorldRenderUtils.enable_world_fullscreen_blur(world_name, viewport_name, blur_amount)
	else
		WorldRenderUtils.disable_world_fullscreen_blur(world_name, viewport_name)
	end
end

function UIWorldSpawner:_update_animation_data(animation_data, dt)
	for axis, data in pairs(animation_data) do
		local total_time = data.total_time

		if total_time then
			local old_time = data.time
			data.time = math.min(old_time + dt, total_time)
			local progress = total_time > 0 and math.min(1, data.time / total_time) or 1
			local func = data.func
			local anim_progress = func and func(progress) or progress
			data.value = (data.to - data.from) * anim_progress + data.from

			if progress == 1 then
				data.total_time = nil
			end
		end
	end
end

function UIWorldSpawner:_update_camera_rotation()
	local camera_rotation_animation_data = self._camera_rotation_animation_data
	local camera_rotation = self._boxed_camera_start_rotation:unbox()
	local x = camera_rotation_animation_data.x.value
	local y = camera_rotation_animation_data.y.value
	local z = camera_rotation_animation_data.z.value
	local camera_anim_rotation = Quaternion.from_euler_angles_xyz(x, y, z)
	camera_rotation = Quaternion.multiply(camera_rotation, camera_anim_rotation)

	Unit.set_local_rotation(self._camera_unit, 1, camera_rotation)
end

function UIWorldSpawner:_update_camera_position()
	local boxed_camera_start_position = self._boxed_camera_start_position
	local camera_position_animation_data = self._camera_position_animation_data
	local camera_position_new = Vector3.zero()
	camera_position_new.x = boxed_camera_start_position[1] + camera_position_animation_data.x.value
	camera_position_new.y = boxed_camera_start_position[2] + camera_position_animation_data.y.value
	camera_position_new.z = boxed_camera_start_position[3] + camera_position_animation_data.z.value

	Unit.set_local_position(self._camera_unit, 1, camera_position_new)
end

function UIWorldSpawner:_update_world_blur(dt)
	local blur_animation_data = self._blur_animation_data

	if not blur_animation_data then
		return self._current_blur or 0
	end

	local time = blur_animation_data.time
	local duration = blur_animation_data.duration
	local anim_func = blur_animation_data.anim_func
	time = math.min(time + dt, duration)
	local progress = duration > 0 and time / duration or 0
	local anim_progress = anim_func and anim_func(progress) or progress
	local start_value = blur_animation_data.start_value
	local value_difference = blur_animation_data.value_difference
	local new_value = start_value + anim_progress * value_difference

	if progress == 1 then
		self._blur_animation_data = nil
	else
		blur_animation_data.time = time
	end

	return new_value
end

function UIWorldSpawner:update(dt, t)
	local blur_value = self:_update_world_blur(dt)

	if blur_value ~= self._current_blur then
		self._current_blur = blur_value

		self:_set_world_blur_value(blur_value)
	end

	if self._extension_manager then
		self._extension_manager:pre_update(dt, t)
		self._extension_manager:update()
	end

	if self._viewport then
		self:_update_animation_data(self._camera_position_animation_data, dt)
		self:_update_animation_data(self._camera_rotation_animation_data, dt)
		self:_update_camera_position()
		self:_update_camera_rotation()
	end

	self._unit_spawner:remove_pending_units()
end

function UIWorldSpawner:set_world_disabled(disabled)
	disabled = disabled or false
	self._world_disabled = disabled
	local world_name = self._world_name
	local world_manager = Managers.world
	local world_disabled_state = not world_manager:is_world_enabled(world_name)

	if world_disabled_state ~= disabled then
		world_manager:enable_world(world_name, not disabled)
	end
end

function UIWorldSpawner:world_disabled()
	return self._world_disabled
end

function UIWorldSpawner:destroy()
	local world = self._world

	if self._extension_manager then
		self._extension_manager:unregister_unit_category("level_spawned")
		self._extension_manager:unregister_unit_category("flow_spawned")
	end

	local unit_spawner = self._unit_spawner

	if unit_spawner then
		unit_spawner:remove_pending_units()
		unit_spawner:destroy()

		self._unit_spawner = nil
	end

	if self._viewport then
		ScriptWorld.destroy_viewport(world, self._viewport_name)

		self._viewport = nil
		self._viewport_name = nil
	end

	if self._level then
		ScriptWorld.destroy_level(world, self._level_name)

		self._level = nil
		self._level_name = nil
	end

	if self._extension_manager then
		Managers.ui:unregister_world_extension_manager_lookup(world)
		self._extension_manager:destroy()

		self._extension_manager = nil
	end

	Managers.ui:destroy_world(world)

	self._world = nil
end

return UIWorldSpawner
