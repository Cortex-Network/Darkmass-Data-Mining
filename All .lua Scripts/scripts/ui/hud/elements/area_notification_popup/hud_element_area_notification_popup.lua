local Definitions = require("scripts/ui/hud/elements/area_notification_popup/hud_element_area_notification_popup_definitions")
local HudElementAreaNotificationPopupSettings = require("scripts/ui/hud/elements/area_notification_popup/hud_element_area_notification_popup_settings")
local UISoundEvents = require("scripts/settings/ui/ui_sound_events")
local HudElementAreaNotificationPopup = class("HudElementAreaNotificationPopup", "HudElementBase")

function HudElementAreaNotificationPopup:init(parent, draw_layer, start_scale, definitions)
	HudElementAreaNotificationPopup.super.init(self, parent, draw_layer, start_scale, Definitions)

	self._player = parent:player()
	self._area_notificactions_queue = {}

	self:_register_events()
end

function HudElementAreaNotificationPopup:destroy()
	self:_unregister_events()
	HudElementAreaNotificationPopup.super.destroy(self)
end

function HudElementAreaNotificationPopup:update(dt, t, ui_renderer, render_settings, input_service)
	HudElementAreaNotificationPopup.super.update(self, dt, t, ui_renderer, render_settings, input_service)

	if self._popup_animation_id and not self:_is_animation_active(self._popup_animation_id) then
		self._popup_animation_id = nil

		if #self._area_notificactions_queue > 0 then
			local area_data = table.remove(self._area_notificactions_queue, #self._area_notificactions_queue)
			local full_text = area_data.full_text
			local short_text = area_data.short_text

			self:_present_new_area(full_text, short_text)
		end
	end
end

function HudElementAreaNotificationPopup:event_player_set_new_location(player, full_text, short_text)
	if not self._player or self._player ~= player then
		return
	end

	if self._popup_animation_id then
		table.insert(self._area_notificactions_queue, 1, {
			full_text = full_text,
			short_text = short_text
		})
	else
		self:_present_new_area(full_text, short_text)
	end
end

function HudElementAreaNotificationPopup:_present_new_area(full_text_unlocalized, short_text_unlocalized)
	local widgets_by_name = self._widgets_by_name
	local widget = widgets_by_name.area_popup
	local content = widget.content
	content.title_text = self:_localize(full_text_unlocalized)
	content.description_text = self:_localize(short_text_unlocalized)
	local popup_animation_id = self:_start_animation("popup_enter", widgets_by_name)
	self._popup_animation_id = popup_animation_id

	self:_play_sound(UISoundEvents.area_notification_popup_enter)
end

function HudElementAreaNotificationPopup:_draw_widgets(dt, t, input_service, ui_renderer, render_settings)
	if not self._popup_animation_id then
		return
	end

	HudElementAreaNotificationPopup.super._draw_widgets(self, dt, t, input_service, ui_renderer, render_settings)
end

function HudElementAreaNotificationPopup:_register_events()
	local event_manager = Managers.event
	local events = HudElementAreaNotificationPopupSettings.events

	for i = 1, #events do
		local event = events[i]

		event_manager:register(self, event[1], event[2])
	end
end

function HudElementAreaNotificationPopup:_unregister_events()
	local event_manager = Managers.event
	local events = HudElementAreaNotificationPopupSettings.events

	for i = 1, #events do
		local event = events[i]

		event_manager:unregister(self, event[1])
	end
end

return HudElementAreaNotificationPopup
