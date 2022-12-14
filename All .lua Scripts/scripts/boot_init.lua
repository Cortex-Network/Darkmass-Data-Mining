if jit then
	jit.off()
end

if not LEVEL_EDITOR_TEST then
	LEVEL_EDITOR_TEST = false
end

if not EDITOR then
	EDITOR = false
end

local function import(lib)
	for k, v in pairs(lib) do
		_G[k] = v
	end
end

if s3d and not LIBRARIES_IMPORTED then
	import(s3d)

	LIBRARIES_IMPORTED = true
end

if cjson.stingray_init then
	cjson = cjson.stingray_init()
end

if not ENGINE_FUNCTIONS_OVERRIDDEN then
	APPLICATION_SETTINGS = Application.settings()
	BUILD = Application.build()
	BUILD_IDENTIFIER = Application.build_identifier()
	PLATFORM = Application.platform()
	IS_XBS = PLATFORM == "xbs"
	IS_WINDOWS = PLATFORM == "win32"
	IS_GDK = Backend.get_auth_method() == Backend.AUTH_METHOD_XBOXLIVE and IS_WINDOWS

	if PLATFORM == "win32_server" then
		PLATFORM = "win32"
	end

	if PLATFORM == "linux_server" then
		PLATFORM = "linux"
	end

	function Application.settings()
		error("Trying to use Application.settings, use global variable APPLICATION_SETTINGS instead.")
	end

	function Application.build()
		error("Trying to use Application.build, use global variable BUILD instead.")
	end

	function Application.build_identifier()
		error("Trying to use Application.build_identifier(), use global variable BUILD_IDENTIFIER instead.")

		return BUILD_IDENTIFIER
	end

	function Application.platform()
		error("Trying to use Application.platform(), use global variable PLATFORM instead.")
	end

	lua_math = {}

	for f_name, f in pairs(math) do
		lua_math[f_name] = f
	end

	local function err()
		error("Use 'math' instead of 'Math'")
	end

	for f_name, f in pairs(Math) do
		math[f_name] = f
		Math[f_name] = err
	end

	ENGINE_FUNCTIONS_OVERRIDDEN = true
end

local ARGS = {
	Application.argv()
}

local function arg_value(key)
	for i, arg in ipairs(ARGS) do
		if arg == key then
			return ARGS[i + 1]
		end
	end
end

local function backend_env()
	local auth_url = arg_value("--backend-auth-service-url")

	if auth_url then
		local match = string.match(auth_url, "https://bsp%-auth%-(%a+)%.fatsharkgames%.se")

		if match then
			return match
		end

		match = string.match(auth_url, "https://bsp%-auth%-(%a+)%.atoma%.cloud")

		if match then
			return match
		end
	end

	return "dev"
end

BACKEND_ENV = backend_env()
HAS_STEAM = rawget(_G, "Steam") and true or false
DEDICATED_SERVER = Application.is_dedicated_server()
CLASSES = CLASSES or {}
SETTINGS = SETTINGS or {}
local valid = nil
valid, LOCAL_CONTENT_REVISION = pcall(require, "scripts/optional/content_revision")

if not valid then
	LOCAL_CONTENT_REVISION = "Unknown"
end

if not NETWORK_INIT_WRAPPED then
	NETWORK_INIT_WRAPPED = true
	Network._is_active = false

	function Network.is_active()
		return Network._is_active
	end

	local init_steam_server = Network.init_steam_server

	if init_steam_server then
		function Network.init_steam_server(...)
			local server = init_steam_server(...)

			if server then
				Network._is_active = true
			end

			return server
		end
	end

	local shutdown_steam_server = Network.shutdown_steam_server

	if shutdown_steam_server then
		function Network.shutdown_steam_server(...)
			shutdown_steam_server(...)

			Network._is_active = false
		end
	end

	local init_steam_client = Network.init_steam_client

	if init_steam_client then
		function Network.init_steam_client(...)
			local client = init_steam_client(...)

			if client then
				Network._is_active = true
			end

			return client
		end
	end

	local shutdown_steam_client = Network.shutdown_steam_client

	if shutdown_steam_client then
		function Network.shutdown_steam_client(...)
			shutdown_steam_client(...)

			Network._is_active = false
		end
	end

	local init_lan_client = Network.init_lan_client

	if init_lan_client then
		function Network.init_lan_client(...)
			local client = init_lan_client(...)

			if client then
				Network._is_active = true
			end

			return client
		end
	end

	local shutdown_lan_client = Network.shutdown_lan_client

	if shutdown_lan_client then
		function Network.shutdown_lan_client(...)
			shutdown_lan_client(...)

			Network._is_active = false
		end
	end

	local init_wan_server = Network.init_wan_server

	if init_wan_server then
		function Network.init_wan_server(...)
			local server = init_wan_server(...)

			if server then
				Network._is_active = true
			end

			return server
		end
	end

	local init_wan_client = Network.init_wan_client

	if init_wan_client then
		function Network.init_wan_client(...)
			local client = init_wan_client(...)

			if client then
				Network._is_active = true
			end

			return client
		end
	end
end
