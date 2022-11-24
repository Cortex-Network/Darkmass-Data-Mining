local PropShield = component("PropShield")

function PropShield:init(unit)
	self._unit = unit
	local pickup_spawner_extension = ScriptUnit.fetch_component_extension(unit, "shield_system")

	if pickup_spawner_extension then
		local actor_names = self:get_data(unit, "actor_names")

		pickup_spawner_extension:setup_from_component(actor_names)
	end
end

function PropShield:editor_init(unit)
end

function PropShield:enable(unit)
end

function PropShield:disable(unit)
end

function PropShield:destroy(unit)
end

PropShield.component_data = {
	actor_names = {
		ui_type = "text_box_array",
		size = 0,
		ui_name = "Shield Actors",
		values = {}
	},
	extensions = {
		"PropShieldExtension"
	}
}

return PropShield
