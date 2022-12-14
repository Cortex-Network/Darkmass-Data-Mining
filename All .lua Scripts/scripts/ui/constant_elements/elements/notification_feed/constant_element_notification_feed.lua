local Definitions = require("scripts/ui/constant_elements/elements/notification_feed/constant_element_notification_feed_definitions")
local ConstantElementNotificationFeedSettings = require("scripts/ui/constant_elements/elements/notification_feed/constant_element_notification_feed_settings")
local UIWidget = require("scripts/managers/ui/ui_widget")
local UIFonts = require("scripts/managers/ui/ui_fonts")
local UIRenderer = require("scripts/managers/ui/ui_renderer")
local ItemUtils = require("scripts/utilities/items")
local WalletSettings = require("scripts/settings/wallet_settings")
local TextUtils = require("scripts/utilities/ui/text")
local CriteriaParser = require("scripts/managers/contracts/utility/criteria_parser")
local UISettings = require("scripts/settings/ui/ui_settings")
local UISoundEvents = require("scripts/settings/ui/ui_sound_events")
local DEBUG_RELOAD = true

local function _apply_package_item_icon_cb_func(widget, item)
	local icon = item.icon
	local material_values = widget.style.icon.material_values
	material_values.texture_map = icon
end

local function _remove_package_item_icon_cb_func(widget)
	local material_values = widget.style.icon.material_values
	material_values.texture_map = nil
end

local function _apply_live_item_icon_cb_func(widget, grid_index, rows, columns, render_target)
	local material_values = widget.style.icon.material_values
	material_values.use_placeholder_texture = 0
	material_values.use_render_target = 1
	material_values.rows = rows
	material_values.columns = columns
	material_values.grid_index = grid_index - 1
	material_values.render_target = render_target
end

local function _remove_live_item_icon_cb_func(widget)
	local material_values = widget.style.icon.material_values
	material_values.use_placeholder_texture = 1
	material_values.texture_icon = nil
end

local ConstantElementNotificationFeed = class("ConstantElementNotificationFeed", "ConstantElementBase")
local MESSAGE_TYPES = table.enum("default", "alert", "mission", "item_granted", "currency", "achievement", "contract", "custom", "matchmaking")

function ConstantElementNotificationFeed:init(parent, draw_layer, start_scale)
	ConstantElementNotificationFeed.super.init(self, parent, draw_layer, start_scale, Definitions)

	self._notifications = {}
	self._queue_notifications = {}
	self._num_notifications = 0
	self._notification_id_counter = 0
	self._notification_templates = {
		default = {
			animation_exit = "popup_leave",
			animation_enter = "popup_enter",
			total_time = 5,
			priority_order = 2,
			widget_definition = Definitions.notification_message
		},
		alert = {
			animation_exit = "popup_leave",
			animation_enter = "popup_enter",
			total_time = 5,
			priority_order = 1,
			widget_definition = Definitions.notification_message
		},
		mission = {
			animation_exit = "popup_leave",
			animation_enter = "popup_enter",
			priority_order = 1,
			widget_definition = Definitions.notification_message
		},
		item_granted = {
			animation_exit = "popup_leave",
			animation_enter = "popup_enter",
			total_time = 5,
			priority_order = 1,
			widget_definition = Definitions.notification_message
		},
		currency = {
			animation_exit = "popup_leave",
			animation_enter = "popup_enter",
			total_time = 5,
			priority_order = 1,
			widget_definition = Definitions.notification_message
		},
		contract = {
			animation_exit = "popup_leave",
			animation_enter = "popup_enter",
			total_time = 5,
			priority_order = 1,
			widget_definition = Definitions.notification_message
		},
		achievement = {
			animation_exit = "popup_leave",
			animation_enter = "popup_enter",
			total_time = 5,
			priority_order = 1,
			widget_definition = Definitions.notification_message
		},
		custom = {
			animation_exit = "popup_leave",
			animation_enter = "popup_enter",
			total_time = 5,
			priority_order = 1,
			widget_definition = Definitions.notification_message
		},
		matchmaking = {
			animation_exit = "popup_leave",
			animation_enter = "popup_enter",
			priority_order = 1,
			widget_definition = Definitions.notification_message
		}
	}
	local event_manager = Managers.event
	local events = ConstantElementNotificationFeedSettings.events

	for i = 1, #events do
		local event = events[i]

		event_manager:register(self, event[1], event[2])
	end
end

