require("scripts/extension_systems/locomotion/deployable_husk_locomotion_extension")
require("scripts/extension_systems/locomotion/deployable_unit_locomotion_extension")
require("scripts/extension_systems/locomotion/minion_husk_locomotion_extension")
require("scripts/extension_systems/locomotion/minion_locomotion_extension")
require("scripts/extension_systems/locomotion/player_husk_locomotion")
require("scripts/extension_systems/locomotion/player_unit_locomotion_extension")
require("scripts/extension_systems/locomotion/projectile_husk_locomotion_extension")
require("scripts/extension_systems/locomotion/projectile_unit_locomotion_extension")

local Attack = require("scripts/utilities/attack/attack")
local Breed = require("scripts/utilities/breed")
local DamageProfileTemplates = require("scripts/settings/damage/damage_profile_templates")
local LocomotionSystem = class("LocomotionSystem", "ExtensionSystemBase")

function LocomotionSystem:init(extension_system_creation_context, ...)
	LocomotionSystem.super.init(self, extension_system_creation_context, ...)

	local game_session = extension_system_creation_context.game_session

	if self._is_server then
		MinionLocomotion.init(self._world, self._physics_world, self._nav_world, game_session)
	else
		MinionHuskLocomotion.init(self._world, game_session)
	end
end

function LocomotionSystem:destroy()
	if self._is_server then
		MinionLocomotion.destroy()
	else
		MinionHuskLocomotion.destroy()
	end
end

function LocomotionSystem:on_remove_extension(unit, extension_name)
	for other_unit, other_extension in pairs(self._unit_to_extension_map) do
		if other_extension.sticking_to_unit then
			local sticking_to_unit = other_extension:sticking_to_unit()

			if sticking_to_unit == unit then
				other_extension:unstick_from_unit()
			end
		end
	end

	LocomotionSystem.super.on_remove_extension(self, unit, extension_name)
end

function LocomotionSystem:update(context, dt, t, ...)
	LocomotionSystem.super.update(self, context, dt, t, ...)

	if self._is_server then
		local units_to_kill = MinionLocomotion.update(dt, t)

		self:_update_units_to_kill(units_to_kill)
	else
		MinionHuskLocomotion.update(dt)
	end
end

function LocomotionSystem:_update_units_to_kill(units_to_kill)
	if units_to_kill == nil then
		return
	end

	local attack_direction = Vector3.down()
	local damage_profile = DamageProfileTemplates.kill_volume_and_ofF_navmesh

	for i = 1, #units_to_kill do
		local unit = units_to_kill[i]

		if HEALTH_ALIVE[unit] then
			local position = Unit.local_position(unit, 1)

			Log.info("LocomotionSystem", "Killing %s since outside nav mesh (%s).", unit, position)

			local health_extension = ScriptUnit.has_extension(unit, "health_system")
			local last_damaging_unit = health_extension and health_extension:last_damaging_unit()

			Attack.execute(unit, damage_profile, "instakill", true, "attack_direction", attack_direction, "attacking_unit", last_damaging_unit)
		end
	end
end

return LocomotionSystem
