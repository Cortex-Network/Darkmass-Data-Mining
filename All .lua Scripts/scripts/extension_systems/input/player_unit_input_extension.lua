local HumanUnitInput = require("scripts/extension_systems/input/human_unit_input")
local BotUnitInput = require("scripts/extension_systems/input/bot_unit_input")
local PlayerUnitInputExtension = class("PlayerUnitInputExtension")

function PlayerUnitInputExtension:init(extension_init_context, unit, extension_init_data, ...)
	local player = extension_init_data.player
	local input_handler = extension_init_data.input_handler
	local fixed_frame = extension_init_context.fixed_frame
	self._human_unit_input = HumanUnitInput:new(player, input_handler, fixed_frame)
	self._player = player
	local is_server = extension_init_context.is_server

	if is_server then
		local physics_world = extension_init_context.physics_world
		self._bot_unit_input = BotUnitInput:new(physics_world, player)
	end

	self._is_server = is_server
end

function PlayerUnitInputExtension:extensions_ready(world, unit)
	if self._is_server then
		self._bot_unit_input:extensions_ready(world, unit)
	end
end

function PlayerUnitInputExtension:fixed_update(unit, dt, t, frame)
	if self._player:is_human_controlled() then
		self._human_unit_input:fixed_update(unit, dt, t, frame)
	else
		self._bot_unit_input:fixed_update(unit, dt, t, frame)
	end
end

function PlayerUnitInputExtension:update(unit, dt, t)
	if not self._player:is_human_controlled() then
		self._bot_unit_input:update(unit, dt, t)
	end
end

function PlayerUnitInputExtension:bot_unit_input()
	return self._bot_unit_input
end

function PlayerUnitInputExtension:get_orientation()
	local yaw, pitch, roll = nil

	if self._player:is_human_controlled() then
		yaw, pitch, roll = self._human_unit_input:get_orientation()
	else
		yaw, pitch, roll = self._bot_unit_input:get_orientation()
	end

	return yaw, pitch, roll
end

function PlayerUnitInputExtension:get(action)
	local result = nil

	if self._player:is_human_controlled() then
		result = self._human_unit_input:get(action)
	else
		result = self._bot_unit_input:get(action)
	end

	return result
end

function PlayerUnitInputExtension:had_received_input(fixed_frame)
	local result = nil

	if self._player:is_human_controlled() then
		result = self._human_unit_input:had_received_input(fixed_frame)
	else
		result = true
	end

	return result
end

return PlayerUnitInputExtension