function ConstantElementNotificationFeed:_on_item_icon_loaded(notification, item, grid_index, rows, columns, render_target)
	local widget = notification.widget
	local item_type = item.item_type

	if item_type == "WEAPON_MELEE" or item_type == "WEAPON_RANGED" or item_type == "GADGET" or item_type == "WEAPON_SKIN" or item_type == "WEAPON_TRINKET" then
		_apply_live_item_icon_cb_func(widget, grid_index, rows, columns, render_target)
	elseif item_type == "PORTRAIT_FRAME" or item_type == "CHARACTER_INSIGNIA" then
		_apply_package_item_icon_cb_func(widget, item)
	else
		_apply_live_item_icon_cb_func(widget, grid_index, rows, columns, render_target)
	end
end

function ConstantElementNotificationFeed:event_add_notification_message(message_type, data, callback, sound_event)
	self:_add_notification_message(message_type, data, callback, sound_event)
end

function ConstantElementNotificationFeed:event_update_notification_message(notification_id, texts)
	local notification = self:_notification_by_id(notification_id)

	if notification then
		self:_set_texts(notification, texts)
	end
end

function ConstantElementNotificationFeed:_set_texts(notification, texts)
	local widget = notification.widget

	for i = 1, #texts do
		local text = texts[i]
		widget.content[string.format("text_%d", i)] = text
	end
end

function ConstantElementNotificationFeed:event_remove_notification(notification_id)
	local notification = self:_notification_by_id(notification_id)

	if notification then
		self:_remove_notification(notification)
	end
end

function ConstantElementNotificationFeed:event_clear_notifications()
	self:clear()
end

function ConstantElementNotificationFeed:_get_new_id()
	self._notification_id_counter = self._notification_id_counter + 1

	return self._notification_id_counter
end

function ConstantElementNotificationFeed:clear()
	while #self._notifications > 0 do
		local notification = self._notifications[1]

		self:_remove_notification(notification)
	end
end

function ConstantElementNotificationFeed:destroy()
	ConstantElementNotificationFeed.super.destroy(self)

	local event_manager = Managers.event
	local events = ConstantElementNotificationFeedSettings.events

	for i = 1, #events do
		local event = events[i]

		event_manager:unregister(self, event[1])
	end
end

