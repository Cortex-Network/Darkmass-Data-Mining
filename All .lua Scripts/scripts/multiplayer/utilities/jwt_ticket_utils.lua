local JwtTicketUtils = {}

local function parse_jwt_payload(payload_json)
	local payload = cjson.decode(payload_json)
	local missionJson = payload.sessionSettings.missionJson

	if missionJson then
		payload.sessionSettings.missionJson = cjson.decode(missionJson)
	end

	return payload
end

function JwtTicketUtils.decode_jwt_ticket(jwt_ticket)
	local parts = string.split(jwt_ticket, ".")
	local header_base64 = parts[1]
	local header_json = string.decode_base64(header_base64)
	local header = cjson.decode(header_json)
	local payload_json = string.decode_base64(parts[2])
	local payload = parse_jwt_payload(payload_json)

	return header, payload
end

function JwtTicketUtils.verify_jwt_ticket(jwt_ticket, public_key)
	local is_valid = false

	if public_key == "none" then
		Log.info("JwtTicketUtils", "ticket is valid since public_key is set to 'none'")

		is_valid = true
	else
		is_valid = JWT.verify(jwt_ticket, public_key)
	end

	if is_valid then
		local header, payload = JwtTicketUtils.decode_jwt_ticket(jwt_ticket)

		return is_valid, header, payload
	else
		return false
	end
end

function JwtTicketUtils.create_matchmaking_jwt_ticket(backend_mission_data)
	local missionJson = nil

	if backend_mission_data then
		missionJson = cjson.encode(backend_mission_data)
	end

	local payload = {
		instanceId = "NO_INSTANCE_ID",
		sessionId = "NO_SESSION_ID",
		exp = 4109491289.0,
		iat = 4109491289.0,
		sessionSettings = {
			missionJson = missionJson
		}
	}
	payload = cjson.encode(payload)
	payload = string.encode_base64(payload)
	local header = string.encode_base64("{}")
	local jwt_ticket = string.format("%s.%s.", header, payload)

	return jwt_ticket
end

function JwtTicketUtils.join_jwt_ticket_array(jwt_ticket_array)
	local str = ""

	for i = 1, #jwt_ticket_array do
		local part = jwt_ticket_array[i]
		str = str .. part
	end

	return str
end

return JwtTicketUtils
