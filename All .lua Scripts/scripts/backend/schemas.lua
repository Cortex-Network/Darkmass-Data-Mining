local Interface = {
	"fetch"
}
local Schemas = class("Schemas")

function Schemas:fetch()
	return Managers.backend:title_request("/schemas"):next(function (data)
		return data.body
	end)
end

implements(Schemas, Interface)

return Schemas
