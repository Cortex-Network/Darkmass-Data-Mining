local Views = require("scripts/ui/views/views")
local UIManagerTestify = {
	all_views = function (_, ui_manager)
		return Views
	end
}

function UIManagerTestify.close_view(view_name, ui_manager)
	ui_manager:close_view(view_name)
end

function UIManagerTestify.is_view_active(view_name, ui_manager)
	return ui_manager:view_active(view_name)
end

function UIManagerTestify.open_view(view, ui_manager)
	local context = view.dummy_data or {
		debug_preview = true,
		can_exit = true
	}

	ui_manager:open_view(view.view_name, nil, , , , context)
end

function UIManagerTestify.wait_for_view(view_name, ui_manager)
	if not ui_manager:view_active(view_name) then
		return Testify.RETRY
	end
end

function UIManagerTestify.wait_for_view_to_close(view_name, ui_manager)
	if ui_manager:view_active(view_name) then
		return Testify.RETRY
	end
end

return UIManagerTestify
