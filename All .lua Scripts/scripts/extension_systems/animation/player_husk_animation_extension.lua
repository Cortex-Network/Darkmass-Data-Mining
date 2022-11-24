local PlayerUnitAnimationState = require("scripts/extension_systems/animation/utilities/player_unit_animation_state")
local PlayerHuskAnimationExtension = class("PlayerHuskAnimationExtension")

function PlayerHuskAnimationExtension:init(extension_init_context, unit, extension_init_data)
	self._unit = unit
	local first_person_extension = ScriptUnit.extension(unit, "first_person_system")
	local first_person_unit = first_person_extension:first_person_unit()
	self._first_person_unit = first_person_unit
	self._anim_variable_ids_third_person = {}
	self._anim_variable_ids_first_person = {}

	PlayerUnitAnimationState.cache_anim_variable_ids(unit, first_person_unit, self._anim_variable_ids_third_person, self._anim_variable_ids_first_person)
end

function PlayerHuskAnimationExtension:anim_event(event_name)
	error("Not allowed to play animations on husk.")
end

function PlayerHuskAnimationExtension:anim_event_with_variable_float(event_name, variable_name, variable_value)
	error("Not allowed to play animations on husk.")
end

function PlayerHuskAnimationExtension:anim_event_with_variable_floats(event_name, ...)
	error("Not allowed to play animations on husk.")
end

function PlayerHuskAnimationExtension:anim_event_with_variable_int(event_name, ...)
	error("Not allowed to play animations on husk.")
end

function PlayerHuskAnimationExtension:anim_event_1p(event_name)
	error("Not allowed to play animations on husk.")
end

function PlayerHuskAnimationExtension:anim_event_with_variable_float_1p(event_name, variable_name, variable_value)
	error("Not allowed to play animations on husk.")
end

function PlayerHuskAnimationExtension:anim_event_with_variable_floats_1p(event_name, ...)
	error("Not allowed to play animations on husk.")
end

function PlayerHuskAnimationExtension:inventory_slot_wielded(weapon_template)
	local unit = self._unit
	local first_person_unit = self._first_person_unit
	local is_local_unit = false

	PlayerUnitAnimationState.set_anim_state_machine(unit, first_person_unit, weapon_template, is_local_unit, self._anim_variable_ids_third_person, self._anim_variable_ids_first_person)
end

function PlayerHuskAnimationExtension:anim_variable_id(anim_variable)
	return self._anim_variable_ids_third_person[anim_variable]
end

function PlayerHuskAnimationExtension:anim_variable_id_1p(anim_variable)
	return self._anim_variable_ids_first_person[anim_variable]
end

function PlayerHuskAnimationExtension:destroy()
end

return PlayerHuskAnimationExtension
