local BackendError = require("scripts/managers/error/errors/backend_error")
local MasterItems = require("scripts/backend/master_items")
local ProfileUtils = require("scripts/utilities/profile_utils")
local Promise = require("scripts/foundation/utilities/promise")
local ProfilesService = class("ProfilesService")

function ProfilesService:init(backend_interface)
	self._backend_interface = backend_interface
end

local function _find_character_progression(character, characters_progression)
	local character_id = character.id

	for i = 1, #characters_progression do
		local progression = characters_progression[i]

		if progression.id == character_id then
			return progression
		end
	end
end

local function _fetch_all_backend_profiles(backend_interface)
	local characters_promise = backend_interface.characters:fetch()
	local characters_progression_promise = backend_interface.progression:get_entity_type_progression("character")
	local gear_list_promise = backend_interface.gear:fetch()
	local selected_character_id_promise = backend_interface.account:get_selected_character()

	return Promise.all(characters_promise, characters_progression_promise, gear_list_promise, selected_character_id_promise):next(function (results)
		local characters, characters_progression, gear_list, selected_character_id = unpack(results, 1, 4)

		if not characters or #characters == 0 then
			return Promise.resolved({
				profiles = {}
			})
		end

		local profiles = {}
		local selected_profile = nil

		for i = 1, #characters do
			local character = characters[i]
			local progression = _find_character_progression(character, characters_progression)
			local profile = ProfileUtils.character_to_profile(character, gear_list, progression)
			profiles[#profiles + 1] = profile

			if selected_character_id and character.id == selected_character_id then
				selected_profile = profile
			end
		end

		selected_profile = selected_profile or profiles[1]

		return Promise.resolved({
			profiles = profiles,
			selected_profile = selected_profile,
			gear = gear_list
		})
	end)
end

local function _fetch_backend_profile(backend_interface, character_id)
	local character_promise = backend_interface.characters:fetch(character_id)
	local character_progression_promise = backend_interface.progression:get_progression("character", character_id)
	local gear_list_promise = backend_interface.gear:fetch()

	return Promise.all(character_promise, character_progression_promise, gear_list_promise):next(function (results)
		local character, character_progression, gear_list = unpack(results, 1, 3)
		local profile = ProfileUtils.character_to_profile(character, gear_list, character_progression)

		return Promise.resolved(profile)
	end)
end

local function _new_character_to_profile(backend_interface, character)
	return backend_interface.gear:fetch():next(function (gear_list)
		local profile = ProfileUtils.character_to_profile(character, gear_list, nil)

		return profile
	end)
end

local function _handle_fetch_all_profiles_error()
	return Promise.rejected({})
end

function ProfilesService:fetch_all_profiles()
	return _fetch_all_backend_profiles(self._backend_interface):catch(function (error)
		Managers.error:report_error(BackendError:new(error))

		return _handle_fetch_all_profiles_error()
	end)
end

function ProfilesService:new_character_to_profile(character)
	return _new_character_to_profile(self._backend_interface, character):catch(function (error)
		Managers.error:report_error(BackendError:new(error))

		return Promise.rejected({})
	end)
end

function ProfilesService:fetch_profile(character_id)
	return _fetch_backend_profile(self._backend_interface, character_id):catch(function (error)
		Managers.error:report_error(BackendError:new(error))

		return Promise.rejected({})
	end)
end

function ProfilesService:create_profile(profile)
	return self._backend_interface.characters:create(profile):catch(function (error)
		Managers.error:report_error(BackendError:new(error))

		return Promise.rejected({})
	end)
end

function ProfilesService:delete_profile(character_id)
	return self._backend_interface.characters:delete_character(character_id):catch(function (error)
		Managers.error:report_error(BackendError:new(error))

		return Promise.rejected({})
	end)
end

function ProfilesService:fetch_suggested_names_by_archetype(archetype_name, gender, planet)
	return Managers.backend.interfaces.social:suggested_names_by_archetype(archetype_name, gender, planet):next(function (names)
		return Promise.resolved(names)
	end):catch(function (error)
		return Promise.resolved({
			"Alex",
			"Rikard",
			"Thomas",
			"Jane",
			"Niki",
			"Marie"
		})
	end)
end

function ProfilesService:set_character_height(character_id, value)
	return self._backend_interface.characters:set_character_height(character_id, value):next(function ()
		return Promise.resolved(character_id)
	end):catch(function (error)
		Managers.error:report_error(BackendError:new(error))

		return Promise.rejected({})
	end)
end

function ProfilesService:check_name(name)
	return self._backend_interface.characters:check_name(name):next(function (data)
		return Promise.resolved(data)
	end):catch(function (error)
		Managers.error:report_error(BackendError:new(error))

		return Promise.rejected({})
	end)
end

return ProfilesService
