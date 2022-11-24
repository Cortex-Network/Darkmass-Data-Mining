local PlayerVoiceGrunts = {
	SOURCE_NAME = "voice"
}
local SOURCE_NAME = PlayerVoiceGrunts.SOURCE_NAME

function PlayerVoiceGrunts.create_voice(fx_extension, unit, node_name)
	local attachments = {
		unit
	}

	fx_extension:register_sound_source(SOURCE_NAME, unit, attachments, node_name)
end

function PlayerVoiceGrunts.destroy_voice(fx_extension)
	fx_extension:unregister_sound_source(SOURCE_NAME)
end

function PlayerVoiceGrunts.voice_source(fx_extension)
	return fx_extension:sound_source(PlayerVoiceGrunts.SOURCE_NAME)
end

function PlayerVoiceGrunts.set_voice(wwise_world, source, switch_group, selected_voice, selected_fx_preset)
	WwiseWorld.set_switch(wwise_world, switch_group, selected_voice, source)

	if selected_fx_preset then
		WwiseWorld.set_source_parameter(wwise_world, source, "voice_fx_preset", selected_fx_preset)
	end
end

function PlayerVoiceGrunts.trigger_voice(sound_alias, visual_loadout_extension, fx_extension, suppress_vo)
	local dialogue_extension = fx_extension._dialogue_extension
	local should_play_voice = PlayerVoiceGrunts:_should_play_voice(dialogue_extension, suppress_vo)

	if not should_play_voice then
		return
	elseif should_play_voice and suppress_vo then
		dialogue_extension:stop_currently_playing_vo()
	end

	local resolved, event_name, append_husk_to_event_name = visual_loadout_extension:resolve_gear_sound(sound_alias)

	if resolved then
		return fx_extension:trigger_voice_wwise_event_with_source(event_name, SOURCE_NAME, append_husk_to_event_name)
	end
end

function PlayerVoiceGrunts.trigger_voice_non_synced(sound_alias, visual_loadout_extension, fx_extension, suppress_vo)
	local dialogue_extension = fx_extension._dialogue_extension
	local should_play_voice = PlayerVoiceGrunts:_should_play_voice(dialogue_extension, suppress_vo)

	if not should_play_voice then
		return
	elseif should_play_voice and suppress_vo then
		dialogue_extension:stop_currently_playing_vo()
	end

	local resolved, event_name, append_husk_to_event_name = visual_loadout_extension:resolve_gear_sound(sound_alias)

	if resolved then
		return fx_extension:trigger_wwise_event_non_synced(dialogue_extension, event_name, SOURCE_NAME, append_husk_to_event_name)
	end
end

function PlayerVoiceGrunts:_should_play_voice(dialogue_extension, suppress_vo)
	local should_play_voice = true
	local is_player_speaking = dialogue_extension and dialogue_extension:is_currently_playing_dialogue()

	if is_player_speaking and not suppress_vo then
		should_play_voice = false
	end

	return should_play_voice
end

local temp_voice_data = {}

function PlayerVoiceGrunts.voice_data(unit)
	local dialogue_extension = ScriptUnit.extension(unit, "dialogue_system")
	local wwise_switch_group, selected_voice, voice_fx_preset = dialogue_extension:voice_data()
	temp_voice_data.switch_group = wwise_switch_group
	temp_voice_data.selected_voice = selected_voice
	temp_voice_data.selected_voice_fx_preset = voice_fx_preset

	return temp_voice_data
end

return PlayerVoiceGrunts
