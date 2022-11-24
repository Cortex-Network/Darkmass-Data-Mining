local NavBlock = component("NavBlock")

function NavBlock:init(unit, is_server)
	self._is_server = is_server
	local nav_block_extension = ScriptUnit.fetch_component_extension(unit, "nav_block_system")

	if nav_block_extension then
		local start_blocked = self:get_data(unit, "start_blocked")

		nav_block_extension:setup_from_component(start_blocked)

		self._nav_block_extension = nav_block_extension
	end
end

function NavBlock:_set_block(val)
	local nav_block_extension = self._nav_block_extension

	if nav_block_extension and self._is_server then
		nav_block_extension:set_block(val)
	end
end

function NavBlock:editor_init(unit)
end

function NavBlock:enable(unit)
end

function NavBlock:disable(unit)
end

function NavBlock:destroy(unit)
end

function NavBlock:block_nav()
	self:_set_block(true)
end

function NavBlock:unblock_nav()
	self:_set_block(false)
end

NavBlock.component_data = {
	start_blocked = {
		ui_type = "check_box",
		value = true,
		ui_name = "Start blocked"
	},
	inputs = {
		block_nav = {
			accessibility = "public",
			type = "event"
		},
		unblock_nav = {
			accessibility = "public",
			type = "event"
		}
	},
	extensions = {
		"NavBlockExtension"
	}
}

return NavBlock
