local SkullDecoderEffects = class("SkullDecoderEffects")
local FX_SOURCE_NAME = "_source"
local SFX_START_ALIAS = "sfx_device_start"
local SFX_STOP_ALIAS = "sfx_device_stop"

function SkullDecoderEffects:init(context, slot, weapon_template, fx_sources)
	local owner_unit = context.owner_unit
	self._wwise_world = context.wwise_world
	self._fx_source_name = fx_sources[FX_SOURCE_NAME]
	self._fx_extension = ScriptUnit.extension(owner_unit, "fx_system")
end

function SkullDecoderEffects:destroy()
end

function SkullDecoderEffects:wield()
	self._fx_extension:trigger_gear_wwise_event(SFX_START_ALIAS, FX_SOURCE_NAME)
end

function SkullDecoderEffects:unwield()
	self._fx_extension:trigger_gear_wwise_event(SFX_STOP_ALIAS, FX_SOURCE_NAME)
end

function SkullDecoderEffects:fixed_update(unit, dt, t, frame)
end

function SkullDecoderEffects:update(unit, dt, t)
end

function SkullDecoderEffects:update_first_person_mode(first_person_mode)
end

return SkullDecoderEffects