function ConstantElementNotificationFeed:_generate_notification_data(message_type, data)
	local notification_data = nil

	if message_type == MESSAGE_TYPES.default then
		notification_data = {
			texts = {
				{
					display_name = data
				}
			}
		}
	elseif message_type == MESSAGE_TYPES.mission then
		notification_data = {
			texts = {
				{
					display_name = data
				}
			}
		}
	elseif message_type == MESSAGE_TYPES.alert then
		slot4 = {
			texts = {
				{
					display_name = data.text,
					color = {
						255,
						255,
						101,
						101
					}
				}
			},
			color = {
				255 * ConstantElementNotificationFeedSettings.default_alpha_value,
				85,
				26,
				26
			},
			line_color = {
				255,
				255,
				101,
				101
			}
		}

		if data.type == "server" then
			-- Nothing
		end

		slot4.icon_color = {
			255,
			255,
			208,
			208
		}
		slot4.enter_sound_event = UISoundEvents.notification_warning
		notification_data = slot4
	elseif message_type == MESSAGE_TYPES.item_granted then
		local item = data
		local item_type = item.item_type
		local has_rarity = not not item.rarity
		local texts, rarity_color = nil
		local enter_sound_event = UISoundEvents.notification_item_received_rarity_1

		if has_rarity then
			local sound_event_name = string.format("notification_item_received_rarity_%d", item.rarity)
			enter_sound_event = UISoundEvents[sound_event_name] or enter_sound_event
			rarity_color = ItemUtils.rarity_color(item)
			texts = {
				{
					display_name = ItemUtils.display_name(item),
					color = rarity_color
				},
				{
					display_name = ItemUtils.rarity_display_name(data),
					color = rarity_color
				},
				{
					display_name = Localize("loc_notification_desc_added_to_inventory")
				}
			}
		else
			texts = {
				{
					display_name = ItemUtils.display_name(item)
				},
				{
					display_name = Localize(UISettings.item_type_localization_lookup[item.item_type]),
					color = Color.terminal_frame(255, true)
				},
				{
					display_name = Localize("loc_notification_desc_added_to_inventory")
				}
			}
		end

		local icon, icon_size = nil

		if item_type == "PORTRAIT_FRAME" then
			icon = "content/ui/materials/base/ui_default_base"
			icon_size = "portrait_frame"
		elseif item_type == "CHARACTER_INSIGNIA" then
			icon = "content/ui/materials/base/ui_default_base"
			icon_size = "insignia"
		elseif item_type == "WEAPON_MELEE" or item_type == "WEAPON_RANGED" or item_type == "WEAPON_TRINKET" or item_type == "WEAPON_SKIN" then
			icon = "content/ui/materials/icons/items/containers/item_container_landscape"
			icon_size = "large_weapon"
		elseif item_type == "GADGET" then
			icon = "content/ui/materials/icons/items/containers/item_container_landscape"
			icon_size = "large_gadget"
		else
			icon = "content/ui/materials/icons/items/containers/item_container_landscape"
			icon_size = "large_cosmetic"
		end

		local background_rarity_color = rarity_color and table.clone(rarity_color)

		if background_rarity_color then
			background_rarity_color[1] = background_rarity_color[1] * ConstantElementNotificationFeedSettings.default_alpha_value
		end

		notification_data = {
			show_shine = true,
			glow_opacity = 0.35,
			scale_icon = true,
			texts = texts,
			icon = icon,
			item = item,
			icon_size = icon_size,
			color = background_rarity_color,
			line_color = rarity_color,
			enter_sound_event = enter_sound_event
		}
	elseif message_type == MESSAGE_TYPES.currency then
		local currency_type = data.currency
		local amount = data.amount
		local wallet_settings = WalletSettings[currency_type]

		if wallet_settings then
			local icon_texture_large = wallet_settings and wallet_settings.icon_texture_big
			local selected_color = Color.terminal_corner_selected(255, true)
			local text = string.format("{#color(%d,%d,%d)}%s %s{#reset()} added", selected_color[2], selected_color[3], selected_color[4], TextUtils.format_currency(amount), Localize(wallet_settings.display_name))
			notification_data = {
				icon_size = "medium",
				texts = {
					{
						display_name = text
					}
				},
				icon = icon_texture_large
			}
		end
	elseif message_type == MESSAGE_TYPES.achievement then
		notification_data = {
			icon_size = "medium",
			icon = "content/ui/materials/icons/achievements/achievement_icon_container",
			texts = {
				{
					display_name = string.format("\"%s\"", data:label()),
					color = {
						255,
						248,
						240,
						222
					}
				},
				{
					display_name = Localize("loc_notification_desc_achievement_completed"),
					color = {
						255,
						200,
						182,
						149
					}
				}
			},
			icon_material_values = {
				frame = "content/ui/textures/icons/achievements/frames/achieved",
				icon = data:icon(),
				icon_color = Color.ui_achievement_icon_completed(255, true)
			},
			color = {
				255 * ConstantElementNotificationFeedSettings.default_alpha_value,
				82,
				73,
				45
			},
			enter_sound_event = UISoundEvents.notification_achievement
		}
	elseif message_type == MESSAGE_TYPES.contract then
		local criteria = data.criteria
		local title, _, _ = CriteriaParser.localize_criteria(criteria)
		local type = criteria.taskType
		notification_data = {
			icon = "content/ui/materials/icons/contracts/contract_task",
			icon_size = "medium",
			texts = {
				{
					display_name = title,
					color = Color.terminal_corner_selected(255, true)
				},
				{
					display_name = Localize("loc_notification_desc_contract_task_completed")
				}
			},
			icon_material_values = {
				checkbox = 1,
				contract_type = type and UISettings.contracts_icons_by_type[type] or UISettings.contracts_icons_by_type.default
			},
			icon_color = Color.terminal_text_header(255, true)
		}
	elseif message_type == MESSAGE_TYPES.custom then
		notification_data = {
			texts = {
				{
					display_name = data.line_1,
					color = data.line_1_color
				},
				{
					display_name = data.line_2,
					color = data.line_2_color
				},
				{
					display_name = data.line_3,
					color = data.line_3_color
				}
			},
			icon = data.icon,
			icon_size = data.icon_size,
			color = data.color,
			line_color = data.line_color,
			icon_color = data.icon_color,
			glow_opacity = data.glow_opacity or 0,
			show_shine = data.show_shine or false,
			scale_icon = data.scale_icon or false
		}
	elseif message_type == MESSAGE_TYPES.matchmaking then
		notification_data = {
			texts = {
				{
					display_name = data.texts[1],
					color = {
						255,
						200,
						200,
						200
					}
				},
				{
					font_size = 18,
					display_name = data.texts[2],
					color = {
						255,
						140,
						140,
						140
					}
				},
				{
					display_name = data.texts[3],
					color = {
						255,
						200,
						182,
						149
					}
				}
			}
		}
	end

	if not notification_data then
		return
	end

	notification_data.type = message_type
	notification_data.enter_sound_event = notification_data.enter_sound_event or UISoundEvents.notification_default_enter
	notification_data.exit_sound_event = notification_data.exit_sound_event or UISoundEvents.notification_default_exit

	return notification_data
