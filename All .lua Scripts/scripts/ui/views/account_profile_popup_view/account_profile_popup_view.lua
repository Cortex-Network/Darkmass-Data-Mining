local Definitions = require("scripts/ui/views/account_profile_popup_view/account_profile_popup_view_definitions")
local AccountProfilePopupView = class("AccountProfilePopupView", "BaseView")

function AccountProfilePopupView:init(settings, context)
	self._context = context

	AccountProfilePopupView.super.init(self, Definitions, settings)

	self._pass_input = false
	self._parent = context and context.parent

	if self._parent then
		self._parent:cb_set_active_popup_instance(self)
	end
end

function AccountProfilePopupView:on_enter()
	AccountProfilePopupView.super.on_enter(self)
	self:_populate_popup(self._context)
	self:_start_animation("open_view")
end

function AccountProfilePopupView:on_exit()
	AccountProfilePopupView.super.on_exit(self)
end

function AccountProfilePopupView:close_view()
	if not self._is_closing then
		self._is_closing = true
		local view_name = self.view_name

		local function on_done_callback()
			Managers.ui:close_view(view_name)
		end

		self:_start_animation("close_view", nil, , on_done_callback)
	end
end

function AccountProfilePopupView:_handle_input(input_service, dt, t)
	if input_service:get("left_pressed") then
		if not self._widgets_by_name.background.content.hotspot.is_hover then
			self:close_view()
		end
	elseif input_service:get("back") then
		self:close_view()
	end
end

function AccountProfilePopupView:_start_fade_animation(name, on_done_callback)
	local animation_parameters = {
		start_height = self._start_height,
		popup_area_height = self._menu_height
	}

	self:_start_animation(name, nil, animation_parameters, on_done_callback)
end

function AccountProfilePopupView:_populate_popup(context)
	local widgets_by_name = self._widgets_by_name
	local icon_widget = widgets_by_name.icon

	if context.icon then
		icon_widget.content.icon = context.icon
	else
		icon_widget.content.visible = false
	end

	local headline_widget = widgets_by_name.headline
	headline_widget.content.text = self:_localize(context.headline)
end

return AccountProfilePopupView
