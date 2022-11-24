local Definitions = require("scripts/ui/views/barber_vendor_background_view/barber_vendor_background_view_definitions")
local VendorInteractionViewBase = require("scripts/ui/views/vendor_interaction_view_base/vendor_interaction_view_base")
local ViewSettings = require("scripts/ui/views/barber_vendor_background_view/barber_vendor_background_view_settings")
local BarberVendorBackgroundView = class("BarberVendorBackgroundView", "VendorInteractionViewBase")

function BarberVendorBackgroundView:init(settings, context)
	self._wallet_type = "credits"

	BarberVendorBackgroundView.super.init(self, Definitions, settings, context)
end

function BarberVendorBackgroundView:on_enter()
	BarberVendorBackgroundView.super.on_enter(self)

	local narrative_manager = Managers.narrative
	local narrative_event_name = "level_unlock_barber_visited"

	if narrative_manager:can_complete_event(narrative_event_name) then
		narrative_manager:complete_event(narrative_event_name)
		self:play_vo_events(ViewSettings.vo_event_vendor_first_interaction, "barber_a", nil, 0.8)
	else
		self:play_vo_events(ViewSettings.vo_event_vendor_greeting, "barber_a", nil, 0.8)
	end
end

function BarberVendorBackgroundView:on_exit()
	BarberVendorBackgroundView.super.on_exit(self)

	local level = Managers.state.mission and Managers.state.mission:mission_level()

	if level then
		Level.trigger_event(level, "lua_barber_store_closed")
	end
end

return BarberVendorBackgroundView
