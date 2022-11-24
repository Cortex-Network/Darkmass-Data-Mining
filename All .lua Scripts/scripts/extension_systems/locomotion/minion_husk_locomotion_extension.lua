local MinionHuskLocomotionExtension = class("MinionHuskLocomotionExtension")

function MinionHuskLocomotionExtension:init(extension_init_context, unit, extension_init_data, game_session, game_object_id)
	local sync_full_rotation = GameSession.has_game_object_field(game_session, game_object_id, "rotation")
	self._engine_extension_id = MinionHuskLocomotion.register_extension(unit, game_object_id, sync_full_rotation)

	Unit._set_mover(unit, nil)
end

function MinionHuskLocomotionExtension:destroy()
	MinionHuskLocomotion.destroy_extension(self._engine_extension_id)
end

function MinionHuskLocomotionExtension:current_velocity()
	return MinionHuskLocomotion.velocity(self._engine_extension_id)
end

return MinionHuskLocomotionExtension
