local WeaponIconAlignment = component("WeaponIconAlignment")

function WeaponIconAlignment:init(unit)
end

function WeaponIconAlignment:editor_init(unit)
	local in_editor = true
	local world = Unit.world(unit)
	self._item_definitions = self:_get_item_definitions(unit, world, in_editor)
end

function WeaponIconAlignment:enable(unit)
end

function WeaponIconAlignment:get_item_definitions(unit)
	local item_definitions = {}

	if EditorMasterItems then
		EditorMasterItems.memoize(LocalLoader.get_items_from_metadata_db):next(function (data)
			self:enable(unit, data)
		end)
	else
		Log.error("WeaponIconAlignment", "EditorMasterItems not defined, missing master_items plugin?")
	end

	return item_definitions
end

function WeaponIconAlignment:disable(unit)
end

function WeaponIconAlignment:destroy(unit)
end

function WeaponIconAlignment:update(unit, dt, t)
end

function WeaponIconAlignment:editor_update(unit, dt, t)
end

function WeaponIconAlignment:changed(unit)
end

function WeaponIconAlignment:editor_changed(unit)
end

function WeaponIconAlignment:editor_world_transform_modified(unit)
end

function WeaponIconAlignment:editor_selection_changed(unit, selected)
end

function WeaponIconAlignment:editor_reset_physics(unit)
end

function WeaponIconAlignment:editor_property_changed(unit)
end

function WeaponIconAlignment:editor_on_level_spawned(unit, level)
end

function WeaponIconAlignment:editor_on_set_debug_draw(enabled)
end

WeaponIconAlignment.component_data = {}

return WeaponIconAlignment
