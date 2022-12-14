local Dialogue = component("Dialogue")

function Dialogue:init(unit)
	self:enable(unit)

	local dialogue_class = self:get_data(unit, "dialogue_class")
	local dialogue_profile = self:get_data(unit, "dialogue_profile")
	local player_selected_voice = self:get_data(unit, "player_selected_voice")
	local faction_memory_name = self:get_data(unit, "faction_memory_name")
	local enabled = self:get_data(unit, "enabled")
	self._dialogue_class = dialogue_class
	self._dialogue_profile = dialogue_profile
	self._player_selected_voice = player_selected_voice
	self._faction_memory_name = faction_memory_name
	self._enabled = enabled
	local dialogue_extension = ScriptUnit.fetch_component_extension(unit, "dialogue_system")

	if dialogue_extension then
		dialogue_extension:setup_from_component(dialogue_class, dialogue_profile, player_selected_voice, faction_memory_name, enabled)
	end
end

function Dialogue:editor_init(unit)
	if not rawget(_G, "LevelEditor") then
		return
	end
end

function Dialogue:enable(unit)
end

function Dialogue:disable(unit)
end

function Dialogue:destroy(unit)
end

function Dialogue:dialogue_class()
	return self._dialogue_class
end

function Dialogue:dialogue_profile()
	return self._dialogue_profile
end

function Dialogue:player_selected_voice()
	return self._player_selected_voice
end

function Dialogue:dialogue_faction_name()
	return self._player_selected_voice
end

Dialogue.component_data = {
	dialogue_class = {
		value = "none",
		ui_type = "combo_box",
		category = "Dialogue",
		ui_name = "Class",
		options_keys = {
			"None",
			"Boon Vendor",
			"Confessional",
			"Contract Vendor",
			"Enemy Nemesis Wolfer",
			"Explicator",
			"Interrogator",
			"Ogryn",
			"Medicae Servitor",
			"Mourningstar Servitor",
			"Pilot",
			"Prison Guard",
			"Prologue Traitor",
			"Psyker",
			"Purser",
			"Sergeant",
			"Shipmistress",
			"Tech Priest",
			"Training Ground Psyker",
			"Underhive Contact",
			"Veteran",
			"Vocator",
			"Zealot",
			"Credit Store Servitor",
			"Mourningstar Soldier",
			"Barber"
		},
		options_values = {
			"none",
			"boon_vendor",
			"confessional",
			"contract_vendor",
			"enemy_nemesis_wolfer",
			"explicator",
			"interrogator",
			"ogryn",
			"medicae_servitor",
			"mourningstar_servitor",
			"pilot",
			"prison_guard",
			"prologue_traitor",
			"psyker",
			"purser",
			"sergeant",
			"shipmistress",
			"tech_priest",
			"training_ground_psyker",
			"underhive_contact",
			"veteran",
			"vocator",
			"zealot",
			"credit_store_servitor",
			"mourningstar_soldier",
			"barber"
		}
	},
	dialogue_profile = {
		value = "none",
		ui_type = "combo_box",
		category = "Dialogue",
		ui_name = "Character Voice",
		options_keys = {
			"None",
			"Boon Vendor A",
			"Contract Vendor",
			"Enemy Nemesis Wolfer, Male",
			"Emora Brahms, The Shipmistress",
			"Explicator Zola, Female",
			"Interrogator Rannick, Male",
			"Medicae Servitor A",
			"Mourningstar Servitor A",
			"Mourningstar Servitor B",
			"Mourningstar Servitor C",
			"Mourningstar Servitor D",
			"Ogryn, Male, The Bodyguard",
			"Ogryn, Male, The Bully",
			"Pilot Masozi, Female",
			"Prison Guard, Male",
			"Prologue Traitor, Male",
			"Psyker, Female, The Loner",
			"Psyker, Female, The Seer",
			"Psyker, Male, The Loner",
			"Psyker, Male, The Seer",
			"Purser A",
			"Sergeant Morrow, Male",
			"Servitor, The Confessor Servitorum",
			"Tech Priest Hadron, Female",
			"Training Grounds Psyker",
			"Underhive Contract A",
			"Veteran, Female, The Professional",
			"Veteran, Female, The Loose Cannon",
			"Veteran, Male, The Professional",
			"Veteran, Male, The Loose Cannon",
			"Vocator A",
			"Vocator B",
			"Zealot, Female, The Crusader",
			"Zealot, Female, The Fanatic",
			"Zealot, Male, The Crusader",
			"Zealot, Male, The Fanatic",
			"Credit Store Servitor A",
			"Credit Store Servitor B",
			"Credit Store Servitor C",
			"Mourningstar Soldier Male A",
			"Mourningstar Soldier Male B",
			"Mourningstar Soldier Male F",
			"Mourningstar Soldier Female A",
			"Mourningstar Initiate A",
			"Barber A"
		},
		options_values = {
			"none",
			"boon_vendor_a",
			"contract_vendor_a",
			"enemy_nemesis_wolfer_a",
			"shipmistress_a",
			"explicator_a",
			"interrogator_a",
			"medicae_servitor_a",
			"mourningstar_servitor_a",
			"mourningstar_servitor_b",
			"mourningstar_servitor_c",
			"mourningstar_servitor_d",
			"ogryn_a",
			"ogryn_b",
			"pilot_a",
			"prison_guard_a",
			"prologue_traitor_a",
			"psyker_female_a",
			"psyker_female_b",
			"psyker_male_a",
			"psyker_male_b",
			"purser_a",
			"sergeant_a",
			"confessional_a",
			"tech_priest_a",
			"training_ground_psyker_a",
			"underhive_contact_a",
			"veteran_female_a",
			"veteran_female_b",
			"veteran_male_a",
			"veteran_male_b",
			"vocator_a",
			"vocator_b",
			"zealot_female_a",
			"zealot_female_b",
			"zealot_male_a",
			"zealot_male_b",
			"credit_store_servitor_a",
			"credit_store_servitor_b",
			"credit_store_servitor_c",
			"mourningstar_soldier_male_a",
			"mourningstar_soldier_male_b",
			"mourningstar_soldier_male_f",
			"mourningstar_soldier_female_a",
			"mourningstar_initiate_a",
			"barber_a"
		}
	},
	faction_memory_name = {
		value = "none",
		ui_type = "combo_box",
		category = "Dialogue",
		ui_name = "Dialogue Faction Name",
		options_keys = {
			"None",
			"Enemy",
			"NPC",
			"Player"
		},
		options_values = {
			"none",
			"enemy",
			"npc",
			"player"
		}
	},
	player_selected_voice = {
		ui_type = "check_box",
		value = false,
		ui_name = "Use Local Player Voice",
		category = "Dialogue"
	},
	enabled = {
		ui_type = "check_box",
		value = true,
		ui_name = "Enabled"
	},
	extensions = {
		"DialogueActorExtension"
	}
}

return Dialogue
