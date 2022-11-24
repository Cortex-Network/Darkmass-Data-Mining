local ScannerDisplay = component("ScannerDisplay")

function ScannerDisplay:init(unit)
	local scanner_display_extension = ScriptUnit.fetch_component_extension(unit, "scanner_display_system")

	if scanner_display_extension then
		scanner_display_extension:setup_from_component()
	end
end

function ScannerDisplay:editor_init(unit)
end

function ScannerDisplay:enable(unit)
end

function ScannerDisplay:disable(unit)
end

function ScannerDisplay:destroy(unit)
end

ScannerDisplay.component_data = {
	extensions = {
		"ScannerDisplayExtension"
	}
}

return ScannerDisplay
