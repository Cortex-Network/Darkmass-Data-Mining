local PropUnitData = component("PropUnitData")

function PropUnitData:init(unit)
	local unit_data_extension = ScriptUnit.fetch_component_extension(unit, "unit_data_system")

	if unit_data_extension then
		local armor_data_name = self:get_data(unit, "armor_data_name")

		unit_data_extension:setup_from_component(armor_data_name)
	end
end

function PropUnitData:editor_init(unit)
end

function PropUnitData:enable(unit)
end

function PropUnitData:disable(unit)
end

function PropUnitData:destroy(unit)
end

PropUnitData.component_data = {
	armor_data_name = {
		value = "hazard_prop",
		ui_type = "combo_box",
		ui_name = "Prop Breed Data",
		options_keys = {
			"hazard_prop",
			"hazard_sphere",
			"corruptor_body",
			"corruptor_pustule"
		},
		options_values = {
			"hazard_prop",
			"hazard_sphere",
			"corruptor_body",
			"corruptor_pustule"
		}
	},
	extensions = {
		"PropUnitDataExtension"
	}
}

return PropUnitData
