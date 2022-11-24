local ImguiDenoising = class("ImguiDenoising")

function ImguiDenoising:init()
	self._input_manager = Managers.input
end

function ImguiDenoising:_subwindow_count()
	return 0
end

function ImguiDenoising:update(dt, t)
	Renderer.render_denoiser_imgui()
end

return ImguiDenoising
