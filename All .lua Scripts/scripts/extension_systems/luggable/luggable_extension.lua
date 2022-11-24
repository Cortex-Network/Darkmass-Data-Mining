local FixedFrame = require("scripts/utilities/fixed_frame")
local PlayerUnitVisualLoadout = require("scripts/extension_systems/visual_loadout/utilities/player_unit_visual_loadout")
local LuggableExtension = class("LuggableExtension")

function LuggableExtension:init(extension_init_context, unit, extension_init_data, ...)
	local is_server = extension_init_context.is_server
	self._is_server = is_server
	self._unit = unit
	self._destroyed = false
	self._carrier_player_unit = nil
	self._synchronizer = nil
end

function LuggableExtension:extensions_ready(world, unit)
	self._mission_objective_target_extension = ScriptUnit.extension(unit, "mission_objective_target_system")
	self._interactee_extension = ScriptUnit.extension(unit, "interactee_system")
end

function LuggableExtension:destroy()
	self._destroyed = true
	local player_unit = self._carrier_player_unit

	if player_unit then
		local fixed_t = FixedFrame.get_latest_fixed_time()

		PlayerUnitVisualLoadout.unequip_item_from_slot(player_unit, "slot_luggable", fixed_t)
	end
end

function LuggableExtension:set_carried_by(player_unit_or_nil)
	if player_unit_or_nil then
		self:_on_carried()
	else
		self:_on_dropped()
	end

	local synchronizer = self._synchronizer

	if synchronizer then
		synchronizer:set_carried_by(self._unit, player_unit_or_nil)
	end

	self._carrier_player_unit = player_unit_or_nil
end

function LuggableExtension:set_synchronizer(synchronizer)
	self._synchronizer = synchronizer
end

function LuggableExtension:_on_carried()
	if self._is_server then
		self._interactee_extension:set_active(false)
	end
end

function LuggableExtension:_on_dropped()
	if self._is_server and not self._destroyed then
		self._interactee_extension:set_active(true)
	end
end

return LuggableExtension
