local ScriptViewport = require("scripts/foundation/utilities/script_viewport")
local BoneLodManager = class("BoneLodManager")

function BoneLodManager:init(world, is_dedicated_server, is_server)
	self._world = world
	self._bone_lod_viewport = nil
	local update_mode = nil

	if is_dedicated_server then
		update_mode = BoneLod.USE_HIGHEST_NON_ROOT_BONE_LOD
	elseif is_server then
		update_mode = BoneLod.USE_ALL_EXCEPT_ROOT_BONE_LOD
	else
		update_mode = BoneLod.USE_ALL_BONE_LOD
	end

	local lod_in_distance = GameParameters.bone_lod_in_distance
	local lod_out_distance = GameParameters.bone_lod_out_distance

	BoneLod.init(lod_in_distance, lod_out_distance, update_mode)
end

function BoneLodManager:destroy(...)
	BoneLod.destroy()
end

function BoneLodManager:pre_update()
	self:_update_animation_bone_lod()
end

function BoneLodManager:register_unit(unit, radius, impact_animation_on_children)
	local result = BoneLod.register_unit(unit, radius, impact_animation_on_children)

	return result
end

function BoneLodManager:unregister_unit(registration_id)
	BoneLod.unregister_unit(registration_id)
end

function BoneLodManager:register_bone_lod_viewport(viewport)
	self._bone_lod_viewport = viewport
end

function BoneLodManager:unregister_bone_lod_viewport(viewport)
	self._bone_lod_viewport = nil
end

function BoneLodManager:_update_animation_bone_lod()
	local viewport = self._bone_lod_viewport

	if viewport then
		local camera = ScriptViewport.camera(viewport)

		BoneLod.update(camera)
	end
end

return BoneLodManager
