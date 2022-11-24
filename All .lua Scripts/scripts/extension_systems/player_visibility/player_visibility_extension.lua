local PlayerVisibilityExtension = class("PlayerVisibilityExtension")

function PlayerVisibilityExtension:init(extension_init_context, unit, extension_init_data, ...)
	self._is_visible = true
	self._unit = unit
	self._first_person_unit = nil
	local first_person_extension = ScriptUnit.has_extension(unit, "first_person_system")

	if first_person_extension then
		self._first_person_unit = first_person_extension:first_person_unit()
	end
end

function PlayerVisibilityExtension:visible()
	return self._is_visible
end

function PlayerVisibilityExtension:hide()
	if self._is_visible then
		self:_take_snapshot()
		Unit.set_unit_visibility(self._unit, false, true)

		if self._first_person_unit then
			Unit.set_unit_visibility(self._first_person_unit, false, true)
		end

		self._is_visible = false
	end
end

function PlayerVisibilityExtension:show()
	if not self._is_visible then
		self:_restore_snapshot()

		self._is_visible = true
	end
end

function PlayerVisibilityExtension:_take_snapshot()
	Unit.take_visibility_snapshot({
		self._unit
	})

	if self._first_person_unit then
		Unit.take_visibility_snapshot({
			self._first_person_unit
		})
	end
end

function PlayerVisibilityExtension:_restore_snapshot()
	Unit.restore_visibility_snapshot({
		self._unit
	})

	if self._first_person_unit then
		Unit.restore_visibility_snapshot({
			self._first_person_unit
		})
	end
end

function PlayerVisibilityExtension:update_visibility_snapshot()
	if not self._is_visible then
		self:show()
		self:hide()
	end
end

return PlayerVisibilityExtension
