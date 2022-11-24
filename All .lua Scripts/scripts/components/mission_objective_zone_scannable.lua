local MissionObjectiveZoneScannable = component("MissionObjectiveZoneScannable")

function MissionObjectiveZoneScannable:init(unit)
end

function MissionObjectiveZoneScannable:enable(unit)
end

function MissionObjectiveZoneScannable:disable(unit)
end

function MissionObjectiveZoneScannable:destroy(unit)
end

MissionObjectiveZoneScannable.component_data = {
	extensions = {
		"MissionObjectiveZoneScannableExtension"
	}
}

return MissionObjectiveZoneScannable
