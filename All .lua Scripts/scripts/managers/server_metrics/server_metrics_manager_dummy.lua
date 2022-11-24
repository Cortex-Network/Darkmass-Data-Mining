local ServerMetricsManagerDummy = class("DummyServerMetricsManager")
local ServerMetricsManagerInterface = require("scripts/managers/server_metrics/server_metrics_manager_interface")

function ServerMetricsManagerDummy:init()
end

function ServerMetricsManagerDummy:destroy()
end

function ServerMetricsManagerDummy:add_annotation(type_name, metadata)
end

function ServerMetricsManagerDummy:set_gauge(metric_name, value)
end

function ServerMetricsManagerDummy:update(dt)
end

implements(ServerMetricsManagerDummy, ServerMetricsManagerInterface)

return ServerMetricsManagerDummy
