local HudElementPrologueTutorialObjectivesTrackerSettings = require("scripts/ui/hud/elements/prologue_tutorial_step_tracker/hud_element_prologue_tutorial_step_tracker_settings")
local Definitions = require("scripts/ui/hud/elements/prologue_tutorial_step_tracker/hud_element_prologue_tutorial_step_tracker_definitions")
local UIWidget = require("scripts/managers/ui/ui_widget")
local HudElementPrologueStepTracker = class("HudElementPrologueStepTracker", "HudElementBase")

function HudElementPrologueStepTracker:init(parent, draw_layer, start_scale, definitions)
	HudElementPrologueStepTracker.super.init(self, parent, draw_layer, start_scale, Definitions)

	self._active = false
	self._player = parent:player()
	self._popup_queue = {}

	self:_register_events()
end

function HudElementPrologueStepTracker:destroy()
	self:_unregister_events()
	HudElementPrologueStepTracker.super.destroy(self)
end

function HudElementPrologueStepTracker:update(dt, t, ui_renderer, render_settings, input_service)
	HudElementPrologueStepTracker.super.update(self, dt, t, ui_renderer, render_settings, input_service)

	if self._popup_animation_id and not self:_is_animation_active(self._popup_animation_id) then
		self._popup_animation_id = nil

		if #self._popup_queue > 0 then
			if self._active then
				self:remove_step_tracker()
			else
				local area_data = table.remove(self._popup_queue, #self._popup_queue)
				local step_description = area_data.step_description

				self:_set_step_tracker_text(step_description)
			end
		end
	end
end

function HudElementPrologueStepTracker:event_player_add_step_tracker(step_description)
	if not step_description then
		return
	end

	if self._popup_animation_id or self._active then
		if self._popup_animation_id == nil then
			self:remove_step_tracker()
		end

		table.insert(self._popup_queue, 1, {
			step_description = step_description
		})
	else
		self:_set_step_tracker_text(step_description)
	end
end

function HudElementPrologueStepTracker:_set_step_tracker_text(step_description)
	local widgets_by_name = self._widgets_by_name
	local widget = widgets_by_name.step_tracker
	local content = widget.content
	content.description_text = Localize(step_description)
	self._popup_animation_id = self:_start_animation("add_entry", widget)
	self._active = true
end

function HudElementPrologueStepTracker:event_player_remove_tracker()
	if self._active and self._popup_animation_id == nil then
		self:remove_step_tracker()
	end
end

function HudElementPrologueStepTracker:remove_step_tracker()
	local widgets_by_name = self._widgets_by_name
	local widget = widgets_by_name.step_tracker
	self._popup_animation_id = self:_start_animation("remove_entry", widget)
	self._active = false
end

function HudElementPrologueStepTracker:on_objective_completed(objective_id)
	local widget = self._widgets_by_name[objective_id]

	self:_start_animation("on_complete", widget)
end

function HudElementPrologueStepTracker:_draw_widgets(dt, t, input_service, ui_renderer, render_settings)
	if not self._popup_animation_id and not self._active then
		return
	end

	HudElementPrologueStepTracker.super._draw_widgets(self, dt, t, input_service, ui_renderer, render_settings)
end

function HudElementPrologueStepTracker:_register_events()
	local event_manager = Managers.event
	local events = HudElementPrologueTutorialObjectivesTrackerSettings.events

	for i = 1, #events do
		local event = events[i]

		event_manager:register(self, event[1], event[2])
	end
end

function HudElementPrologueStepTracker:_unregister_events()
	local event_manager = Managers.event
	local events = HudElementPrologueTutorialObjectivesTrackerSettings.events

	for i = 1, #events do
		local event = events[i]

		event_manager:unregister(self, event[1])
	end
end

return HudElementPrologueStepTracker
