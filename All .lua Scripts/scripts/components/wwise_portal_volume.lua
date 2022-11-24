local WwisePortalVolume = component("WwisePortalVolume")

function WwisePortalVolume:init(unit)
	self._unit = unit
	self._wwise_world = Wwise.wwise_world(Unit.world(unit))
	self._open = false
	local register_portal = self:get_data(unit, "register_portal")

	if not register_portal then
		return false
	end

	if Unit.has_volume(unit, "portal_volume") == false then
		Log.error("WwisePortalVolume", "[init][Unit: %s] missing 'portal_volume'", Unit.id_string(unit))

		return false
	end

	if Managers then
		Managers.state.rooms_and_portals:register_portal(self)
	end

	return true
end

function WwisePortalVolume:editor_init(unit)
	if not rawget(_G, "LevelEditor") then
		return
	end

	self._unit = unit
	local world = Application.main_world()
	self._world = world
	self._line_object = World.create_line_object(self._world)
	self._drawer = DebugDrawer(self._line_object, "retained")
	self._should_debug_draw = false

	if Unit.has_volume(unit, "portal_volume") == false then
		Log.error("WwisePortalVolume", "[init][Unit: %s] missing 'portal_volume'", Unit.id_string(unit))

		return false
	end

	if Managers then
		Managers.state.rooms_and_portals:register_portal(self)
	end

	return true
end

function WwisePortalVolume:enable(unit)
	if Managers then
		self._open = true

		Managers.state.rooms_and_portals:toggle_portal(self, true)
	end
end

function WwisePortalVolume:get_unit()
	return self._unit
end

function WwisePortalVolume:disable(unit)
	if Managers then
		self._open = false

		Managers.state.rooms_and_portals:toggle_portal(self, false)
	end
end

function WwisePortalVolume:destroy(unit)
	if Managers then
		Managers.state.rooms_and_portals:remove_portal(self)
	end
end

function WwisePortalVolume:update(unit, dt, t)
end

function WwisePortalVolume:editor_update(unit)
	if not rawget(_G, "LevelEditor") then
		return
	end

	self:_editor_debug_draw(unit)

	return true
end

function WwisePortalVolume:editor_destroy(unit)
	if not rawget(_G, "LevelEditor") then
		return
	end

	local line_object = self._line_object
	local world = self._world

	LineObject.reset(line_object)
	LineObject.dispatch(world, line_object)
	World.destroy_line_object(world, line_object)

	self._line_object = nil
	self._world = nil
end

function WwisePortalVolume:_editor_debug_draw(unit)
	local should_debug_draw = self._should_debug_draw

	if should_debug_draw then
		local drawer = self._drawer

		drawer:reset()

		local tm = Unit.world_pose(unit, 1)
		local rotation = Matrix4x4.rotation(tm)
		local unit_forward = Quaternion.forward(rotation)
		local center = Unit.world_position(unit, 1)
		local from = center - unit_forward * 2
		local to = center + unit_forward * 2
		local color = Color.red()

		drawer:arrow_2d(from, to, color)

		local world = self._world

		drawer:update(world)
	else
		self._drawer:reset()
		self._drawer:update(self._world)
	end
end

function WwisePortalVolume:editor_toggle_debug_draw(enable)
	if not rawget(_G, "LevelEditor") then
		return
	end

	self._should_debug_draw = enable
end

function WwisePortalVolume:flow_enable()
	local unit = self._unit

	self:enable(unit)
end

function WwisePortalVolume:flow_disable()
	local unit = self._unit

	self:disable(unit)
end

function WwisePortalVolume:door_apply_portal_obstruction(door_is_closed, normalize_anim_time, anim_time, anim_duration)
	if Managers then
		local unit = self._unit
		local adjust_open_anim_time = self:get_data(unit, "adjust_open_anim_time")

		if adjust_open_anim_time then
			local actual_open_time = self:get_data(unit, "actual_open_time")
			local new_length = anim_duration - actual_open_time

			if new_length > 0 then
				local new_anim_time = anim_time - actual_open_time
				new_anim_time = math.max(new_anim_time, 0)
				normalize_anim_time = new_anim_time / new_length
			else
				Log.error("WwisePortalVolume", "[door_apply_portal_obstruction] Unit(%s, %s), 'actual_open_time' settings longer than door animation time. actual_open_time(%.2f) > anim_duration(%.2f)", tostring(unit), Unit.id_string(unit), anim_duration, actual_open_time)
			end
		end

		if door_is_closed then
			normalize_anim_time = 1 - normalize_anim_time
		end

		normalize_anim_time = 1 - normalize_anim_time
		normalize_anim_time = math.clamp(normalize_anim_time, 0, 1)
		local obstruction = normalize_anim_time
		local occlusion = normalize_anim_time

		if self._open then
			if obstruction >= 1 and occlusion >= 1 then
				Managers.state.rooms_and_portals:toggle_portal(self, false)

				self._open = false
			end
		elseif obstruction < 1 or occlusion < 1 then
			Managers.state.rooms_and_portals:toggle_portal(self, true)

			self._open = true
		end

		Managers.state.rooms_and_portals:set_portal_obstruction_and_occlusion(self, obstruction, occlusion)
	end
end

WwisePortalVolume.component_data = {
	register_portal = {
		ui_type = "check_box",
		value = true,
		ui_name = "Register Portal"
	},
	adjust_open_anim_time = {
		ui_type = "check_box",
		value = false,
		ui_name = "Adjust Open Anim Time Calculation",
		category = "Adjust Open Anim"
	},
	actual_open_time = {
		ui_type = "number",
		min = 0,
		decimals = 2,
		category = "Adjust Open Anim",
		value = 0,
		ui_name = "Actual Open Start Time (in sec.)",
		step = 0.01
	},
	inputs = {
		flow_enable = {
			accessibility = "private",
			type = "event"
		},
		flow_disable = {
			accessibility = "private",
			type = "event"
		}
	}
}

return WwisePortalVolume
