local TabbedMenuViewBase = require("scripts/ui/views/tabbed_menu_view_base")
local Definitions = require("scripts/ui/views/social_menu_view/social_menu_view_definitions")
local SocialMenuView = class("SocialMenuView", "TabbedMenuViewBase")

function SocialMenuView:init(settings, context)
	SocialMenuView.super.init(self, Definitions, settings, context)

	self._pass_draw = false
end

function SocialMenuView:on_enter()
	SocialMenuView.super.on_enter(self)
	Managers.account:refresh_communcation_restrictions()
end

function SocialMenuView:on_exit()
	SocialMenuView.super.on_exit(self)
	Managers.account:refresh_communcation_restrictions()
end

return SocialMenuView
