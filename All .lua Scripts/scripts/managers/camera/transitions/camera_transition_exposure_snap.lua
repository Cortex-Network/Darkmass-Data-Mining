require("scripts/managers/camera/transitions/camera_transition_base")

local CameraTransitionExposureSnap = class("CameraTransitionExposureSnap", "CameraTransitionBase")

function CameraTransitionExposureSnap:init(node_1, node_2, duration, speed)
end

function CameraTransitionExposureSnap:update(dt, update_time)
	local value = true
	local done = true

	return value, done
end

return CameraTransitionExposureSnap
