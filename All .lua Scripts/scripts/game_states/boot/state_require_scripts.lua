require("scripts/game_states/boot/state_boot_sub_state_base")

local StateRequireScripts = class("StateRequireScripts", "StateBootSubStateBase")

function StateRequireScripts:on_enter(parent, params)
	StateRequireScripts.super.on_enter(self, parent, params)

	local state_params = self:_state_params()
	local pm = state_params.package_manager
	self._package_manager = pm
end

function StateRequireScripts:_state_update(dt)
	local loading_done = self._package_manager:update()

	if loading_done then
		self:_foundation_scripts()
		self:_init_crashify()
		self:_init_testify()
		self:_require_scripts()

		return true, false
	end

	return false, false
end

function StateRequireScripts:_init_crashify()
	local settings = require("scripts/settings/crashify/crashify")

	Crashify.print_property("project", settings.project)
	Crashify.print_property("project_branch", settings.branch)
	Crashify.print_property("build", BUILD)
	Crashify.print_property("platform", PLATFORM)
	Crashify.print_property("title_id", "4711")
	Crashify.print_property("content_revision", APPLICATION_SETTINGS.content_revision or LOCAL_CONTENT_REVISION)
	Crashify.print_property("engine_revision", BUILD_IDENTIFIER)
	Crashify.print_property("rendering_backend", Renderer.render_device_string())
	Crashify.print_property("teamcity_build_id", APPLICATION_SETTINGS.teamcity_build_id)
	Crashify.print_property("server", DEDICATED_SERVER)
	Crashify.print_property("backend_env", BACKEND_ENV)

	if PLATFORM == "win32" then
		if HAS_STEAM then
			Crashify.print_property("steam_id", Steam.user_id())
			Crashify.print_property("steam_user_name", Steam.user_name())
			Crashify.print_property("steam_app_id", Steam.app_id())
		elseif IS_GDK then
			local device_type = XboxLive.get_device_type()

			Crashify.print_property("device_type", device_type)
		end

		Crashify.print_property("machine_id", Application.machine_id())
	elseif PLATFORM == "ps4" then
		Crashify.print_property("machine_id", Application.machine_id())
	elseif PLATFORM == "xb1" then
		Crashify.print_property("console_type", "unknown")
	elseif PLATFORM == "xbs" then
		local device_type = XboxLive.get_device_type()

		Crashify.print_property("device_type", device_type)
	elseif PLATFORM == "linux" then
		Crashify.print_property("machine_id", Application.machine_id())
	end
end

function StateRequireScripts:_init_testify()
	Testify:ready()
	require("scripts/tests/test_cases/audio_test_cases")
	require("scripts/tests/test_cases/combat_test_cases")
	require("scripts/tests/test_cases/misc_test_cases")
	require("scripts/tests/test_cases/networked_test_cases")
	require("scripts/tests/test_cases/performance_test_cases")
	require("scripts/tests/test_cases/ui_test_cases")
	require("scripts/tests/test_cases/world_test_cases")
end

function StateRequireScripts:_require_scripts()
	require("scripts/foundation/managers/managers")
	require("scripts/game_states/state_game")
end

function StateRequireScripts:_foundation_scripts()
	require("scripts/foundation/utilities/vector3")
	require("scripts/foundation/utilities/utf8")
	require("scripts/foundation/utilities/color")
	require("scripts/foundation/utilities/math")
	require("scripts/foundation/utilities/table")
	require("scripts/foundation/utilities/string")
	require("scripts/foundation/utilities/callback")
	require("scripts/foundation/utilities/crashify")
	require("scripts/foundation/utilities/testify")
	require("scripts/foundation/utilities/log")
	require("scripts/foundation/utilities/reportify")
end

return StateRequireScripts
