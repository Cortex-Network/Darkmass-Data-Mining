local ChainSwordSpin = component("ChainSwordSpin")
local DEFAULT_MIN_SPEED = 1

function ChainSwordSpin:init(unit)
	if not Unit.has_animation_state_machine(unit) then
		return
	end

	self._unit = unit
	self._speed = Unit.get_data(unit, "speed")
	self._speed_variable_index = Unit.animation_find_variable(unit, "speed")

	self:_set_speed()
end

function ChainSwordSpin:_set_speed(speed)
	speed = speed or DEFAULT_MIN_SPEED
	self._speed = speed

	if self._speed >= 0 then
		Unit.animation_event(self._unit, "forward")
	else
		Unit.animation_event(self._unit, "backward")
	end

	if self._speed < 0 then
		self._speed = self._speed * -1
	end

	Unit.animation_set_variable(self._unit, self._speed_variable_index, self._speed)
end

function ChainSwordSpin:enable(unit)
end

function ChainSwordSpin:disable(unit)
end

function ChainSwordSpin:destroy(unit)
end

function ChainSwordSpin:update(unit, dt, t)
end

function ChainSwordSpin:changed(unit)
end

function ChainSwordSpin.events:set_speed(speed)
	self:_set_speed(speed)
end

ChainSwordSpin.component_data = {
	inputs = {
		set_speed = {
			accessibility = "public",
			type = "event"
		}
	}
}

return ChainSwordSpin
