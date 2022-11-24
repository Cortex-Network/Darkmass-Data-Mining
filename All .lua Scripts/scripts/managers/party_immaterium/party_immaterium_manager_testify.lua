local PartyImmateriumTestify = {}

function PartyImmateriumTestify.accept_join_party()
	local constant_elements = Managers.ui:ui_constant_elements()
	local constant_element_popup_handler = constant_elements:element("ConstantElementPopupHandler")
	local widgets_by_name = constant_element_popup_handler:widgets_by_name()
	local accept_button = widgets_by_name.popup_widget_1

	if accept_button then
		constant_element_popup_handler:trigger_widget_callback(accept_button)
	else
		return Testify.RETRY
	end
end

function PartyImmateriumTestify.immaterium_join_party(party_id, party_immaterium_manager)
	party_immaterium_manager:join_party(party_id)
end

function PartyImmateriumTestify.immaterium_party_id(_, party_immaterium_manager)
	return party_immaterium_manager:party_id()
end

function PartyImmateriumTestify.leave_party_immaterium(_, party_immaterium_manager)
	return party_immaterium_manager:leave_party():next(function ()
	end)
end

return PartyImmateriumTestify
