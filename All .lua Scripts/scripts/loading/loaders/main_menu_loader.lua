local views_to_load = {
	"main_menu_view",
	"main_menu_background_view",
	"character_appearance_view",
	"class_selection_view",
	"options_view",
	"news_view",
	"system_view"
}
local MainMenuLoader = class("MainMenuLoader")

function MainMenuLoader:init()
	self._load_done = false
end

function MainMenuLoader:destroy()
	self:cleanup()
end

function MainMenuLoader:start_loading()
	local ui_manager = Managers.ui

	if ui_manager then
		self._num_views_loading = #views_to_load

		local function callback()
			self._num_views_loading = self._num_views_loading - 1

			if self._num_views_loading == 0 then
				self:_load_done_callback()
			end
		end

		for i = 1, #views_to_load do
			local view_name = views_to_load[i]

			ui_manager:load_view(view_name, "MainMenuLoader - " .. view_name, callback)
		end
	else
		self:_load_done_callback()
	end
end

function MainMenuLoader:is_loading_done()
	return self._load_done
end

function MainMenuLoader:cleanup()
	if not self._unloaded then
		self._unloaded = true
		local ui_manager = Managers.ui

		if ui_manager then
			for i = 1, #views_to_load do
				local view_name = views_to_load[i]

				ui_manager:unload_view(view_name, "MainMenuLoader - " .. view_name)
			end
		end
	end

	self._load_done = false
end

function MainMenuLoader:_load_done_callback()
	self._load_done = true
end

return MainMenuLoader
