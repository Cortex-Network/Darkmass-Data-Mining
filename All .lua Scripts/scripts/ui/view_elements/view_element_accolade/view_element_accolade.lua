local definition_path = "scripts/ui/view_elements/view_element_accolade/view_element_accolade_definitions"
local ViewElementAccoladeSettings = require("scripts/ui/view_elements/view_element_accolade/view_element_accolade_settings")
local AccoladePassTemplates = require("scripts/ui/pass_templates/accolade_pass_templates")
local UIWidget = require("scripts/managers/ui/ui_widget")
local ViewElementAccolade = class("ViewElementAccolade", "ViewElementBase")

function ViewElementAccolade:init(parent, draw_layer, start_scale)
	local definitions = require(definition_path)

	ViewElementAccolade.super.init(self, parent, draw_layer, start_scale, definitions)

	self._template_widget = self:_create_template_widget("player_of_the_game")
end

function ViewElementAccolade:set_alpha_multiplier(alpha_multiplier)
	self._alpha_multiplier = alpha_multiplier
end

function ViewElementAccolade:set_pivot_offset(x, y)
	self:_set_scenegraph_position("pivot", x, y)
end

function ViewElementAccolade:_create_template_widget(template_type)
	local scenegraph_id = "canvas"
	local pass_template = AccoladePassTemplates[template_type]
	local widget_definition = pass_template and UIWidget.create_definition(pass_template, scenegraph_id)
	local widget = self:_create_widget("accolade_template", widget_definition)
	local is_new = true
	local title_key = nil

	if is_new then
		local new_str = "{#color(255,242,0)}" .. self:_localize("loc_accolade_title_tag_new") .. "{#reset()}"
		local no_cache = true
		local localization_str = "loc_accolade_title_player_of_the_game_new"
		title_key = self:_localize(localization_str, no_cache, {
			new = new_str
		})
	else
		local localization_str = "loc_accolade_title_player_of_the_game"
		title_key = self:_localize(localization_str)
	end

	local content = widget.content
	content.title = title_key
	local level = 1
	content.sub_title = self:_localize("loc_accolade_sub_title_tag_level") .. tostring(level)

	return widget
end

function ViewElementAccolade:update(dt, t, input_service)
	return ViewElementAccolade.super.update(self, dt, t, input_service)
end

function ViewElementAccolade:_draw_widgets(dt, t, input_service, ui_renderer, render_settings)
	local previous_alpha_multiplier = render_settings.alpha_multiplier
	render_settings.alpha_multiplier = self._alpha_multiplier

	ViewElementAccolade.super._draw_widgets(self, dt, t, input_service, ui_renderer, render_settings)
	UIWidget.draw(self._template_widget, ui_renderer)

	render_settings.alpha_multiplier = previous_alpha_multiplier
end

return ViewElementAccolade