end

function ConstantElementNotificationFeed:_add_notification_message(message_type, data, callback, sound_event)
	local notifications = self._notifications
	local num_notifications = #notifications

	if ConstantElementNotificationFeedSettings.max_visible_notifications <= num_notifications then
		self._queue_notifications[#self._queue_notifications + 1] = {
			message_type = message_type,
			data = data,
			callback = callback,
			sound_event = sound_event
		}

		self:_update_notification_queue_counter()

		return
	end

	local notification_data = self:_generate_notification_data(message_type, data)

	if notification_data then
		local notification = self:_create_notification_entry(notification_data)
		local notification_id = notification.id

		if callback then
			callback(notification_id)
		end

		if notification.animation_enter then
			local sound_event = sound_event or notification.enter_sound_event

			if sound_event then
				Managers.ui:play_2d_sound(sound_event)
			end

			self:_start_animation(notification.animation_enter, notification.widget)
		end
	end
end

function ConstantElementNotificationFeed:_remove_notification(notification_to_remove)
	local notifications = self._notifications

	for i = 1, #notifications do
		local notification = notifications[i]
		local widget = notification_to_remove.widget

		if notification == notification_to_remove then
			if notification_to_remove.item then
				local item = notification_to_remove.item
				local item_type = item.item_type

				if item_type == "PORTRAIT_FRAME" or item_type == "CHARACTER_INSIGNIA" then
					_remove_package_item_icon_cb_func(widget)
				else
					_remove_live_item_icon_cb_func(widget)
				end

				Managers.ui:unload_item_icon(widget.content.icon_load_id)
			end

			self:_unregister_widget_name(widget.name)
			table.remove(notifications, i)

			if self._queue_notifications[1] and ConstantElementNotificationFeedSettings.max_visible_notifications > #self._notifications then
				local notification = self._queue_notifications[1]
				local message_type = notification.message_type
				local data = notification.data
				local callback = notification.callback
				local sound_event = notification.sound_event

				self:_add_notification_message(message_type, data, callback, sound_event)
				table.remove(self._queue_notifications, 1)
				self:_update_notification_queue_counter()
			end
		end
	end
end

function ConstantElementNotificationFeed:_create_notification_entry(notification_data)
	local notification_type = notification_data.type
	local notification_template = self._notification_templates[notification_type]
	local priority_order = notification_template.priority_order
	local id = self:_get_new_id()
	local name = "notification_" .. id
	local pass_template_function = notification_template.widget_definition.pass_template_function
	local pass_template = pass_template_function and pass_template_function(self) or notification_template.widget_definition.pass_template
	local widget_definition = UIWidget.create_definition(pass_template, "background", nil)
	local widget = self:_create_widget(name, widget_definition)
	local notification = {
		priority_order = notification_template.priority_order,
		total_time = notification_template.total_time,
		widget = widget,
		id = id,
		time = 0,
		animation_enter = notification_template.animation_enter,
		animation_exit = notification_template.animation_exit,
		enter_sound_event = notification_data.enter_sound_event,
		exit_sound_event = notification_data.exit_sound_event
	}
	local notifications = self._notifications
	local num_notifications = #notifications
	local init = notification_template.widget_definition.init

	if init then
		init(self, widget, notification_data)
	end

	local item = notification_data.item

	if item then
		local slots = item.slots

		if slots then
			local slot_name = slots[1]
			local item_state_machine = item.state_machine
			local item_animation_event = item.animation_event
			local context = {
				camera_focus_slot_name = slot_name,
				state_machine = item_state_machine,
				animation_event = item_animation_event
			}
			local on_load_callback = callback(self, "_on_item_icon_loaded", notification, item)

			Managers.ui:load_item_icon(item, on_load_callback, context)
		end
	end

	local start_index = nil

	if num_notifications > 0 then
		for i = 1, num_notifications do
			if priority_order <= notifications[i].priority_order then
				start_index = i

				break
			elseif i == num_notifications then
				start_index = i + 1
			end
		end
	end

	start_index = start_index or 1
	local start_height = self:_get_height_of_notification_index(start_index)

	self:_set_widget_position(widget, nil, start_height)
	table.insert(notifications, start_index, notification)

	return notification
