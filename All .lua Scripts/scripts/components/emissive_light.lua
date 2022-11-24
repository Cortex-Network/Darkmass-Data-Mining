local EmissiveLight = component("EmissiveLight")

function EmissiveLight:init(unit)
	self:enable(unit)
end

function EmissiveLight:enable(unit)
	if Unit.num_lights(unit) >= 1 then
		local light = Unit.light(unit, 1)
		local color_intensity = Light.color_with_intensity(light)
		local color = Vector3.normalize(color_intensity)
		local intensity = Vector3.length(color_intensity)

		Unit.set_vector3_for_materials(unit, "emissive_color", color)
		Unit.set_scalar_for_materials(unit, "emissive_intensity_lumen", intensity)
	end
end

function EmissiveLight:disable(unit)
end

function EmissiveLight:destroy(unit)
end

EmissiveLight.component_data = {}

return EmissiveLight
