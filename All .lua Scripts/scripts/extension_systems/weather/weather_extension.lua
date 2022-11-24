local WeatherExtension = class("WeatherExtension")

function WeatherExtension:init(extension_init_context, unit, extension_init_data, ...)
	self._unit = unit

	if DevParameters.debug_weather_vfx then
		-- Nothing
	end
end

function WeatherExtension:setup_from_component(world_particles, screen_particles, priority)
	self._world_particles = world_particles
	self._screen_particles = screen_particles
	self._priority = priority
end

function WeatherExtension:is_in_volume(position)
	local inside = false

	if position then
		inside = Unit.is_point_inside_volume(self._unit, "weather_volume", position)
	end

	return inside
end

function WeatherExtension:get_settings()
	return self._priority, self._world_particles, self._screen_particles
end

function WeatherExtension:destroy()
	self._unit = nil
end

function WeatherExtension:extensions_ready(world, unit)
end

return WeatherExtension
