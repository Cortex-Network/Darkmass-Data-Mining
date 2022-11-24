core = rawget(_G, "core") or {}
core.vis_modes = core.vis_modes or {}

function core.render_vis_on(settings)
	for setting, prev_value in pairs(core.vis_modes) do
		Application.set_render_setting(setting, tostring(prev_value))
	end

	for render_setting, value in pairs(settings) do
		local prev_value = Application.render_config("settings", render_setting)

		Application.set_render_setting(render_setting, tostring(value))
		print(render_setting .. ": " .. tostring(prev_value) .. " -> " .. tostring(value))

		core.vis_modes[render_setting] = prev_value
	end
end
