local PlayerHuskMusicParameterExtension = class("PlayerHuskMusicParameterExtension")

function PlayerHuskMusicParameterExtension:init(extension_init_context, unit, extension_init_data, game_object_data)
	self._health_extension = ScriptUnit.extension(unit, "health_system")
	self._vector_horde_near = false
	self._ambush_horde_near = false
	self._last_man_standing = false
	self._boss_near = false
	self._health_percent = 0
	self._intensity_percent = 0
	self._tension_percent = 0
	self._locked_in_melee = false
	self._update_timer = 0
end

function PlayerHuskMusicParameterExtension:on_game_object_created(game_session, game_object_id)
	self._game_object_id = game_object_id
	self._game_session = game_session
end

function PlayerHuskMusicParameterExtension:on_game_object_destroyed(game_session, game_object_id)
	self._game_object_id = nil
	self._game_session = nil
end

function PlayerHuskMusicParameterExtension:update(unit, dt, t)
	local game_session = self._game_session
	local game_object_id = self._game_object_id

	if not game_session or not game_object_id or t < self._update_timer then
		return
	end

	self._vector_horde_near = GameSession.game_object_field(game_session, game_object_id, "vector_horde_near")
	self._ambush_horde_near = GameSession.game_object_field(game_session, game_object_id, "ambush_horde_near")
	self._last_man_standing = GameSession.game_object_field(game_session, game_object_id, "last_man_standing")
	self._boss_near = GameSession.game_object_field(game_session, game_object_id, "boss_near")
	self._health_percent = self._health_extension:current_health_percent()
	self._intensity_percent = GameSession.game_object_field(game_session, game_object_id, "intensity_percent")
	self._tension_percent = GameSession.game_object_field(game_session, game_object_id, "tension_percent")
	self._num_aggroed_minions_near = GameSession.game_object_field(game_session, game_object_id, "num_aggroed_minions_near")
	self._locked_in_melee = GameSession.game_object_field(game_session, game_object_id, "locked_in_melee")
	self._num_aggroed_minions = GameSession.game_object_field(game_session, game_object_id, "num_aggroed_minions")
	self._update_timer = t + 0.5
end

function PlayerHuskMusicParameterExtension:num_aggroed_minions_near()
	return self._num_aggroed_minions_near
end

function PlayerHuskMusicParameterExtension:tension_percent()
	return self._tension_percent
end

function PlayerHuskMusicParameterExtension:vector_horde_near()
	return self._vector_horde_near
end

function PlayerHuskMusicParameterExtension:ambush_horde_near()
	return self._ambush_horde_near
end

function PlayerHuskMusicParameterExtension:last_man_standing()
	return self._last_man_standing
end

function PlayerHuskMusicParameterExtension:boss_near()
	return self._boss_near
end

function PlayerHuskMusicParameterExtension:health_percent()
	return self._health_percent
end

function PlayerHuskMusicParameterExtension:intensity_percent()
	return self._intensity_percent
end

function PlayerHuskMusicParameterExtension:locked_in_melee()
	return self._locked_in_melee
end

function PlayerHuskMusicParameterExtension:num_aggroed_minions()
	return self._num_aggroed_minions
end

return PlayerHuskMusicParameterExtension
