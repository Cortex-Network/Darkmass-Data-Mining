local CinematicPlayerSpawner = component("CinematicPlayerSpawner")

function CinematicPlayerSpawner:init(unit)
	self:enable(unit)

	self._cinematic_name = self:get_data(unit, "cinematic_name")
end

function CinematicPlayerSpawner:editor_init(unit)
	self:enable(unit)
end

function CinematicPlayerSpawner:enable(unit)
end

function CinematicPlayerSpawner:disable(unit)
end

function CinematicPlayerSpawner:destroy(unit)
end

function CinematicPlayerSpawner:cinematic_name()
	return self._cinematic_name
end

CinematicPlayerSpawner.component_data = {
	cinematic_name = {
		value = "none",
		ui_type = "combo_box",
		ui_name = "Cinematic Name",
		options_keys = {
			"None",
			"Intro ABC",
			"Outro Win",
			"Outro Fail",
			"Cutscene 01",
			"Cutscene 02",
			"Cutscene 03",
			"Cutscene 04",
			"Cutscene 05",
			"Cutscene 6",
			"Cutscene 7",
			"Cutscene 8",
			"Cutscene 9",
			"Cutscene 10",
			"Path of Trust 01",
			"Path of Trust 02",
			"Path of Trust 03",
			"Path of Trust 04",
			"Path of Trust 05",
			"Path of Trust 06",
			"Path of Trust 07",
			"Path of Trust 08",
			"Path of Trust 09",
			"Traitor Captain Intro"
		},
		options_values = {
			"none",
			"intro_abc",
			"outro_win",
			"outro_fail",
			"cutscene_1",
			"cutscene_2",
			"cutscene_3",
			"cutscene_4",
			"cutscene_5",
			"cutscene_6",
			"cutscene_7",
			"cutscene_8",
			"cutscene_9",
			"cutscene_10",
			"path_of_trust_01",
			"path_of_trust_02",
			"path_of_trust_03",
			"path_of_trust_04",
			"path_of_trust_05",
			"path_of_trust_06",
			"path_of_trust_07",
			"path_of_trust_08",
			"path_of_trust_09",
			"traitor_captain_intro"
		}
	}
}

return CinematicPlayerSpawner
