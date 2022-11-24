local InvitesDummy = class("InvitesDummy")

function InvitesDummy:init()
end

function InvitesDummy:update()
end

function InvitesDummy:has_invite()
	return false
end

function InvitesDummy:get_invite()
	return nil
end

function InvitesDummy:send_invite()
end

function InvitesDummy:destroy()
end

return InvitesDummy
