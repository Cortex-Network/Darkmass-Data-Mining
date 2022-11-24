local GameplayInitStepInterface = require("scripts/game_states/game/gameplay_sub_states/gameplay_init_step_states/gameplay_init_step_state_interface")
local GameplayInitStepStateNetworkEvents = require("scripts/game_states/game/gameplay_sub_states/gameplay_init_step_states/gameplay_init_step_network_events")
local ScriptWorld = require("scripts/foundation/utilities/script_world")
local GameplayInitStepExtensionUnits = class("GameplayInitStepExtensionUnits")

function GameplayInitStepExtensionUnits:init()
	self._skipped_first_update = false
end

function GameplayInitStepExtensionUnits:on_enter(parent, params)
	local shared_state = params.shared_state
	self._shared_state = shared_state
	local world = shared_state.world
	local level = shared_state.level

	self:_init_extension_unit_registration(world, level, time_query_handle)
end

function GameplayInitStepExtensionUnits:update(main_dt, main_t)
	if not self._skipped_first_update then
		self._skipped_first_update = true

		return nil, 
	end

	local extension_manager = Managers.state.extension
	local are_units_added_and_registered = extension_manager:update_time_slice_add_and_register_level_units()

	if not are_units_added_and_registered then
		return nil, 
	end

	local next_step_params = {
		shared_state = self._shared_state
	}

	return GameplayInitStepStateNetworkEvents, next_step_params
end

function GameplayInitStepExtensionUnits:_optimize_level_units(world)
	ScriptWorld.optimize_level_units(world)
end

function GameplayInitStepExtensionUnits:_init_extension_unit_registration(world, level, time_query_handle)
	Level.finish_spawn_time_sliced(level)
	self:_optimize_level_units(world)

	local extension_manager = Managers.state.extension
	local units = Level.units(level, true)
	local optional_category = nil

	extension_manager:init_time_slice_add_and_register_level_units(world, units, optional_category)
end

implements(GameplayInitStepExtensionUnits, GameplayInitStepInterface)

return GameplayInitStepExtensionUnits
