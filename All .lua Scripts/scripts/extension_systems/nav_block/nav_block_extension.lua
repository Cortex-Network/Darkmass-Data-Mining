local NavBlockExtension = class("NavBlockExtension")

function NavBlockExtension:init(extension_init_context, unit, extension_init_data, ...)
	self._unit = unit
	self._is_server = extension_init_context.is_server
	self._start_blocked = nil
	self._layer_name = ""

	self:_setup_nav_gate(unit, not self._start_blocked)
end

function NavBlockExtension:destroy()
	if self._is_server then
		local nav_mesh_manager = Managers.state.nav_mesh
		local layer_name = self._layer_name

		if not nav_mesh_manager:is_nav_tag_volume_layer_allowed(layer_name) then
			nav_mesh_manager:set_allowed_nav_tag_layer(layer_name, true)
		end
	end
end

function NavBlockExtension:setup_from_component(start_blocked)
	self:set_start_blocked(start_blocked)
end

function NavBlockExtension:set_start_blocked(start_blocked)
	self._start_blocked = start_blocked
end

function NavBlockExtension:update(unit, dt, t)
	if self._is_server and self._start_blocked ~= nil then
		self:set_block(self._start_blocked)

		self._start_blocked = nil
	end
end

function NavBlockExtension:set_block(block)
	local nav_mesh_manager = Managers.state.nav_mesh
	local is_allowed = not block

	nav_mesh_manager:set_allowed_nav_tag_layer(self._layer_name, is_allowed)
end

function NavBlockExtension:_get_volume_alt_min_max(volume_points, volume_height)
	local alt_min, alt_max = nil

	for i = 1, #volume_points do
		local alt = volume_points[i].z

		if not alt_min or alt < alt_min then
			alt_min = alt
		end

		if not alt_max or alt_max < alt + volume_height then
			alt_max = alt + volume_height
		end
	end

	return alt_min, alt_max
end

function NavBlockExtension:_setup_nav_gate(unit, layer_allowed)
	local unit_level_index = Managers.state.unit_spawner:level_index(unit)
	local layer_name = "nav_block_volume_" .. tostring(unit_level_index)
	local volume_points = Unit.volume_points(unit, "g_volume_block")
	local volume_height = Unit.volume_height(unit, "g_volume_block")
	local volume_alt_min, volume_alt_max = self:_get_volume_alt_min_max(volume_points, volume_height)

	Managers.state.nav_mesh:add_nav_tag_volume(volume_points, volume_alt_min, volume_alt_max, layer_name, layer_allowed)

	self._layer_name = layer_name
end

return NavBlockExtension
