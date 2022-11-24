local DecoderDevice = component("DecoderDevice")

function DecoderDevice:init(unit, is_server)
	local decoder_device_extension = ScriptUnit.fetch_component_extension(unit, "decoder_device_system")

	if decoder_device_extension then
		local material_slot = self:get_data(unit, "material_slot")
		local main_material = self:get_data(unit, "main_material")
		local ghost_material = self:get_data(unit, "ghost_material")
		local install_anim_event = self:get_data(unit, "install_anim_event")

		if main_material == "" or ghost_material == "" or install_anim_event == "" then
			Log.error("DecoderDevice", "Missing materials or anim event. material_slot(%q), main_material(%q), ghost_material(%q), install_anim_event(%q)", material_slot, main_material, ghost_material, install_anim_event)

			return
		end

		decoder_device_extension:setup_from_component(material_slot, main_material, ghost_material, install_anim_event)
	end
end

function DecoderDevice:editor_init(unit)
end

function DecoderDevice:enable(unit)
end

function DecoderDevice:disable(unit)
end

function DecoderDevice:destroy(unit)
end

DecoderDevice.component_data = {
	material_slot = {
		ui_type = "text_box",
		value = "",
		ui_name = "Material Slot",
		category = "Material"
	},
	main_material = {
		ui_type = "resource",
		category = "Material",
		value = "",
		ui_name = "Main Material",
		filter = "material"
	},
	ghost_material = {
		ui_type = "resource",
		category = "Material",
		value = "",
		ui_name = "Ghost Material",
		filter = "material"
	},
	install_anim_event = {
		ui_type = "text_box",
		value = "",
		ui_name = "Install Anim Event"
	},
	extensions = {
		"DecoderDeviceExtension"
	}
}

return DecoderDevice
