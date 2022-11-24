local ImguiResourceEventsGui = class("ImguiResourceEventsGui")

function ImguiResourceEventsGui:init(...)
	self._input_manager = Managers.input
end

function ImguiResourceEventsGui:_subwindow_count()
	return 0
end

function ImguiResourceEventsGui:update(dt, t)
end

return ImguiResourceEventsGui
