local CircumstanceTemplates = require("scripts/settings/circumstance/circumstance_templates")
local MutatorTemplates = require("scripts/settings/mutator/mutator_templates")
local MutatorManager = class("MutatorManager")

function MutatorManager:init(is_server, network_event_delegate, circumstance_name)
	self._is_server = is_server
	self._network_event_delegate = network_event_delegate
	self._mutators = {}

	self:_load_mutators(circumstance_name)

	if is_server then
		local event_manager = Managers.event

		event_manager:register(self, "player_unit_spawned", "_on_player_unit_spawned")
		event_manager:register(self, "player_unit_despawned", "_on_player_unit_despawned")
		event_manager:register(self, "minion_unit_spawned", "_on_minion_unit_spawned")
	end
end

function MutatorManager:_load_mutators(circumstance_name)
	local circumstance_template = CircumstanceTemplates[circumstance_name]
	local mutators_to_load = circumstance_template.mutators
	local is_server = self._is_server
	local network_event_delegate = self._network_event_delegate
	local mutators = self._mutators

	if mutators_to_load then
		for _, mutator_name in ipairs(mutators_to_load) do
			local mutator_template = MutatorTemplates[mutator_name]
			local mutator_class = require(mutator_template.class)
			mutators[mutator_name] = mutator_class:new(is_server, network_event_delegate, mutator_template)
		end
	end
end

function MutatorManager:destroy()
	if self._is_server then
		local event_manager = Managers.event

		event_manager:unregister(self, "minion_unit_spawned")
		event_manager:unregister(self, "player_unit_despawned")
		event_manager:unregister(self, "player_unit_spawned")
	end
end

function MutatorManager:hot_join_sync(sender, channel)
	local mutators = self._mutators

	for _, mutator in pairs(mutators) do
		mutator:hot_join_sync(sender, channel)
	end
end

function MutatorManager:on_gameplay_post_init(level, themes)
	local mutators = self._mutators

	for _, mutator in pairs(mutators) do
		mutator:on_gameplay_post_init(level, themes)
	end
end

function MutatorManager:update(dt, t)
	local mutators = self._mutators

	for _, mutator in pairs(mutators) do
		if mutator:is_active() then
			mutator:update(dt, t)
		end
	end
end

function MutatorManager:activate_mutator(mutator_name)
	local mutator = self._mutators[mutator_name]

	mutator:activate()
end

function MutatorManager:deactivate_mutator(mutator_name)
	local mutator = self._mutators[mutator_name]

	mutator:deactivate()
end

function MutatorManager:mutator(mutator_name)
	return self._mutators[mutator_name]
end

function MutatorManager:_on_player_unit_spawned(player)
	local mutators = self._mutators

	for _, mutator in pairs(mutators) do
		mutator:_on_player_unit_spawned(player)
	end
end

function MutatorManager:_on_player_unit_despawned(player)
	local mutators = self._mutators

	for _, mutator in pairs(mutators) do
		mutator:_on_player_unit_despawned(player)
	end
end

function MutatorManager:_on_minion_unit_spawned(unit)
	local mutators = self._mutators

	for _, mutator in pairs(mutators) do
		mutator:_on_minion_unit_spawned(unit)
	end
end

return MutatorManager
