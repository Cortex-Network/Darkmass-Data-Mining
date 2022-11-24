local InputUtils = require("scripts/managers/input/input_utils")
local InputDevice = class("InputDevice")
InputDevice.DEFAULT_HELD_THRESHOLD = InputDevice.DEFAULT_HELD_THRESHOLD or 0.5
InputDevice.last_pressed_of_type = {}
InputDevice.last_pressed_device = nil
InputDevice.default_device_id = InputDevice.default_device_id or {}
InputDevice.gamepad_active = nil

function InputDevice:init(raw_device, device_type, slot)
	self.device_type = device_type
	self.slot = slot
	self._raw_device = raw_device
	self._default_held_threshold = InputDevice.DEFAULT_HELD_THRESHOLD
	self._active = raw_device:active()
	self._last_press_event = 0
	self._is_gamepad = InputUtils.is_gamepad(device_type)
	InputDevice.last_pressed_device = InputDevice.last_pressed_device or self
	InputDevice.last_pressed_of_type[device_type] = InputDevice.last_pressed_of_type[device_type] or self

	if self._active and raw_device.device_id then
		self._device_id = raw_device.device_id()
	end

	if IS_XBS and device_type == "xbox_controller" and not InputDevice.gamepad_active then
		InputDevice.last_pressed_device = self
		InputDevice.last_pressed_of_type[device_type] = self
		InputDevice.gamepad_active = self._is_gamepad
	end
end

function InputDevice:update(dt, t)
	local old_state = self._active
	self._active = self._raw_device:active()

	if self._active and (self._raw_device.any_pressed() or self:_any_analog_input()) and self:_verify_device() then
		self._last_press_event = t
		InputDevice.last_pressed_device = self
		InputDevice.last_pressed_of_type[self.device_type] = self
		InputDevice.gamepad_active = self._is_gamepad
	end

	if not old_state and self._active then
		Managers.event:trigger("device_activated", self)
	elseif old_state and not self._active then
		Managers.event:trigger("device_deactivated", self)
	end
end

function InputDevice:can_rumble()
	if self.device_type == "xbox_controller" or self.device_type == "ps4_controller" then
		return true
	end

	return false
end

local VALID_AXES = {
	"left",
	"right",
	"mouse",
	"wheel"
}

function InputDevice:_any_analog_input()
	local input_device = self._raw_device

	for i = 1, #VALID_AXES do
		local axis_name = VALID_AXES[i]
		local axis_index = input_device.axis_index(axis_name)

		if axis_index then
			local value = input_device.axis(axis_index)

			if Vector3.length_squared(value) > 0 then
				return true
			end
		end
	end
end

function InputDevice:_verify_device()
	if not IS_XBS then
		return true
	end

	local default_device_id = InputDevice.default_device_id[self.device_type]

	if not default_device_id then
		return true
	else
		self._device_id = self._raw_device.device_id()

		return default_device_id == self._device_id
	end
end

function InputDevice:last_pressed()
	return self._last_press_event
end

function InputDevice:active()
	return self._active
end

function InputDevice:slot()
	return self.slot
end

function InputDevice:held(id)
	return self._raw_device.button(id) > 0
end

function InputDevice:type()
	return self.device_type
end

function InputDevice:debug_name()
	if self.slot then
		return self.device_type .. "(" .. self.slot .. ")"
	end

	return self.device_type
end

function InputDevice:button_index(name)
	return InputUtils.button_index(name, self._raw_device, self.device_type)
end

function InputDevice:axis_index(name)
	return InputUtils.axis_index(name, self._raw_device, self.device_type)
end

function InputDevice:local_key_name(key)
	return InputUtils.local_key_name(key, self.device_type)
end

function InputDevice:local_to_global_name(local_name)
	return InputUtils.local_to_global_name(local_name, self.device_type)
end

function InputDevice:raw_device()
	return self._raw_device
end

function InputDevice:set_default_held_threshold(threshold)
	self._default_held_threshold = threshold
end

function InputDevice:buttons_held()
	local raw_device = self._raw_device
	local num = math.min(raw_device.num_buttons(), 255)
	local button_list = {}

	for i = 0, num - 1 do
		if raw_device.button(i) > 0 then
			local raw_name = raw_device.button_name(i)
			local global_name = self:local_to_global_name(raw_name)

			table.insert(button_list, global_name)
		end
	end

	return button_list
end

function InputDevice:buttons_released()
	local raw_device = self._raw_device
	local num = math.min(raw_device.num_buttons(), 255)
	local button_list = {}

	for i = 0, num - 1 do
		if raw_device.released(i) then
			local raw_name = raw_device.button_name(i)
			local global_name = self:local_to_global_name(raw_name)

			table.insert(button_list, global_name)
		end
	end

	return button_list
end

return InputDevice
