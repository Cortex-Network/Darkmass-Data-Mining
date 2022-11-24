local Broadphase = component("Broadphase")

function Broadphase:init(unit)
	self:enable(unit)

	local broadphase_extension = ScriptUnit.fetch_component_extension(unit, "broadphase_system")

	if broadphase_extension then
		local broadphase_categories = self:get_data(unit, "broadphase_categories")
		local broadphase_radius = self:get_data(unit, "broadphase_radius")
		local broadphase_node_name = self:get_data(unit, "broadphase_node_name")

		broadphase_extension:setup_from_component(broadphase_categories, broadphase_radius, broadphase_node_name)
	end
end

function Broadphase:editor_init(unit)
	self:enable(unit)
end

function Broadphase:enable(unit)
end

function Broadphase:disable(unit)
end

function Broadphase:destroy(unit)
end

Broadphase.component_data = {
	broadphase_categories = {
		value = "doors",
		ui_type = "combo_box",
		ui_name = "Broadphase Categories",
		options_keys = {
			"doors"
		},
		options_values = {
			"doors"
		}
	},
	broadphase_radius = {
		ui_type = "number",
		value = 1,
		ui_name = "Broadphase Radius",
		decimals = 2
	},
	broadphase_node_name = {
		ui_type = "text_box",
		value = "",
		ui_name = "Broadphase Node Name"
	},
	extensions = {
		"BroadphaseExtension"
	}
}

return Broadphase
