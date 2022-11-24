local DoorControlPanel = component("DoorControlPanel")

function DoorControlPanel:init(unit)
	self:enable(unit)

	local door_control_panel_extension = ScriptUnit.fetch_component_extension(unit, "door_control_panel_system")

	if door_control_panel_extension then
		local start_active = self:get_data(unit, "start_active")

		door_control_panel_extension:setup_from_component(start_active)

		self._door_control_panel_extension = door_control_panel_extension
	end
end

function DoorControlPanel:editor_init(unit)
end

function DoorControlPanel:enable(unit)
end

function DoorControlPanel:disable(unit)
end

function DoorControlPanel:destroy(unit)
end

function DoorControlPanel:activate()
	if self._door_control_panel_extension then
		self._door_control_panel_extension:set_active(true)
	end
end

function DoorControlPanel:deactivate()
	if self._door_control_panel_extension then
		self._door_control_panel_extension:set_active(false)
	end
end

DoorControlPanel.component_data = {
	start_active = {
		ui_type = "check_box",
		value = true,
		ui_name = "Start Active"
	},
	inputs = {
		activate = {
			accessibility = "public",
			type = "event"
		},
		deactivate = {
			accessibility = "public",
			type = "event"
		}
	},
	extensions = {
		"DoorControlPanelExtension"
	}
}

return DoorControlPanel
