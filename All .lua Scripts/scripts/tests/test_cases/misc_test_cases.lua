local TestifySnippets = require("scripts/tests/testify_snippets")
MiscTestCases = {}

local function _ensure_table_structure(tbl, ...)
	local num_args = select("#", ...)

	for i = 1, num_args do
		local arg = select(i, ...)
		tbl[arg] = tbl[arg] or {}
		tbl = tbl[arg]
	end

	return tbl
end

function MiscTestCases.validate_minion_visual_loadout_templates()
	Testify:run_case(function (dt, t)
		TestifySnippets.skip_splash_and_title_screen()

		local MinionVisualLoadoutTemplates = require("scripts/settings/minion_visual_loadout/minion_visual_loadout_templates")
		local item_definitions = Testify:make_request("all_items")
		local missing_items = {}

		for breed_name, loadout_templates in pairs(MinionVisualLoadoutTemplates) do
			for template_name, template_variations in pairs(loadout_templates) do
				for variation_i, variation in ipairs(template_variations) do
					for slot_name, slot_data in pairs(variation.slots) do
						for item_i, item_name in ipairs(slot_data.items) do
							if not rawget(item_definitions, item_name) then
								local items = _ensure_table_structure(missing_items, breed_name, template_name, variation_i, slot_name)
								items[item_i] = item_name
							end
						end
					end
				end
			end
		end

		if not table.is_empty(missing_items) then
			local error_tbl = {
				"Minion visual loadout items missing in MasterData:"
			}

			for breed_name, templates in pairs(missing_items) do
				table.insert(error_tbl, "\n" .. breed_name .. " = {")

				for template_name, variations in pairs(templates) do
					table.insert(error_tbl, "\n\t" .. template_name .. " = {")

					for variation_i, slot_names in pairs(variations) do
						table.insert(error_tbl, "\n\t\t[" .. variation_i .. "] = {")

						for slot_name, items in pairs(slot_names) do
							table.insert(error_tbl, "\n\t\t\t" .. slot_name .. " = {")

							for item_index, item_name in pairs(items) do
								table.insert(error_tbl, "\n\t\t\t\t[" .. item_index .. "] = " .. item_name)
							end

							table.insert(error_tbl, "\n\t\t\t}")
						end

						table.insert(error_tbl, "\n\t\t}")
					end

					table.insert(error_tbl, "\n\t}")
				end

				table.insert(error_tbl, "\n}")
			end

			local assert_data = {
				condition = false,
				message = table.concat(error_tbl)
			}
		end
	end)
end

local function _ensure_no_hidden_attachments_recursive(item_definitions, attachment_data, nil_attachments, attachment_name, parent_item_name, source_item_name)
	local item_name = attachment_data.item

	if not item_name then
		nil_attachments[source_item_name] = nil_attachments[source_item_name] or {}
		nil_attachments[source_item_name][attachment_name] = true

		return
	end

	local children = attachment_data.children

	if children then
		for child_attachment_name, child_data in pairs(children) do
			_ensure_no_hidden_attachments_recursive(item_definitions, child_data, nil_attachments, child_attachment_name, item_name, source_item_name)
		end
	end
end

function MiscTestCases.ensure_no_hidden_attachments()
	Testify:run_case(function (dt, t)
		TestifySnippets.skip_splash_and_title_screen()

		local item_definitions = Testify:make_request("all_items")
		local nil_attachments = {}

		for name, item_data in pairs(item_definitions) do
			local attachments = item_data.attachments

			if attachments then
				for attachment_name, attachment_data in pairs(attachments) do
					_ensure_no_hidden_attachments_recursive(item_definitions, attachment_data, nil_attachments, attachment_name, name, name)
				end
			end
		end

		if not table.is_empty(nil_attachments) then
			local error_tbl = {
				"Items contain nil attachments. These are defined in the item files but won't show up in the Item Manager:\n"
			}

			for source_item_name, nil_attachment_names in pairs(nil_attachments) do
				table.insert(error_tbl, "\t" .. source_item_name .. "\n")

				for name, _ in pairs(nil_attachment_names) do
					table.insert(error_tbl, "\t\t" .. name .. "\n")
				end
			end

			local assert_data = {
				condition = false,
				message = table.concat(error_tbl)
			}
		end
	end)
end

local _ignored_attachment_types = {
	slot_trinket_1 = true,
	slot_trinket_2 = true
}

