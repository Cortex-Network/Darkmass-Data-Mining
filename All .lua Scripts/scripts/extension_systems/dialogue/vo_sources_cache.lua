local DialogueSettings = require("scripts/settings/dialogue/dialogue_settings")
local VOSourcesCache = class("VOSourcesCache")

function VOSourcesCache:init()
	self._vo_sources = {}
	self._default_voice_template = "empty_voice_template"
	self._rule_files_loaded = {}
end

function VOSourcesCache:add_rule_file(rule_file_name)
	if table.contains(self._rule_files_loaded, rule_file_name) then
		return
	end

	self._rule_files_loaded[rule_file_name] = true

	for voice_template, _ in pairs(self._vo_sources) do
		local vo_source_target = DialogueSettings.default_voSources_path .. rule_file_name .. "_" .. voice_template

		if Application.can_get_resource("lua", vo_source_target) then
			table.merge(self._vo_sources[voice_template], require(vo_source_target))
		end
	end
end

function VOSourcesCache:get_vo_source(voice_template)
	Log.debug("VOSourcesCache", "voice_template %s requested", voice_template)

	if self._vo_sources[voice_template] ~= nil then
		return self._vo_sources[voice_template]
	end

	self._vo_sources[voice_template] = {}

	for rule_file, _ in pairs(self._rule_files_loaded) do
		local vo_sources_target = DialogueSettings.default_voSources_path .. rule_file .. "_" .. voice_template

		if Application.can_get_resource("lua", vo_sources_target) then
			table.merge(self._vo_sources[voice_template], require(vo_sources_target))
		end
	end

	return self._vo_sources[voice_template]
end

function VOSourcesCache:get_default_voice_profile()
	return self._default_voice_template, self:get_vo_source(self._default_voice_template)
end

function VOSourcesCache:destroy()
	self._vo_sources = nil
	self._default_voice_template = nil
	self._rule_files_loaded = nil
end

return VOSourcesCache
