local Promise = require("scripts/foundation/utilities/promise")
local PERMISSIVE_RESPONSE = {
	has_privilege = true
}
local PrivilegesManagerPermissive = class("PrivilegesManagerPermissive")

function PrivilegesManagerPermissive:init()
end

function PrivilegesManagerPermissive:multiplayer_privilege(resolve_privilege)
	local p = Promise:new()

	p:resolve(PERMISSIVE_RESPONSE)

	return p
end

function PrivilegesManagerPermissive:communications_privilege(resolve_privilege)
	local p = Promise:new()

	p:resolve(PERMISSIVE_RESPONSE)

	return p
end

function PrivilegesManagerPermissive:cross_play(resolve_privilege)
	local p = Promise:new()

	p:resolve(PERMISSIVE_RESPONSE)

	return p
end

function PrivilegesManagerPermissive:update(dt, t)
end

return PrivilegesManagerPermissive
