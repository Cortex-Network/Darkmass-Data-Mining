local LungeTemplates = require("scripts/settings/lunge/lunge_templates")
local LungeEffects = class("LungeEffects")

function LungeEffects:init(equiped_ability_effect_scripts_context, ability_template)
	self._is_local_unit = equiped_ability_effect_scripts_context.is_local_unit
	self._ability_template = ability_template
	local unit_data_extension = equiped_ability_effect_scripts_context.unit_data_extension
	self._lunge_character_state_component = unit_data_extension:read_component("lunge_character_state")
	self._is_sfx_active = false
	local unit = equiped_ability_effect_scripts_context.unit
	self._unit = unit
	self._fx_extension = ScriptUnit.has_extension(unit, "fx_system")
end

function LungeEffects:destroy()
	if self._is_sfx_active then
		self:_stop_effects()
		self:_reset_lunge_parameter()
	end
end

function LungeEffects:update(unit, dt, t)
	local lunge_character_state_component = self._lunge_character_state_component
	local is_lungeing = lunge_character_state_component.is_lunging
	local is_sfx_active = self._is_sfx_active

	if is_lungeing and not is_sfx_active then
		self._is_sfx_active = true
		local lunnge_template_name = lunge_character_state_component.lunge_template
		self._lunge_template = LungeTemplates[lunnge_template_name]

		self:_start_effects()
		self:_set_lunge_parameter()
	elseif not is_lungeing and is_sfx_active then
		self._is_sfx_active = false

		self:_stop_effects()
		self:_reset_lunge_parameter()
	end
end

function LungeEffects:_start_effects()
	local lunge_template = self._lunge_template
	local start_sound_event = lunge_template.start_sound_event

	if start_sound_event and self._is_local_unit then
		self._fx_extension:trigger_wwise_event(start_sound_event, false)
	end
end

function LungeEffects:_stop_effects()
	local lunge_template = self._lunge_template
	local stop_sound_event = lunge_template.stop_sound_event

	if stop_sound_event and self._is_local_unit then
		self._fx_extension:trigger_wwise_event(stop_sound_event, false)
	end
end

function LungeEffects:_set_lunge_parameter()
	local lunge_template = self._lunge_template
	local wwise_state = lunge_template.wwise_state

	if wwise_state and self._is_local_unit then
		Wwise.set_state(wwise_state.group, wwise_state.on_state)
	end
end

function LungeEffects:_reset_lunge_parameter()
	local lunge_template = self._lunge_template
	local wwise_state = lunge_template.wwise_state

	if wwise_state and self._is_local_unit then
		Wwise.set_state(wwise_state.group, wwise_state.off_state)
	end
end

return LungeEffects
