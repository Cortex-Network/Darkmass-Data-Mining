local RootCamera = require("scripts/managers/camera/cameras/root_camera")
local TestifyCamera = class("TestifyCamera", "RootCamera")
TestifyCamera.CAMERA_NODE_ID = 1

function TestifyCamera:init(root_node)
	RootCamera.init(self, root_node)
end

function TestifyCamera:set_root_unit(unit, object, preserve_yaw)
	RootCamera.set_root_unit(self, unit, object, preserve_yaw)

	self._root_camera = Unit.camera(self._root_unit, self.CAMERA_NODE_ID)
end

function TestifyCamera:near_range()
	return Camera.near_range(self._root_camera)
end

function TestifyCamera:far_range()
	return Camera.far_range(self._root_camera)
end

return TestifyCamera
