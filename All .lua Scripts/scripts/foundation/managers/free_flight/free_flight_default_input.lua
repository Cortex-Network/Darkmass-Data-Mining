local FreeFlightDefaultInput = class("FreeFlightDefaultInput")

function FreeFlightDefaultInput:frustum_toggle()
	return Keyboard.pressed(Keyboard.button_index("f10"))
end

function FreeFlightDefaultInput:global_toggle()
	return Keyboard.pressed(Keyboard.button_index("f9"))
end

function FreeFlightDefaultInput:top_down_toggle()
	return Keyboard.pressed(Keyboard.button_index("f8"))
end

function FreeFlightDefaultInput:look()
	return Mouse.axis(0) + Pad1.axis(1)
end

function FreeFlightDefaultInput:move_right()
	return Keyboard.button(Keyboard.button_index("d")) + math.min(Vector3.x(Pad1.axis(0)), 0)
end

function FreeFlightDefaultInput:move_left()
	return Keyboard.button(Keyboard.button_index("a")) + math.min(-Vector3.x(Pad1.axis(0)), 0)
end

function FreeFlightDefaultInput:move_forward()
	return Keyboard.button(Keyboard.button_index("w")) + math.min(Vector3.y(Pad1.axis(0)), 0)
end

function FreeFlightDefaultInput:move_backward()
	return Keyboard.button(Keyboard.button_index("s")) + math.min(-Vector3.y(Pad1.axis(0)), 0)
end

function FreeFlightDefaultInput:move_up()
	return Keyboard.button(Keyboard.button_index("e"))
end

function FreeFlightDefaultInput:move_down()
	return Keyboard.button(Keyboard.button_index("q"))
end

function FreeFlightDefaultInput:increase_fov()
	return Keyboard.pressed(Keyboard.button_index("numpad +"))
end

function FreeFlightDefaultInput:decrease_fov()
	return Keyboard.pressed(Keyboard.button_index("num -"))
end

function FreeFlightDefaultInput:toggle_dof()
	return Keyboard.pressed(Keyboard.button_index("f"))
end

function FreeFlightDefaultInput:reset_dof()
	return Keyboard.button(Keyboard.button_index("f")) > 0.5 and Keyboard.button(Keyboard.button_index("left ctrl")) > 0.5
end

function FreeFlightDefaultInput:inc_dof_distance()
	return Keyboard.button(Keyboard.button_index("g")) > 0.5
end

function FreeFlightDefaultInput:dec_dof_distance()
	return Keyboard.button(Keyboard.button_index("b")) > 0.5
end

function FreeFlightDefaultInput:inc_dof_region()
	return Keyboard.button(Keyboard.button_index("h")) > 0.5
end

function FreeFlightDefaultInput:dec_dof_region()
	return Keyboard.button(Keyboard.button_index("n")) > 0.5
end

function FreeFlightDefaultInput:inc_dof_padding()
	return Keyboard.button(Keyboard.button_index("j")) > 0.5
end

function FreeFlightDefaultInput:dec_dof_padding()
	return Keyboard.button(Keyboard.button_index("m")) > 0.5
end

function FreeFlightDefaultInput:inc_dof_scale()
	return Keyboard.button(Keyboard.button_index("k")) > 0.5
end

function FreeFlightDefaultInput:dec_dof_scale()
	return Keyboard.button(Keyboard.button_index("oem_comma (< ,)")) > 0.5
end

function FreeFlightDefaultInput:speed_change()
	local wheel_axis = Mouse.axis_index("wheel")

	return Vector3.y(Mouse.axis(wheel_axis))
end

function FreeFlightDefaultInput:get(action_name)
	local func = FreeFlightDefaultInput[action_name]

	return func(self)
end

local null_service = {
	get = function (self, action_name)
		local input_type = type(self.input:get(action_name))

		if input_type == "number" then
			return 0
		elseif input_type == "boolean" then
			return false
		elseif input_type == "Vector3" then
			return Vector3.zero()
		else
			ferror("unsupported input type %q for action %q", input_type, action_name)
		end
	end
}

function FreeFlightDefaultInput:null_service()
	null_service.input = self

	return null_service
end

return FreeFlightDefaultInput
