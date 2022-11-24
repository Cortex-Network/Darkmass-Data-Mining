local AsyncLevelSpawner = require("scripts/loading/async_level_spawner")
local LocalCreateWorldState = class("LocalCreateWorldState")

function LocalCreateWorldState:init(state_machine, shared_state)
	local world_parameters = {
		timer_name = "gameplay",
		layer = 1
	}
	local world = AsyncLevelSpawner.setup_world("level_world", world_parameters)
	shared_state.world = world
end

function LocalCreateWorldState:update(dt)
	return "load_done"
end

return LocalCreateWorldState
