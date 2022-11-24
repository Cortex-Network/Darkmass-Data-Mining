local DLCDurable = class("DLCDurable")

function DLCDurable:init(durable_dlc_data)
end

function DLCDurable:update_license()
end

function DLCDurable:has_license()
	return false
end

function DLCDurable:package_details()
end

function DLCDurable:license_status_changed()
end

function DLCDurable:id()
	return nil
end

return DLCDurable
