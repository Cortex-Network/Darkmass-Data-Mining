local PACKAGES_TO_LOAD = {
	"packages/ui/ui_signin_assets"
}
local Loader = require("scripts/loading/loader")
local SigninLoader = class("SigninLoader")

function SigninLoader:init()
	self._load_done = false
	self._package_ids = {}
	self._package_loading_reference_counter = {}
end

function SigninLoader:destroy()
end

function SigninLoader:start_loading()
	local package_manager = Managers.package
	local package_ids = self._package_ids

	for _, package_name in pairs(PACKAGES_TO_LOAD) do
		self._package_loading_reference_counter[package_name] = (self._package_loading_reference_counter[package_name] or 0) + 1

		local function load_callback(id)
			self:_package_load_done_callback(package_name)
		end

		local id = package_manager:load(package_name, "SigninLoader", load_callback)
		package_ids[id] = package_name
	end
end

function SigninLoader:_package_load_done_callback(package_name)
	self._package_loading_reference_counter[package_name] = self._package_loading_reference_counter[package_name] - 1

	for ref_key, counter in pairs(self._package_loading_reference_counter) do
		if counter > 0 then
			return
		end
	end

	self._load_done = true
end

function SigninLoader:is_loading_done()
	return self._load_done
end

function SigninLoader:cleanup()
	local package_manager = Managers.package
	local package_ids = self._package_ids

	for id, package_name in pairs(package_ids) do
		package_manager:release(id)

		package_ids[id] = nil
	end

	self._load_done = false
end

implements(SigninLoader, Loader)

return SigninLoader