local function _validate_attachment_parents_recursive(item_definitions, attachment_data, loose_children, attachment_name, parent_item_name, source_item_name)
	local item_name = attachment_data.item

	if not item_name then
		return
	end

	local ignored = _ignored_attachment_types[attachment_name]

	if not ignored and item_name ~= "" and not parent_item_name == "" then
		loose_children[source_item_name] = loose_children[source_item_name] or {}
		loose_children[source_item_name][attachment_name] = true

		return
	end

	local children = attachment_data.children

	if children then
		for child_attachment_name, child_data in pairs(children) do
			_validate_attachment_parents_recursive(item_definitions, child_data, loose_children, child_attachment_name, item_name, source_item_name)
		end
	end
end

local _ignored_item_types = {
	WEAPON_SKIN = true
}

function MiscTestCases.validate_attachment_parents()
	Testify:run_case(function (dt, t)
		TestifySnippets.skip_splash_and_title_screen()

		local item_definitions = Testify:make_request("all_items")
		local loose_children = {}

		for name, item_data in pairs(item_definitions) do
			local item_type = item_data.item_type
			local ignored = item_type and _ignored_item_types[item_type]
			local attachments = item_data.attachments

			if not ignored and attachments then
				for attachment_name, attachment_data in pairs(attachments) do
					_validate_attachment_parents_recursive(item_definitions, attachment_data, loose_children, attachment_name, name, name)
				end
			end
		end

		if not table.is_empty(loose_children) then
			local error_tbl = {
				"Items contain attachments without parents:\n"
			}

			for source_item_name, attachment_names in pairs(loose_children) do
				table.insert(error_tbl, "\t" .. source_item_name .. "\n")

				for name, _ in pairs(attachment_names) do
					table.insert(error_tbl, "\t\t" .. name .. "\n")
				end
			end

			local assert_data = {
				condition = false,
				message = table.concat(error_tbl)
			}
		end
	end)
end

local function _validate_stripping_recursive(item_definitions, attachment_data, stripped_children, parent_name, source_item_name)
	local item_name = attachment_data.item

	if not item_name then
		return
	end

	if item_name ~= "" then
		local item_data = item_definitions[item_name]

		if not item_data then
			stripped_children[source_item_name] = stripped_children[source_item_name] or {}
			stripped_children[source_item_name][parent_name] = stripped_children[source_item_name][parent_name] or {}
			stripped_children[source_item_name][parent_name][item_name] = true
		end
	end

	local children = attachment_data.children

	if children then
		for child_name, child_data in pairs(children) do
			local child_name = child_data.item

			_validate_stripping_recursive(item_definitions, child_data, stripped_children, item_name, source_item_name)
		end
	end
end

function MiscTestCases.validate_attachment_stripping()
	Testify:run_case(function (dt, t)
		TestifySnippets.skip_splash_and_title_screen()

		return

		local item_definitions = Testify:make_request("all_items")
		local stripped_children = {}

		for name, item_data in pairs(item_definitions) do
			local attachments = item_data.attachments

			if attachments then
				for attachment_name, attachment_data in pairs(attachments) do
					_validate_stripping_recursive(item_definitions, attachment_data, stripped_children, name, name)
				end
			end
		end

		if not table.is_empty(stripped_children) then
			local error_tbl = {
				"MasterItems contains released items with unreleased attachments:\n"
			}

			for source_item_name, faulty_parents in pairs(stripped_children) do
				table.insert(error_tbl, "\t" .. source_item_name .. "\n")

				for parent_name, faulty_children in pairs(faulty_parents) do
					table.insert(error_tbl, "\t\t" .. parent_name .. "\n")

					for name, _ in pairs(faulty_children) do
						table.insert(error_tbl, "\t\t\t" .. name .. "\n")
					end
				end
			end

			local assert_data = {
				condition = false,
				message = table.concat(error_tbl)
			}
		end
	end)
end

function MiscTestCases.check_logs_size(max_messages_per_minute)
	Testify:run_case(function (dt, t)
		Testify:make_request("wait_for_state_gameplay_reached")
		TestifySnippets.wait(5)

		local statistics = TestifySnippets.connection_statistics()
		local messages_per_minute = statistics.messages_per_minute

		Log.info("Testify", "messages_per_minute " .. messages_per_minute)

		local assert_data = {
			condition = messages_per_minute <= max_messages_per_minute,
			message = string.format("The number of messages in the logs per minute is %s which is bigger than the threshold %s", messages_per_minute, max_messages_per_minute)
		}
	end)
