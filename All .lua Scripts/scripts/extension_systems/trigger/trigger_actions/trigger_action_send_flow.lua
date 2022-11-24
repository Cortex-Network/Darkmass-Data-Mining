require("scripts/extension_systems/trigger/trigger_actions/trigger_action_base")

local TriggerActionSendFlow = class("TriggerActionSendFlow", "TriggerActionBase")

function TriggerActionSendFlow:local_on_activate(unit)
	TriggerActionSendFlow.super.local_on_activate(self, unit)
	Unit.flow_event(self._volume_unit, "lua_trigger_activated")
end

function TriggerActionSendFlow:local_on_deactivate(unit)
	TriggerActionSendFlow.super.local_on_deactivate(self, unit)
	Unit.flow_event(self._volume_unit, "lua_trigger_deactivated")
end

return TriggerActionSendFlow
