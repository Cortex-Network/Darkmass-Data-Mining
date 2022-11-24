local definition_path = "scripts/ui/hud/elements/team_player_panel/hud_element_team_player_panel_definitions"
local HudElementTeamPlayerPanelSettings = require("scripts/ui/hud/elements/team_player_panel/hud_element_team_player_panel_settings")
local HudElementTeamPlayerPanel = class("HudElementTeamPlayerPanel", "HudElementPlayerPanelBase")

function HudElementTeamPlayerPanel:init(parent, draw_layer, start_scale, data)
	HudElementTeamPlayerPanel.super.init(self, parent, draw_layer, start_scale, data, definition_path, HudElementTeamPlayerPanelSettings)
end

function HudElementTeamPlayerPanel:update(dt, t, ui_renderer, render_settings, input_service)
	HudElementTeamPlayerPanel.super.update(self, dt, t, ui_renderer, render_settings, input_service)
end

function HudElementTeamPlayerPanel:draw(dt, t, ui_renderer, render_settings, input_service)
	HudElementTeamPlayerPanel.super.draw(self, dt, t, ui_renderer, render_settings, input_service)
end

return HudElementTeamPlayerPanel
