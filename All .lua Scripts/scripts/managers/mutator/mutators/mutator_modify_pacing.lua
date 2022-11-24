require("scripts/managers/mutator/mutators/mutator_base")

local MutatorModifyPacing = class("MutatorModifyPacing", "MutatorBase")

function MutatorModifyPacing:init(is_server, network_event_delegate, mutator_template)
	self._is_server = is_server
	self._network_event_delegate = network_event_delegate
	self._is_active = false
	self._buffs = {}
	self._template = mutator_template
	local template = self._template
	local init_modify_pacing = template.init_modify_pacing

	if self._is_server and init_modify_pacing then
		Managers.state.pacing:add_pacing_modifiers(init_modify_pacing)
	end
end

function MutatorModifyPacing:on_gameplay_post_init(level, themes)
	local template = self._template
	local modify_pacing_settings = template.modify_pacing

	if self._is_server and modify_pacing_settings then
		Managers.state.pacing:add_pacing_modifiers(modify_pacing_settings)
	end
end

return MutatorModifyPacing
