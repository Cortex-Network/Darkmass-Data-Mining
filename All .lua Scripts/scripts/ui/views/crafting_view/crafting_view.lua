local CraftingViewDefinitions = require("scripts/ui/views/crafting_view/crafting_view_definitions")
local UIRenderer = require("scripts/managers/ui/ui_renderer")

require("scripts/ui/views/vendor_interaction_view_base/vendor_interaction_view_base")

local CraftingView = class("CraftingView", "VendorInteractionViewBase")

function CraftingView:init(settings, context)
	self._wallet_type = {
		"diamantine",
		"plasteel",
		"credits"
	}

	CraftingView.super.init(self, CraftingViewDefinitions, settings, context)

	local ui_renderer = self._ui_renderer
	ui_renderer.render_pass_flag = "render_pass"
	ui_renderer.base_render_pass = "to_screen"
end

function CraftingView:go_to_crafting_view(view_name, item)
	local tab_data = CraftingViewDefinitions.crafting_tab_params[view_name]
	local context = {
		item = item,
		ui_renderer = self._ui_renderer
	}

	self:_setup_tab_bar(tab_data, context)
end

function CraftingView:on_enter()
	CraftingView.super.on_enter(self)

	local narrative_manager = Managers.narrative
	local narrative_event_name = "level_unlock_crafting_station_visited"

	if narrative_manager:can_complete_event(narrative_event_name) then
		narrative_manager:complete_event(narrative_event_name)
	end

	self:play_vo_events({
		"hub_idle_crafting"
	}, "tech_priest_a", nil, 0.8)
end

function CraftingView:_setup_tab_bar(tab_bar_params, additional_context)
	CraftingView.super._setup_tab_bar(self, tab_bar_params, additional_context)

	local alpha = #tab_bar_params.tabs_params > 0 and 175 or 0
	self._wanted_overlay_alpha = alpha
end

function CraftingView:update(dt, t, input_service)
	local overlay_style_color = self._widgets_by_name.overlay.style.overlay.color
	overlay_style_color[1] = math.lerp(self._wanted_overlay_alpha or 0, overlay_style_color[1], 1e-05^dt)

	return CraftingView.super.update(self, dt, t, input_service)
end

function CraftingView:draw(dt, t, input_service, layer)
	UIRenderer.clear_render_pass_queue(self._ui_renderer)
	UIRenderer.add_render_pass(self._ui_renderer, 1, "to_screen", false)
	CraftingView.super.draw(self, dt, t, input_service, layer)
end

function CraftingView:on_exit()
	CraftingView.super.on_exit(self)

	local level = Managers.state.mission and Managers.state.mission:mission_level()

	if level then
		Level.trigger_event(level, "lua_crafting_store_closed")
	end
end

function CraftingView:set_crafting_costs(crafting_costs)
	self._crafting_costs = crafting_costs
end

function CraftingView:crafting_costs()
	return self._crafting_costs
end

function CraftingView:update_wallets()
	self:_update_wallets()

	return self._wallet_promise
end

return CraftingView
