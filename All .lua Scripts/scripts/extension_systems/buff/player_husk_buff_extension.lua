local BuffExtensionInterface = require("scripts/extension_systems/buff/buff_extension_interface")
local PlayerHuskBuffExtension = class("PlayerHuskBuffExtension")
local RPCS = {
	"rpc_add_buff",
	"rpc_remove_buff",
	"rpc_buff_proc_set_active_time"
}
local EMPTY_TABLE = {}

function PlayerHuskBuffExtension:init(extension_init_context, unit, extension_init_data, game_session, game_object_id, owner_id)
	self._world = extension_init_context.world
	self._unit = unit
	self._game_object_id = game_object_id
	self._game_session = game_session
	self._player = extension_init_data.player
	local network_event_delegate = extension_init_context.network_event_delegate

	network_event_delegate:register_session_unit_events(self, self._game_object_id, unpack(RPCS))

	self._network_event_delegate = network_event_delegate
end

function PlayerHuskBuffExtension:destroy()
	self._network_event_delegate:unregister_unit_events(self._game_object_id, unpack(RPCS))
end

function PlayerHuskBuffExtension:has_buff_id()
end

function PlayerHuskBuffExtension:has_unique_buff_id()
end

function PlayerHuskBuffExtension:has_keyword()
end

function PlayerHuskBuffExtension:keywords()
end

function PlayerHuskBuffExtension:rpc_add_buff(channel_id, game_object_id)
end

function PlayerHuskBuffExtension:rpc_remove_buff(channel_id, game_object_id)
end

function PlayerHuskBuffExtension:rpc_buff_proc_set_active_time(channel_id, game_object_id, server_index, activation_time)
end

function PlayerHuskBuffExtension:stat_buffs()
	return EMPTY_TABLE
end

function PlayerHuskBuffExtension:buffs()
	return EMPTY_TABLE
end

function PlayerHuskBuffExtension:add_externally_controlled_buff()
	ferror("[PlayerHuskBuffExtension] add_externally_controlled_buff can only be called on server!")
end

function PlayerHuskBuffExtension:add_internally_controlled_buff()
	ferror("[PlayerHuskBuffExtension] add_internally_controlled_buff can only be called on server!")
end

function PlayerHuskBuffExtension:add_proc_event()
	ferror("[PlayerHuskBuffExtension] add_proc_event can only be called on server!")
end

function PlayerHuskBuffExtension:current_stacks()
	ferror("[PlayerHuskBuffExtension] current_stacks can only be called on server!")
end

function PlayerHuskBuffExtension:is_frame_unique_proc()
	ferror("[PlayerHuskBuffExtension] is_frame_unique_proc can only be called on server!")
end

function PlayerHuskBuffExtension:refresh_duration_of_stacking_buff()
	ferror("[PlayerHuskBuffExtension] refresh_duration_of_stacking_buff can only be called on server!")
end

function PlayerHuskBuffExtension:remove_externally_controlled_buff()
	ferror("[PlayerHuskBuffExtension] remove_externally_controlled_buff can only be called on server!")
end

function PlayerHuskBuffExtension:request_proc_event_param_table()
	ferror("[PlayerHuskBuffExtension] request_proc_event_param_table can only be called on server!")
end

function PlayerHuskBuffExtension:set_frame_unique_proc()
	ferror("[PlayerHuskBuffExtension] set_frame_unique_proc can only be called on server!")
end

implements(PlayerHuskBuffExtension, BuffExtensionInterface)

return PlayerHuskBuffExtension
