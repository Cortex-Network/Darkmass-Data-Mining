local CameraTransitionBase = class("CameraTransitionBase")

function CameraTransitionBase:init(node_1, node_2, duration, speed, settings)
	self._node_1 = node_1
	self._node_2 = node_2
	self._duration = duration
	self._speed = speed
	self._start_time = Managers.time:time("main")
	self._time = 0
	self._on_complete_func = settings.on_complete_func
end

function CameraTransitionBase:update(dt, update_time)
	if update_time then
		self._time = Managers.time:time("main") - self._start_time
	end
end

function CameraTransitionBase:on_complete()
	if self._on_complete_func then
		self._on_complete_func()
	end
end

return CameraTransitionBase
