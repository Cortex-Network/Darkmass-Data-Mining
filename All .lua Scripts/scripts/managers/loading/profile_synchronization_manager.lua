local ProfileSynchronizationManagerTestify = GameParameters.testify and require("scripts/managers/loading/profile_synchronization_manager_testify")
local ProfileSynchronizationManager = class("ProfileSynchronizationManager")

function ProfileSynchronizationManager:init()
	self._profile_synchronizer_client = nil
	self._profile_synchronizer_host = nil
end

function ProfileSynchronizationManager:destroy()
end

function ProfileSynchronizationManager:update(dt)
	if self._profile_synchronizer_host then
		self._profile_synchronizer_host:update(dt)
	end

	if GameParameters.testify then
		Testify:poll_requests_through_handler(ProfileSynchronizationManagerTestify, self)
	end
end

function ProfileSynchronizationManager:set_profile_synchroniser_client(profile_synchronizer_client)
	self._profile_synchronizer_client = profile_synchronizer_client
end

function ProfileSynchronizationManager:set_profile_synchroniser_host(profile_synchronizer_host)
	self._profile_synchronizer_host = profile_synchronizer_host
end

function ProfileSynchronizationManager:is_ready()
	return self._profile_synchronizer_client or self._profile_synchronizer_host
end

function ProfileSynchronizationManager:synchronizer_host()
	return self._profile_synchronizer_host
end

function ProfileSynchronizationManager:synchronizer_client()
	return self._profile_synchronizer_client
end

return ProfileSynchronizationManager
