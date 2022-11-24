local Action = {}

function Action.current_action(weapon_action_component, weapon_template)
	local current_action_name = weapon_action_component.current_action_name

	if current_action_name == "none" then
		return "none", nil
	end

	if not weapon_template then
		return "none", nil
	end

	local current_action_settings = Action.action_settings(weapon_template, current_action_name)

	return current_action_name, current_action_settings
end

function Action.previous_action(weapon_action_component, weapon_template)
	local action_name = weapon_action_component.previous_action_name

	if action_name == "none" then
		return "none", nil
	end

	if not weapon_template then
		return "none", nil
	end

	local action_settings = Action.action_settings(weapon_template, action_name)

	return action_name, action_settings
end

function Action.action_settings(weapon_template, action_name)
	local action_settings = weapon_template.actions[action_name]

	return action_settings
end

function Action.current_action_settings_from_component(weapon_action_component, weapon_actions)
	local current_action_name = weapon_action_component.current_action_name
	local action_settings = current_action_name and weapon_actions[current_action_name]

	return action_settings
end

function Action.time_left(action_component, t)
	local is_infinite_duration = action_component.is_infinite_duration
	local end_t = is_infinite_duration and math.huge or action_component.end_t

	return end_t - t
end

return Action
