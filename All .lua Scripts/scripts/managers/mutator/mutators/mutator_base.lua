local Breed = require("scripts/utilities/breed")
local FixedFrame = require("scripts/utilities/fixed_frame")
local MutatorBase = class("MutatorBase")

function MutatorBase:init(is_server, network_event_delegate, mutator_template)
	self._is_server = is_server
	self._network_event_delegate = network_event_delegate
	self._is_active = false
	self._buffs = {}
	self._template = mutator_template
end

function MutatorBase:destroy()
	local is_server = self._is_server

	if is_server then
		self:_remove_buffs()
	end
end

function MutatorBase:hot_join_sync(sender, channel)
end

function MutatorBase:on_gameplay_post_init(level, themes)
end

function MutatorBase:update(dt, t)
end

function MutatorBase:is_active()
	return self._is_active
end

function MutatorBase:activate()
	self._is_active = true

	if self._is_server then
		local template = self._template

		if template.buff_templates then
			self:_add_buffs(template.buff_templates)
		end
	end
end

function MutatorBase:_add_buffs(buff_template_names)
	local buff_system = Managers.state.extension:system("buff_system")
	local buff_extensions = buff_system:unit_to_extension_map()

	for unit, _ in pairs(buff_extensions) do
		self:_add_buffs_on_unit(buff_template_names, unit)
	end
end

function MutatorBase:_add_buffs_on_unit(buff_template_names, unit)
	local buffs = self._buffs
	buffs[unit] = buffs[unit] or {}
	local buff_ids = buffs[unit]
	local current_time = FixedFrame.get_latest_fixed_time()
	local buff_extension = ScriptUnit.extension(unit, "buff_system")

	for i = 1, #buff_template_names do
		local buff_template_name = buff_template_names[i]
		local is_valid_target = buff_extension:is_valid_target(buff_template_name)

		if is_valid_target then
			local _, local_index, component_index = buff_extension:add_externally_controlled_buff(buff_template_name, current_time)
			buff_ids[#buff_ids + 1] = {
				local_index = local_index,
				component_index = component_index
			}
		end
	end
end

function MutatorBase:deactivate()
	if self._is_server then
		self:_remove_buffs()
	end

	self._is_active = false
end

function MutatorBase:_remove_buffs()
	local buffs = self._buffs
	local ALIVE = ALIVE

	for unit, buff_ids in pairs(buffs) do
		if ALIVE[unit] then
			local buff_extension = ScriptUnit.extension(unit, "buff_system")

			for _, buff_indices in ipairs(buff_ids) do
				local local_index = buff_indices.local_index
				local component_index = buff_indices.component_index

				buff_extension:remove_externally_controlled_buff(local_index, component_index)
			end
		else
			buffs[unit] = nil
		end
	end
end

function MutatorBase:_on_player_unit_spawned(player)
	local template = self._template
	local is_server = self._is_server
	local buff_template_names = template.buff_templates

	if is_server and buff_template_names then
		local player_unit = player.player_unit

		self:_add_buffs_on_unit(buff_template_names, player_unit)
	end
end

function MutatorBase:_on_player_unit_despawned(player)
end

function MutatorBase:_on_minion_unit_spawned(unit)
	local template = self._template
	local is_server = self._is_server
	local buff_template_names = template.buff_templates

	if is_server and buff_template_names then
		self:_add_buffs_on_unit(buff_template_names, unit)
	end

	local random_spawn_buff_templates = template.random_spawn_buff_templates

	if is_server and random_spawn_buff_templates then
		local buffs = random_spawn_buff_templates.buffs
		local breed = Breed.unit_breed_or_nil(unit)
		local breed_name = breed.name
		local breed_chances = random_spawn_buff_templates.breed_chances
		local breed_chance = breed_chances[breed_name]

		if breed_chance and math.random() < breed_chance then
			self:_add_buffs_on_unit(buffs, unit)
		end
	end
end

return MutatorBase
