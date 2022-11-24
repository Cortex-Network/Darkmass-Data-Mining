local Interface = {
	"fetch_connection_info"
}
local Immaterium = class("Immaterium")

function Immaterium:fetch_connection_info()
	return Managers.backend:title_request("/immaterium/connectioninfo", {
		method = "GET"
	}):next(function (data)
		return data.body
	end)
end

implements(Immaterium, Interface)

return Immaterium
