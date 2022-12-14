local MissionPathBlocker = component("MissionPathBlocker")

function MissionPathBlocker:init(unit, is_server)
	self._unit = unit
	self._is_server = is_server
	self._enabled = true
end

function MissionPathBlocker:destroy(unit)
end

function MissionPathBlocker:enable(unit)
	if self._enabled then
		return
	end

	if self._is_server then
		local nav_graph_extension = ScriptUnit.fetch_component_extension(self._unit, "nav_graph_system")

		nav_graph_extension:add_nav_graphs_to_database()

		local nav_block_extension = ScriptUnit.fetch_component_extension(self._unit, "nav_block_system")

		nav_block_extension:set_start_blocked(true)
	end

	Unit.set_unit_visibility(self._unit, true)

	for ii = 1, Unit.num_actors(self._unit) do
		local actor = Unit.actor(self._unit, ii)

		Unit.create_actor(self._unit, actor)
	end

	self._enabled = true
end

function MissionPathBlocker:disable(unit)
	if not self._enabled then
		return
	end

	if self._is_server then
		local nav_graph_extension = ScriptUnit.fetch_component_extension(self._unit, "nav_graph_system")

		nav_graph_extension:remove_nav_graphs_from_database()

		local nav_block_extension = ScriptUnit.fetch_component_extension(self._unit, "nav_block_system")

		nav_block_extension:set_start_blocked(false)
	end

	Unit.set_unit_visibility(self._unit, false)

	for ii = 1, Unit.num_actors(self._unit) do
		local actor = Unit.actor(self._unit, ii)

		Unit.destroy_actor(self._unit, actor)
	end

	self._enabled = false
end

function MissionPathBlocker:mission_path_blocker_closed()
	self:enable()
end

function MissionPathBlocker:mission_path_blocker_open()
	self:disable()
end

MissionPathBlocker.component_data = {
	inputs = {
		mission_path_blocker_open = {
			accessibility = "public",
			type = "event"
		}
	},
	extensions = {}
}

return MissionPathBlocker
