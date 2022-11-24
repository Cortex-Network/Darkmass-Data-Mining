local ScannerLight = component("ScannerLight")

function ScannerLight:init(unit)
	self:enable(unit)

	local lights = {}
	local lights_array = self:get_data(unit, "lights")

	if lights_array then
		for i = 1, #lights_array do
			local light_name = lights_array[i]
			local has_light = Unit.has_light(unit, light_name)

			if has_light then
				local light = Unit.light(unit, light_name)
				lights[#lights + 1] = light
			end
		end
	end

	self._lights = lights
end

function ScannerLight:editor_init(unit)
	self:enable(unit)

	self._should_debug_draw = false
end

function ScannerLight:enable(unit)
end

function ScannerLight:disable(unit)
end

function ScannerLight:destroy(unit)
end

function ScannerLight:update(unit, dt, t)
end

function ScannerLight:editor_update(unit, dt, t)
end

function ScannerLight:changed(unit)
end

function ScannerLight:editor_changed(unit)
end

function ScannerLight:editor_world_transform_modified(unit)
end

function ScannerLight:editor_selection_changed(unit, selected)
end

function ScannerLight:editor_reset_physics(unit)
end

function ScannerLight:editor_property_changed(unit)
end

function ScannerLight:editor_on_level_spawned(unit, level)
end

function ScannerLight:editor_toggle_debug_draw(enable)
	self._should_debug_draw = enable
end

function ScannerLight:enable_lights(enabled)
	local lights = self._lights

	for i = 1, #lights do
		local light = lights[i]

		Light.set_enabled(light, enabled)
	end
end

function ScannerLight:set_light_color(color)
	local a, r, g, b = Quaternion.to_elements(color)
	local color_filter = Vector3(r / 255, g / 255, b / 255)
	local lights = self._lights

	for i = 1, #lights do
		local light = lights[i]

		Light.set_color_filter(light, color_filter)
	end
end

ScannerLight.component_data = {
	lights = {
		ui_type = "text_box_array",
		size = 1,
		ui_name = "Lights"
	},
	inputs = {
		function_example = {
			accessibility = "public",
			type = "event"
		}
	}
}

return ScannerLight
