local WeatherVolume = component("WeatherVolume")

function WeatherVolume:init(unit)
	if not DEDICATED_SERVER then
		self:enable(unit)
	end
end

function WeatherVolume:enable(unit)
	local weather_extension = ScriptUnit.fetch_component_extension(unit, "weather_system")

	if weather_extension then
		local world_particles = self:get_data(unit, "world_particles")
		local screen_particles = self:get_data(unit, "screen_particles")
		local priority = self:get_data(unit, "priority")

		weather_extension:setup_from_component(world_particles, screen_particles, priority)
	end
end

function WeatherVolume:disable(unit)
end

function WeatherVolume:destroy(unit)
end

function WeatherVolume:editor_init(unit)
end

function WeatherVolume:editor_destroy(unit)
end

WeatherVolume.component_data = {
	world_particles = {
		ui_type = "resource",
		preview = false,
		value = "",
		ui_name = "World Particles",
		filter = "particles"
	},
	screen_particles = {
		ui_type = "resource",
		preview = false,
		value = "",
		ui_name = "Screen Particles",
		filter = "particles"
	},
	priority = {
		ui_type = "number",
		min = 1,
		max = 10,
		decimals = 0,
		value = 1,
		ui_name = "Priority",
		step = 1
	},
	extensions = {
		"WeatherExtension"
	}
}

return WeatherVolume
