local VendorViewBase = require("scripts/ui/views/vendor_view_base/vendor_view_base")
local Definitions = require("scripts/ui/views/marks_vendor_view/marks_vendor_view_definitions")
local MarksVendorViewSettings = require("scripts/ui/views/marks_vendor_view/marks_vendor_view_settings")
local MarksVendorView = class("MarksVendorView", "VendorViewBase")

function MarksVendorView:init(settings, context)
	MarksVendorView.super.init(self, Definitions, settings, context)

	local parent = context and context.parent
	self._parent = parent

	if parent then
		context.parent:set_is_handling_navigation_input(true)
	end
end

function MarksVendorView:_get_store()
	local store_service = Managers.data_service.store
	local store_promise = nil

	if self._show_temporary_store_items then
		store_promise = store_service:get_marks_store_temporary()
	else
		store_promise = store_service:get_marks_store()
	end

	return store_promise
end

function MarksVendorView:show_items()
	self:_clear_list()

	self._show_temporary_store_items = true

	self:_update_wallets():next(function ()
		self:_fetch_store_items()
	end)
end

function MarksVendorView:_on_purchase_complete(items)
	MarksVendorView.super._on_purchase_complete(self, items)
	self._parent:play_vo_events({
		"credit_store_servitor_purchase_c"
	}, "credit_store_servitor_c", nil, 1.4)
end

function MarksVendorView:dialogue_system()
	return self._parent:dialogue_system()
end

return MarksVendorView
