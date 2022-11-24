local HumanUnitInput = class("HumanUnitInput")

function HumanUnitInput:init(player, input_handler, fixed_frame)
	self._player = player
	self._input_handler = input_handler
	self._frame = fixed_frame
end

function HumanUnitInput:fixed_update(unit, dt, t, frame)
	self._frame = frame
end

function HumanUnitInput:get_orientation()
	local frame = self._frame

	return self._input_handler:get_orientation(frame)
end

function HumanUnitInput:get(action)
	local frame = self._frame

	if action == "move" then
		local input = self._input_handler
		local right = input:get("move_right", frame)
		local left = input:get("move_left", frame)
		local forward = input:get("move_forward", frame)
		local backward = input:get("move_backward", frame)

		return Vector3(right - left, forward - backward, 0)
	else
		return self._input_handler:get(action, frame)
	end
end

function HumanUnitInput:had_received_input(fixed_frame)
	return self._input_handler:had_received_input(fixed_frame)
end

return HumanUnitInput
