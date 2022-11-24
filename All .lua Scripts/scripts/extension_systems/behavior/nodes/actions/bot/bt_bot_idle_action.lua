require("scripts/extension_systems/behavior/nodes/bt_node")

local BtBotIdleAction = class("BtBotIdleAction", "BtNode")

function BtBotIdleAction:run(unit, breed, blackboard, scratchpad, action_data, dt, t)
	return "running"
end

return BtBotIdleAction