end

local _invalid_skin_attachment_overrides = {}

local function _check_weapon_skin_attachments_recursive(attachment_name, children, faulty_items, attachment_item_name, source_item_name)
	local is_invalid_slot = _invalid_skin_attachment_overrides[attachment_name]
	local slot_is_empty = attachment_item_name == ""

	if is_invalid_slot and not slot_is_empty then
		faulty_items[source_item_name] = faulty_items[source_item_name] or {}
		faulty_items[source_item_name][attachment_name] = attachment_item_name
	end

	for attachment_name, attachment_data in pairs(children) do
		local attachment_children = attachment_data.children
		local item_name = attachment_data.item

		_check_weapon_skin_attachments_recursive(attachment_name, attachment_children, faulty_items, item_name, source_item_name)
	end
end

function MiscTestCases.check_unwanted_skin_attachments()
	Testify:run_case(function (dt, t)
		TestifySnippets.skip_splash_and_title_screen()

		return

		local item_definitions = Testify:make_request("all_items")
		local faulty_skin_attachment_overrides = {}

		for name, item_data in pairs(item_definitions) do
			if item_data.item_type == "WEAPON_SKIN" then
				local attachments = item_data.attachments

				if attachments then
					for attachment_name, attachment_data in pairs(attachments) do
						local children = attachment_data.children
						local item_name = attachment_data.item

						_check_weapon_skin_attachments_recursive(attachment_name, children, faulty_skin_attachment_overrides, item_name, name)
					end
				end
			end
		end

		if not table.is_empty(faulty_skin_attachment_overrides) then
			local error_tbl = {
				"MasterItems contains weapon skins with invalid attachment overrides:\n"
			}

			for item_name, attachment_names in pairs(faulty_skin_attachment_overrides) do
				table.insert(error_tbl, "\t" .. item_name .. "\n")

				for slot_name, item_name in pairs(attachment_names) do
					table.insert(error_tbl, "\t\t" .. slot_name .. ": " .. item_name .. "\n")
				end
			end

			local assert_data = {
				condition = false,
				message = table.concat(error_tbl)
			}
		end
	end)
end

function MiscTestCases.play_all_cutscenes(case_settings)
	Testify:run_case(function (dt, t)
		local settings = cjson.decode(case_settings or "{}")
		local flags = settings.flags or {
			"cutscenes",
			"load_mission"
		}
		local hide_players = settings.hide_players or false
		local mission_key = settings.mission_key
		local use_trigger_volumes = settings.use_trigger_volumes or false
		local intro_cutscenes = settings.intro_cutscenes or {
			"intro_abc"
		}
		local cutscenes_to_skip = settings.cutscenes_to_skip or {
			"intro_abc"
		}

		if TestifySnippets.is_debug_stripped() and Testify:make_request("current_state_name") ~= "StateGameplay" then
			TestifySnippets.skip_title_and_main_menu_and_create_character_if_none()
		end

		local output = TestifySnippets.check_flags_for_mission(flags, mission_key)

		if output then
			return output
		end

		TestifySnippets.load_mission(mission_key)
		Testify:make_request("wait_for_state_gameplay_reached")

		for _, cutscene_name in ipairs(intro_cutscenes) do
			Testify:make_request("wait_for_cutscene_to_finish", cutscene_name)
			TestifySnippets.wait(2)
		end

		local temp_keys = {}
		local cutscenes = Testify:make_request("mission_cutscenes", mission_key)

		for _, cutscene_name in ipairs(cutscenes_to_skip) do
			cutscenes[cutscene_name] = nil
		end

		for cutscene_name, _ in table.sorted(cutscenes, temp_keys) do
			if hide_players then
				Testify:make_request("hide_players")
			end

			if use_trigger_volumes then
				local event_name = "event_cutscene_" .. cutscene_name

				Testify:make_request("trigger_external_event", event_name)
				Testify:make_request("wait_for_cutscene_to_start", cutscene_name)
			else
				Testify:make_request("play_cutscene", cutscene_name)
			end

			Testify:make_request("wait_for_cutscene_to_finish", cutscene_name)

			if hide_players then
				Testify:make_request("show_players")
			end

			TestifySnippets.wait(2)
		end

		table.clear(temp_keys)
		TestifySnippets.wait(3)
	end)
end

