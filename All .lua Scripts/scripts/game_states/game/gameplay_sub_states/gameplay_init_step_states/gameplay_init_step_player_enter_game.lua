local BotGameplay = require("scripts/managers/player/player_game_states/bot_gameplay")
local GameplayInitStepInterface = require("scripts/game_states/game/gameplay_sub_states/gameplay_init_step_states/gameplay_init_step_state_interface")
local GameplayInitStepMusic = require("scripts/game_states/game/gameplay_sub_states/gameplay_init_step_states/gameplay_init_step_music")
local HumanGameplay = require("scripts/managers/player/player_game_states/human_gameplay")
local RemotePlayerGameplay = require("scripts/managers/player/player_game_states/remote_player_gameplay")
local GameplayInitStepPlayerEnterGame = class("GameplayInitStepPlayerEnterGame")

function GameplayInitStepPlayerEnterGame:init()
	self._skipped_first_update = false
end

function GameplayInitStepPlayerEnterGame:on_enter(parent, params)
	local shared_state = params.shared_state
	self._shared_state = shared_state
	local gameplay_state = parent:gameplay_state()
	local themes = shared_state.themes
	local is_server = shared_state.is_server
	local physics_world = shared_state.physics_world
	local level = shared_state.level
	local mission_name = shared_state.mission_name
	local world = shared_state.world

	self:_player_state_enter(world, physics_world, level, themes, mission_name, is_server, gameplay_state, shared_state.clock_handler_client)
end

function GameplayInitStepPlayerEnterGame:update(main_dt, main_t)
	if not self._skipped_first_update then
		self._skipped_first_update = true

		return nil, 
	end

	local player_manager = Managers.player
	local is_players_enter_initialized = player_manager:update_time_slice_on_game_state_enter()

	if not is_players_enter_initialized then
		return nil, 
	end

	local next_step_params = {
		shared_state = self._shared_state
	}

	return GameplayInitStepMusic, next_step_params
end

function GameplayInitStepPlayerEnterGame:_player_state_enter(world, physics_world, level, themes, mission_name, is_server, gameplay_state, clock_handler_client)
	if not is_server then
		-- Nothing
	end

	local player_game_state_mapping = {
		HumanPlayer = HumanGameplay,
		BotPlayer = BotGameplay,
		RemotePlayer = RemotePlayerGameplay
	}
	local game_state_context = {
		is_server = is_server,
		clock_handler = clock_handler_client,
		world = world,
		physics_world = physics_world,
		level = level,
		themes = themes,
		mission_name = mission_name
	}

	Managers.player:init_time_slice_on_game_state_enter(gameplay_state, player_game_state_mapping, game_state_context)
end

implements(GameplayInitStepPlayerEnterGame, GameplayInitStepInterface)

return GameplayInitStepPlayerEnterGame
