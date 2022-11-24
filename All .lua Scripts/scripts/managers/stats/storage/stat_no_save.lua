local StatStorage = require("scripts/managers/stats/storage/stat_storage")
local StatNoSave = class("StatNoSave", "StatStorage")

function StatNoSave:set_value()
end

function StatNoSave:get_value()
end

implements(StatNoSave, StatStorage.INTERFACE)

return StatNoSave
