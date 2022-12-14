local MaterialQuery = {}
local QUERY_DISTANCE = 0.6
local HALF_QUERY_DISTANCE = QUERY_DISTANCE * 0.5
local QUERIED_MATERIAL = {
	"surface_material"
}
local surface_materials = {
	"cloth",
	"concrete",
	"dirt_gravel",
	"dirt_mud",
	"dirt_sand",
	"dirt_soil",
	"dirt_trash",
	"dead_body",
	"nurgle_flesh",
	"glass_breakable",
	"glass_unbreakable",
	"ice_solid",
	"metal_catwalk",
	"metal_sheet",
	"metal_solid",
	"vegetation",
	"water_deep",
	"water_puddle",
	"wood_plywood",
	"wood_solid"
}
MaterialQuery.surface_materials = surface_materials
local lookup = {}

for ii = 1, #surface_materials do
	local material_name = surface_materials[ii]
	lookup[Unit.material_id(material_name)] = material_name
end

MaterialQuery.lookup = lookup
local groups = {
	default = {
		"cloth",
		"concrete",
		"ice_solid"
	},
	dirt = {
		"dirt_sand",
		"dirt_mud",
		"dirt_gravel",
		"dirt_soil",
		"dirt_trash",
		"vegetation"
	},
	flesh = {
		"dead_body",
		"nurgle_flesh"
	},
	glass = {
		"glass_breakable",
		"glass_unbreakable"
	},
	metal = {
		"metal_solid",
		"metal_sheet",
		"metal_catwalk"
	},
	water = {
		"water_deep",
		"water_puddle"
	},
	wood = {
		"wood_solid",
		"wood_plywood"
	}
}
MaterialQuery.groups = groups
local groups_lookup = {}

for group, materials in pairs(groups) do
	for _, material in pairs(materials) do
		groups_lookup[material] = group
	end
end

MaterialQuery.groups_lookup = groups_lookup

function MaterialQuery.query_material(physics_world, from, to, debug_name)
	local ray_vector = to - from
	local range = Vector3.length(ray_vector)
	local direction = ray_vector / range
	local hit, position, _, normal, hit_actor = PhysicsWorld.raycast(physics_world, from, direction, range, "closest", "types", "both", "collision_filter", "filter_ground_material_check")
	local hit_unit = hit and Actor.unit(hit_actor)

	if hit_unit then
		local material, material_id = MaterialQuery.query_unit_material(hit_unit, position, -normal)

		return true, material, position, normal, hit_unit, hit_actor
	else
		return false
	end
end

local _query_material_buffer = {}

function MaterialQuery.query_unit_material(hit_unit, query_position, query_direction)
	local query_offset = query_direction * HALF_QUERY_DISTANCE
	local query_start = query_position - query_offset
	local query_end = query_position + query_offset
	local material_ids = Unit.query_material(hit_unit, query_start, query_end, QUERIED_MATERIAL, _query_material_buffer)
	local material_id = material_ids[1]
	local material = MaterialQuery.lookup[material_id]

	return material, material_id
end

return MaterialQuery
