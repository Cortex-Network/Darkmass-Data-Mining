local Definitions = require("scripts/ui/views/cutscene_view/cutscene_view_definitions")
local CutsceneViewSettings = require("scripts/ui/views/cutscene_view/cutscene_view_settings")
local UIRenderer = require("scripts/managers/ui/ui_renderer")
local CutsceneView = class("CutsceneView", "BaseView")

function CutsceneView:init(settings, context)
	self._context = context

	CutsceneView.super.init(self, Definitions, settings)

	self._pass_input = false
	self._can_exit = not context or context.can_exit
end

function CutsceneView:on_enter()
	CutsceneView.super.on_enter(self)
	self:_set_background_visibility(false)
end

function CutsceneView:is_using_input()
	return true
end

function CutsceneView:_set_background_visibility(visible)
	self._widgets_by_name.background.content.visible = visible
end

function CutsceneView:update(dt, t, input_service)
	local pass_input, pass_draw = CutsceneView.super.update(self, dt, t, input_service)

	return pass_input, pass_draw
end

function CutsceneView:can_exit()
	return self._can_exit
end

local system_name = "dialogue_system"

function CutsceneView:dialogue_system()
	local state_managers = Managers.state

	if state_managers then
		local extension_manager = state_managers.extension

		return extension_manager and extension_manager:has_system(system_name) and extension_manager:system(system_name)
	end
end

return CutsceneView
