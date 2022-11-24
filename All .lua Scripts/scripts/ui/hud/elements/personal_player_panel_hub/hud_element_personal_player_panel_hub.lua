local definition_path = "scripts/ui/hud/elements/personal_player_panel_hub/hud_element_personal_player_panel_hub_definitions"
local HudElementPersonalPlayerPanelHubSettings = require("scripts/ui/hud/elements/personal_player_panel_hub/hud_element_personal_player_panel_hub_settings")
local HudElementPersonalPlayerPanelHub = class("HudElementPersonalPlayerPanelHub", "HudElementPlayerPanelBase")

function HudElementPersonalPlayerPanelHub:init(parent, draw_layer, start_scale, data)
	HudElementPersonalPlayerPanelHub.super.init(self, parent, draw_layer, start_scale, data, definition_path, HudElementPersonalPlayerPanelHubSettings)
end

function HudElementPersonalPlayerPanelHub:update(dt, t, ui_renderer, render_settings, input_service)
	HudElementPersonalPlayerPanelHub.super.update(self, dt, t, ui_renderer, render_settings, input_service)
end

function HudElementPersonalPlayerPanelHub:draw(dt, t, ui_renderer, render_settings, input_service)
	HudElementPersonalPlayerPanelHub.super.draw(self, dt, t, ui_renderer, render_settings, input_service)
end

return HudElementPersonalPlayerPanelHub
