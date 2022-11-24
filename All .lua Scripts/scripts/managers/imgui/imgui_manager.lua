local InputDebug = require("scripts/managers/input/input_debug")
local ImguiManager = class("ImguiManager")
local States = {
	MainView = 1,
	TempView = 2
}

function ImguiManager:init()
	self._guis = {}
	self._active_guis = {
		[States.MainView] = {},
		[States.TempView] = {}
	}
	self._state = States.Disabled

	self:_load_active_guis()
	self:_setup_input()
end

function ImguiManager:destroy()
	for _, gui in pairs(self._guis) do
		gui.instance:delete()
	end
end

function ImguiManager:_load_active_guis()
	local active_guis = self._active_guis[States.MainView]
	local saved_active_guis = Application.user_setting("imgui", "main_view_active_guis") or {}

	for _, gui_name in pairs(saved_active_guis) do
		active_guis[gui_name] = true
	end
end

function ImguiManager:_save_active_guis()
	local guis = self._guis
	local active_guis = self._active_guis[States.MainView]
	local save_data = {}

	for gui_name, is_active in pairs(active_guis) do
		if is_active and guis[gui_name] then
			save_data[#save_data + 1] = gui_name
		end
	end

	Application.set_user_setting("imgui", "main_view_active_guis", save_data)
	Application.save_user_settings()
end

function ImguiManager:_setup_input()
	local input_manager = Managers.input
	self._input_manager = input_manager
	self._input = input_manager:get_input_service("Imgui")

	self:_enable_imgui_input()
end

function ImguiManager.imgui_available()
	return Imgui.enable_imgui_input_system ~= nil and Imgui.enable_keyboard_navigation ~= nil
end

function ImguiManager:_enable_imgui_input()
	Imgui.enable_imgui_input_system(Imgui.MOUSE)
	Imgui.enable_imgui_input_system(Imgui.KEYBOARD)
	Imgui.enable_imgui_input_system(Imgui.GAMEPAD)
	Imgui.enable_keyboard_navigation()

	self._using_input = true
end

function ImguiManager:_disable_imgui_input()
	Imgui.disable_imgui_input_system(Imgui.MOUSE)
	Imgui.disable_imgui_input_system(Imgui.KEYBOARD)
	Imgui.disable_imgui_input_system(Imgui.GAMEPAD)
	Imgui.disable_keyboard_navigation()

	self._using_input = false
end

function ImguiManager:is_active()
	return self._state ~= States.Disabled
end

function ImguiManager:using_input()
	return self:is_active() and self._using_input
end

function ImguiManager:add_gui(name, hotkey_action, class_type, ...)
	local instance = class_type:new(...)
	local hotkey_lookup = hotkey_action and self._input:reverse_lookup(hotkey_action)
	local hotkey_strings = {}

	if hotkey_lookup then
		for device, key in pairs(hotkey_lookup) do
			key = InputDebug.value_or_table_to_string(key, true)
			hotkey_strings[device] = string.format("[%s]", key)
		end
	end

	self._guis[name] = {
		instance = instance,
		hotkey_strings = hotkey_strings,
		hotkey_action = hotkey_action
	}
end

function ImguiManager:resize_gui(gui_name, width, height)
	local gui = self._guis[gui_name]
	gui.resize = {
		width,
		height
	}
end

function ImguiManager:update(dt, t)
	self:_handle_input()

	if self:is_active() then
		self:_render(dt, t)
	end
end

function ImguiManager:disable()
	if self._state ~= States.Disabled then
		self:_set_state(States.Disabled)
	end
end

function ImguiManager:_set_state(new_state)
	local state = self._state

	if state == States.TempView then
		table.clear(self._active_guis[States.TempView])
	elseif state == States.MainView then
		self:_save_active_guis()
	end

	if new_state == States.Disabled then
		Imgui.close_imgui()
		Managers.input:pop_cursor("ImguiManager")
	elseif self._state == States.Disabled then
		Imgui.open_imgui()
		Managers.input:push_cursor("ImguiManager")
	end

	self._state = new_state
end

function ImguiManager:_activate_gui(state, gui_name)
	local active_guis = self._active_guis[state]
	active_guis[gui_name] = true

	self:_gui_on_activated(gui_name)
end

function ImguiManager:_deactivate_gui(state, gui_name)
	local active_guis = self._active_guis[state]
	active_guis[gui_name] = nil

	self:_gui_on_deactivated(gui_name)
end

function ImguiManager:_gui_on_activated(gui_name)
	local gui = self._guis[gui_name]

	if gui.instance.on_activated then
		gui.instance:on_activated()
	end
end

function ImguiManager:_gui_on_deactivated(gui_name)
	local gui = self._guis[gui_name]

	if gui.instance.on_deactivated then
		gui.instance:on_deactivated()
	end
end

function ImguiManager:_handle_input()
	local input = self._input
	local state = self._state
	local guis = self._guis

	if input:get("toggle_input") then
		if self._using_input then
			self:_disable_imgui_input()
		else
			self:_enable_imgui_input()
		end

		Window.set_mouse_focus(not self._using_input)
		Window.set_clip_cursor(not self._using_input)
	elseif input:get("toggle_main_view") then
		if state ~= States.Disabled then
			local active_guis = self._active_guis[state]

			for gui_name, _ in pairs(active_guis) do
				self:_gui_on_deactivated(gui_name)
			end
		end

		if state == States.Disabled or state == States.TempView then
			state = States.MainView
		else
			state = States.Disabled
		end

		if state == States.MainView or state == States.TempView then
			local active_guis = self._active_guis[state]

			for gui_name, _ in pairs(active_guis) do
				self:_gui_on_activated(gui_name)
			end
		end

		self:_set_state(state)
	end

	if Managers.ui:chat_using_input() then
		return
	end

	for gui_name, gui in pairs(guis) do
		local hotkey_action = gui.hotkey_action

		if hotkey_action and input:get(hotkey_action) then
			if state == States.Disabled then
				state = States.TempView

				self:_set_state(state)
			end

			local active_guis = self._active_guis[state]

			if active_guis[gui_name] then
				self:_deactivate_gui(state, gui_name)
			else
				self:_activate_gui(state, gui_name)
			end

			if state == States.TempView and table.size(active_guis) == 0 then
				state = States.Disabled

				self:_set_state(state)
			end

			break
		end
	end
end

function ImguiManager:_render(dt, t)
	local state = self._state
	local guis = self._guis
	local active_guis = self._active_guis[state]
	local input_disabled = not self._using_input

	if input_disabled then
		Imgui.push_style_color(Imgui.COLOR_WINDOW_BG, 0, 0, 0, 160)
		Imgui.push_style_color(Imgui.COLOR_TITLE_BG, 40, 40, 40, 160)
		Imgui.push_style_color(Imgui.COLOR_TITLE_BG_ACTIVE, 40, 40, 40, 160)
		Imgui.push_style_color(Imgui.COLOR_TITLE_BG_COLLAPSED, 40, 40, 40, 160)
		Imgui.push_style_color(Imgui.COLOR_HEADER, 120, 120, 120, 100)
	end

	if state == States.MainView and Imgui.begin_main_menu_bar() then
		if Imgui.begin_menu("View") then
			for gui_name, gui in pairs(guis) do
				local is_active = active_guis[gui_name]
				local text = (is_active and "* " or "  ") .. gui_name

				if Imgui.menu_item(text) then
					if is_active then
						self:_deactivate_gui(state, gui_name)
					else
						self:_activate_gui(state, gui_name)
					end
				end

				local hotkey_string = gui.hotkey_strings.keyboard

				if hotkey_string then
					Imgui.same_line()
					Imgui.text(InputDebug.value_or_table_to_string(hotkey_string, true))
				end
			end

			Imgui.end_menu()
		end

		Imgui.end_main_menu_bar()
	end

	self:_render_guis(dt, t, active_guis)

	if input_disabled then
		Imgui.pop_style_color(5)
	end
end

function ImguiManager:post_render(dt, t)
	if self:is_active() then
		self:_post_update_render_guis(dt, t)
	end
end

function ImguiManager:_post_update_render_guis(dt, t)
	local guis = self._guis
	local state = self._state
	local active_guis = self._active_guis[state]

	for gui_name, _ in pairs(active_guis) do
		local gui = guis[gui_name]
		local has_post_update = gui and gui.instance.post_update

		if gui and has_post_update then
			local hotkey_string = gui.hotkey_strings.keyboard
			local window_name = string.format("%s %s###%s%s", gui_name, hotkey_string or "", gui_name, tostring(state))
			local resize = gui.resize

			if resize then
				Imgui.set_next_window_size(resize[1], resize[2])

				gui.resize = nil
			end

			local open, do_close = Imgui.begin_window(window_name)

			if open then
				gui.instance:post_update(dt, t)
			end

			Imgui.end_window()

			if do_close then
				self:_deactivate_gui(state, gui_name)

				if state == States.TempView and table.is_empty(self._active_guis[state]) then
					state = States.Disabled

					self:_set_state(state)
				end
			end
		end
	end
end

function ImguiManager:_render_guis(dt, t, guis_to_render)
	local guis = self._guis
	local state = self._state

	for gui_name, _ in pairs(guis_to_render) do
		local gui = guis[gui_name]

		if gui then
			local hotkey_string = gui.hotkey_strings.keyboard
			local window_name = string.format("%s %s###%s%s", gui_name, hotkey_string or "", gui_name, tostring(state))
			local resize = gui.resize

			if resize then
				Imgui.set_next_window_size(resize[1], resize[2])

				gui.resize = nil
			end

			local open, do_close = Imgui.begin_window(window_name, "menu_bar")

			if open then
				gui.instance:update(dt, t)
			end

			Imgui.end_window()

			if do_close then
				self:_deactivate_gui(state, gui_name)

				if state == States.TempView and table.is_empty(self._active_guis[state]) then
					state = States.Disabled

					self:_set_state(state)
				end
			end
		end
	end
end

return ImguiManager
