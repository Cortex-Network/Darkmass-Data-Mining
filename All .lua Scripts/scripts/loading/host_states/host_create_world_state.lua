local AsyncLevelSpawner = require("scripts/loading/async_level_spawner")
local HostCreateWorldState = class("HostCreateWorldState")

function HostCreateWorldState:init(state_machine, shared_state)
	local world_parameters = {
		timer_name = "gameplay",
		layer = 1
	}
	local world = AsyncLevelSpawner.setup_world("level_world", world_parameters)
	shared_state.world = world
end

function HostCreateWorldState:update(dt)
	return "load_done"
end

return HostCreateWorldState
