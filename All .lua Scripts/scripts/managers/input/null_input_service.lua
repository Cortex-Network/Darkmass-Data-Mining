local NullInputService = class("NullInputService")

function NullInputService:init(parent)
	self._parent = parent
	self.name = parent.name
	self.type = parent.type
end

function NullInputService:is_null_service()
	return true
end

function NullInputService:null_service()
	return self
end

function NullInputService:get(action_name)
	return self._parent:get_default(action_name)
end

function NullInputService:get_default(action_name)
	return self._parent:get_default(action_name)
end

return NullInputService
