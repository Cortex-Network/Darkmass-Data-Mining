local ImguiParticleWorldGui = class("ImguiParticleWorldGui")

function ImguiParticleWorldGui:init(world, ...)
	self._input_manager = Managers.input
	self._world = world
end

function ImguiParticleWorldGui:_subwindow_count()
	return 0
end

function ImguiParticleWorldGui:update(dt, t)
	local world = self._world

	World.particles_draw_imgui_debug(world)
end

return ImguiParticleWorldGui