function MiscTestCases.karls_awesome_vfx_test(particle_effect)
	Testify:run_case(function (dt, t)
		local particle_life_time = 10
		local PARTICLES_TO_PLAY = {
			"content/fx/particles/enemies/netgunner/netgunner_net_miss",
			"content/fx/particles/enemies/plague_ogryn/plague_ogryn_body_odor",
			"content/fx/particles/environment/foundry_molten_pool_boiling_01",
			"content/fx/particles/environment/molten_steel_splash",
			"content/fx/particles/environment/molten_steel_splashes_impact",
			"content/fx/particles/environment/roofdust_tremor",
			"content/fx/particles/environment/tank_foundry/fire_smoke_02",
			"content/fx/particles/environment/tank_foundry/fire_smoke_03",
			"content/fx/particles/interacts/airlock_closing",
			"content/fx/particles/interacts/airlock_opening",
			"content/fx/particles/liquid_area/fire_lingering_enemy",
			"content/fx/particles/weapons/swords/powersword_1h_activate_mesh"
		}

		if TestifySnippets.is_debug_stripped() then
			TestifySnippets.skip_title_and_main_menu_and_create_character_if_none()
			TestifySnippets.load_mission("spawn_all_enemies")
		end

		TestifySnippets.wait_for_gameplay_ready()
		Testify:make_request("set_autoload_enabled", true)

		local world = Testify:make_request("world")
		local boxed_spawn_position = Vector3Box(0, 10, 1.8)

		if particle_effect then
			Testify:make_request("create_particles", world, particle_effect, boxed_spawn_position, particle_life_time)
		else
			for _, particle_name in pairs(PARTICLES_TO_PLAY) do
				Testify:make_request("create_particles", world, particle_name, boxed_spawn_position, particle_life_time)
			end
		end

		TestifySnippets.wait(particle_life_time)
	end)
end

function MiscTestCases.play_all_vfx(case_settings)
	Testify:run_case(function (dt, t)
		local settings = cjson.decode(case_settings or "{}")
		local particle_life_time = settings.particle_life_time or 3
		local PARTICLES_TO_SKIP = {
			"content/fx/particles/debug/mesh_position_spawn_crash",
			"content/fx/particles/enemies/netgunner/netgunner_net_miss",
			"content/fx/particles/enemies/plague_ogryn/plague_ogryn_body_odor",
			"content/fx/particles/environment/foundry_molten_pool_boiling_01",
			"content/fx/particles/environment/molten_steel_splash",
			"content/fx/particles/environment/molten_steel_splashes_impact",
			"content/fx/particles/environment/roofdust_tremor",
			"content/fx/particles/environment/tank_foundry/fire_smoke_02",
			"content/fx/particles/environment/tank_foundry/fire_smoke_03",
			"content/fx/particles/interacts/airlock_closing",
			"content/fx/particles/interacts/airlock_opening",
			"content/fx/particles/liquid_area/fire_lingering_enemy",
			"content/fx/particles/weapons/swords/powersword_1h_activate_mesh"
		}

		if TestifySnippets.is_debug_stripped() then
			TestifySnippets.skip_title_and_main_menu_and_create_character_if_none()
			TestifySnippets.load_mission("spawn_all_enemies")
		end

		TestifySnippets.wait_for_gameplay_ready()
		Testify:make_request("set_autoload_enabled", true)

		local world = Testify:make_request("world")
		local boxed_spawn_position = Vector3Box(0, 10, 1.8)
		local query_handle = Testify:make_request("metadata_execute_query_deferred", {
			type = "particles"
		}, {
			include_properties = false
		})
		local particles = Testify:make_request("metadata_wait_for_query_results", query_handle)
		local particle_ids = {}

		for particle_name, _ in pairs(particles) do
			if not table.contains(PARTICLES_TO_SKIP, particle_name) then
				local particle_id = Testify:make_request("create_particles", world, particle_name, boxed_spawn_position, particle_life_time)
				particle_ids[particle_name] = particle_id
			end
		end

		TestifySnippets.wait(particle_life_time)
	end)
end

function MiscTestCases.smoke()
	Testify:run_case(function (dt, t)
		if TestifySnippets.is_debug_stripped() then
			TestifySnippets.skip_title_and_main_menu_and_create_character_if_none()
		end

		Testify:make_request("wait_for_state_gameplay_reached")
		TestifySnippets.wait(5)
	end)
end
