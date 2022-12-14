local DialogueBreedSettings = require("scripts/settings/dialogue/dialogue_breed_settings")
local LevelProps = require("scripts/settings/level_prop/level_props")
local MissionTemplates = require("scripts/settings/mission/mission_templates")
local VoiceOverSpawnManager = class("VoiceOverSpawnManager")
local _default_vo_profile = "sergeant_a"

function VoiceOverSpawnManager:init(is_server, mission_giver_vo_override)
	self._is_server = is_server
	self._level = nil
	self._unit_spawner_manager = Managers.state.unit_spawner
	self._voice_over_units = {}
	self.mission_giver_vo_override = mission_giver_vo_override
end

function VoiceOverSpawnManager:destroy()
	self._unit_spawner_manager = nil
end

function VoiceOverSpawnManager:on_gameplay_post_init(level)
	self._level = level
	local vo_classes_2d = DialogueBreedSettings.voice_classes_2d

	for i = 1, #vo_classes_2d do
		local vo_class = vo_classes_2d[i]
		local breed_dialogue_settings = DialogueBreedSettings[vo_class]

		self:_create_units(breed_dialogue_settings)
	end
end

function VoiceOverSpawnManager:delete_units()
	local unit_spawner_manager = self._unit_spawner_manager

	for _, vo_unit in pairs(self._voice_over_units) do
		unit_spawner_manager:mark_for_deletion(vo_unit)
	end

	self._voice_over_units = {}
end

function VoiceOverSpawnManager:_create_units(dialogue_breed_settings)
	local unit_spawner_manager = self._unit_spawner_manager
	local props_settings = LevelProps[dialogue_breed_settings.prop_name]
	local unit_name = props_settings.unit_name
	local unit_template_name = props_settings.unit_template_name
	local voice_over_settings = table.clone(props_settings)
	local voice_profiles = dialogue_breed_settings.wwise_voices

	for _, voice_profile in pairs(voice_profiles) do
		local vo_unit = unit_spawner_manager:spawn_network_unit(unit_name, unit_template_name, nil, , , voice_over_settings)
		local dialogue_extension = ScriptUnit.has_extension(vo_unit, "dialogue_system")

		dialogue_extension:set_voice_profile_data(dialogue_breed_settings.vo_class_name, dialogue_breed_settings.wwise_voice_switch_group, voice_profile)
		dialogue_extension:init_faction_memory(dialogue_breed_settings.dialogue_memory_faction_name)

		dialogue_extension._is_network_synced = dialogue_breed_settings.is_network_synced
		self._voice_over_units[voice_profile] = vo_unit
	end
end

function VoiceOverSpawnManager:voice_over_unit(voice_profile)
	return self._voice_over_units[voice_profile]
end

function VoiceOverSpawnManager:current_voice_profile()
	if self.mission_giver_vo_override and self.mission_giver_vo_override ~= "none" then
		return self.mission_giver_vo_override
	end

	local mission_info = Managers.state.mission:mission()
	local mission_brief_vo = mission_info and mission_info.mission_brief_vo
	local vo_profile = mission_brief_vo and mission_brief_vo.vo_profile

	return vo_profile or _default_vo_profile
end

return VoiceOverSpawnManager