end

function ConstantElementNotificationFeed:_notification_by_id(notification_id)
	local notifications = self._notifications

	for i = 1, #notifications do
		local notification = notifications[i]

		if notification.id == notification_id then
			return notification
		end
	end
end

function ConstantElementNotificationFeed:_get_notifications_text_height(notification, ui_renderer)
	local widget = notification.widget
	local content = widget.content
	local text = content.text
	local style = widget.style
	local text_style = style.text
	local text_font_data = UIFonts.data_by_type(text_style.font_type)
	local text_font = text_font_data.path
	local text_size = text_style.size
	local text_options = UIFonts.get_font_options_by_style(text_style)
	local _, text_height = UIRenderer.text_size(ui_renderer, text, text_style.font_type, text_style.font_size, text_size, text_options)

	return text_height
end

function ConstantElementNotificationFeed:update(dt, t, ui_renderer, render_settings, input_service)
	if DEBUG_RELOAD then
		DEBUG_RELOAD = false

		self:clear()
	end

	self:_align_notification_widgets(dt)
	ConstantElementNotificationFeed.super.update(self, dt, t, ui_renderer, render_settings, input_service)
end

function ConstantElementNotificationFeed:_align_notification_widgets(dt)
	local entry_spacing = ConstantElementNotificationFeedSettings.entry_spacing
	local offset_y = 0
	local notifications = self._notifications

	for i = 1, #notifications do
		local notification = notifications[i]

		if notification then
			local widget = notification.widget
			local widget_offset = widget.offset
			local widget_height = widget.size[2]

			if widget_offset[2] < offset_y then
				widget_offset[2] = math.lerp(widget_offset[2], offset_y, dt * 6)
			else
				widget_offset[2] = math.lerp(widget_offset[2], offset_y, dt * 2)
			end

			offset_y = offset_y + widget_height + entry_spacing
		end
	end
end

function ConstantElementNotificationFeed:_get_height_of_notification_index(index)
	local notifications = self._notifications
	local notification = notifications[index - 1]

	if not notification then
		return 0
	else
		local widget = notification.widget
		local widget_offset = widget.offset

		return widget_offset[2]
	end
end

function ConstantElementNotificationFeed:_set_widget_position(widget, x, y)
	local widget_offset = widget.offset

	if x then
		widget_offset[1] = x
	end

	if y then
		widget_offset[2] = y
	end
end

function ConstantElementNotificationFeed:_draw_widgets(dt, t, input_service, ui_renderer, render_settings)
	ConstantElementNotificationFeed.super._draw_widgets(self, dt, t, input_service, ui_renderer, render_settings)

	local notifications = self._notifications

	for i = #notifications, 1, -1 do
		local notification = notifications[i]

		if notification then
			notification.time = (notification.time or 0) + dt
			local widget = notification.widget

			UIWidget.draw(widget, ui_renderer)

			local total_time = notification.total_time
			local time = notification.time

			if time and total_time and total_time <= time then
				self:_evaluate_notification_removal(notification)
			end
		end
	end
end

function ConstantElementNotificationFeed:_evaluate_notification_removal(notification)
	local widget = notification.widget

	if notification.animation_exit_id and not self:_is_animation_completed(notification.animation_exit_id) then
		return
	elseif notification.animation_exit and not notification.animation_exit_id then
		local sound_event = notification.exit_sound_event

		if sound_event then
			Managers.ui:play_2d_sound(sound_event)
		end

		notification.animation_exit_id = self:_start_animation(notification.animation_exit, widget)
	else
		notification.animation_exit_id = nil

		self:_remove_notification(notification)
	end
end

function ConstantElementNotificationFeed:_update_notification_queue_counter()
	self._widgets_by_name.queue_notification_counter.content.visible = #self._queue_notifications > 0
	self._widgets_by_name.queue_notification_counter.content.queue_counter = Localize("loc_notification_queue_more", true, {
		queue = #self._queue_notifications
	})
end

return ConstantElementNotificationFeed
