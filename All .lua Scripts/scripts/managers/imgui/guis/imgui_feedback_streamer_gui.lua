local ImguiFeedbackStreamerGui = class("ImguiFeedbackStreamerGui")

function ImguiFeedbackStreamerGui:init(...)
	self._input_manager = Managers.input
end

function ImguiFeedbackStreamerGui:_subwindow_count()
	return 0
end

function ImguiFeedbackStreamerGui:update(dt, t)
	Renderer.render_streamer_imgui()
end

return ImguiFeedbackStreamerGui
