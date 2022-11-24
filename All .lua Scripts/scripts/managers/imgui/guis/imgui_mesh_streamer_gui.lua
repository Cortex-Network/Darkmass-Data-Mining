local ImguiMeshStreamerGui = class("ImguiMeshStreamerGui")

function ImguiMeshStreamerGui:init(...)
	self._input_manager = Managers.input
end

function ImguiMeshStreamerGui:_subwindow_count()
	return 0
end

function ImguiMeshStreamerGui:update(dt, t)
	Renderer.render_mesh_streamer_imgui()
end

return ImguiMeshStreamerGui
