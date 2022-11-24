local ServoSkullActivator = component("ServoSkullActivator")

function ServoSkullActivator:init(unit)
	local servo_skull_activator_extension = ScriptUnit.fetch_component_extension(unit, "servo_skull_system")

	if servo_skull_activator_extension then
		local hide_timer = self:get_data(unit, "hide_timer")

		servo_skull_activator_extension:setup_from_component(hide_timer)
	end
end

function ServoSkullActivator:editor_init(unit)
end

function ServoSkullActivator:enable(unit)
end

function ServoSkullActivator:disable(unit)
end

function ServoSkullActivator:destroy(unit)
end

ServoSkullActivator.component_data = {
	hide_timer = {
		ui_type = "number",
		value = 10,
		ui_name = "Hide Delay (in sec.)"
	},
	extensions = {
		"ServoSkullActivatorExtension"
	}
}

return ServoSkullActivator
