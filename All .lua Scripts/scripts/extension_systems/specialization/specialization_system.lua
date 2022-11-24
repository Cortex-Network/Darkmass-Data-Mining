require("scripts/extension_systems/specialization/player_unit_specialization_extension")
require("scripts/extension_systems/specialization/player_husk_specialization_extension")

local SpecializationSystem = class("SpecializationSystem", "ExtensionSystemBase")

function SpecializationSystem:init(...)
	SpecializationSystem.super.init(self, ...)
end

function SpecializationSystem:destroy()
	SpecializationSystem.super.destroy(self)
end

function SpecializationSystem:on_add_extension(world, unit, extension_name, extension_init_data, ...)
	local extension = SpecializationSystem.super.on_add_extension(self, world, unit, extension_name, extension_init_data, ...)

	return extension
end

return SpecializationSystem
