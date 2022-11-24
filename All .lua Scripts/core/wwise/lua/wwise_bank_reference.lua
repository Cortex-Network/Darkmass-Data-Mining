WwiseBankReference = WwiseBankReference or {}

local function lazy_init(self)
	if not self.references then
		self.references = {}
	end
end

function WwiseBankReference:add(bank_resource_name)
	lazy_init(self)

	self.references[bank_resource_name] = (self.references[bank_resource_name] or 0) + 1
end

function WwiseBankReference:remove(bank_resource_name)
	lazy_init(self)

	local new_count = (self.references[bank_resource_name] or 0) - 1

	if new_count <= 0 then
		self.references[bank_resource_name] = nil
	end
end

function WwiseBankReference:count(bank_resource_name)
	lazy_init(self)

	return self.references[bank_resource_name] or 0
end

return WwiseBankReference
