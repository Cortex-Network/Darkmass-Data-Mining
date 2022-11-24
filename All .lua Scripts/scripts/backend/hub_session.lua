local Interface = {
	"fetch_server_details",
	"update"
}
local HubSession = class("HubSession")

function HubSession:fetch_server_details(session_id)
	return Managers.backend:title_request("/hub/sessions/" .. session_id .. "/serverdetails"):next(function (data)
		return data.body
	end)
end

function HubSession:update(session_id, jwt_sign_key_id, connection_info, fleet_id, time_at_utilized, deployment_id, participants, status)
	local data = {
		status = status,
		jwtSignKeyId = jwt_sign_key_id,
		connectionInfo = connection_info,
		fleetId = fleet_id,
		timeAtUtilized = time_at_utilized,
		deploymentId = deployment_id,
		connectedParticipants = participants
	}

	return Managers.backend:title_request("/hub/sessions/" .. session_id .. "/update", {
		method = "POST",
		body = data
	}):next(function (data)
		return data.body
	end)
end

function HubSession:get_hub_config()
	return Managers.backend:title_request("/hub/config"):next(function (data)
		return data.body
	end)
end

implements(HubSession, Interface)

return HubSession
