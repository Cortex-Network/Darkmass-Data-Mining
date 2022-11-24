local AnimDrivenShader = component("AnimDrivenShader")

function AnimDrivenShader:init(unit)
	self.parent_node_name = self:get_data(unit, "parent_node_name")
	self.animated_node_name = self:get_data(unit, "animated_node_name")
	self.material_variable = self:get_data(unit, "material_variable")
	self.include_children = self:get_data(unit, "include_children")
	self.requirements = {
		animated_node = Unit.has_node(unit, self.animated_node_name),
		parent_node = Unit.has_node(unit, self.parent_node_name),
		material = self.material ~= "",
		material_variable = self.material_variable ~= ""
	}

	self:enable(unit)

	if self.enabled then
		self.parent_node_index = Unit.node(unit, self.parent_node_name)
		self.animated_node_index = Unit.node(unit, self.animated_node_name)

		self:setShaderVariable(unit)
	end
end

function AnimDrivenShader:enable(unit)
	self.enabled = true

	for key, value in pairs(self.requirements) do
		if not value then
			self.enabled = false
		end
	end
end

function AnimDrivenShader:disable(unit)
	self.enabled = false
end

function AnimDrivenShader:destroy(unit)
end

function AnimDrivenShader:update(unit, dt, t)
	if self.enabled then
		self:setShaderVariable(unit)
	end
end

function AnimDrivenShader:changed(unit)
end

function AnimDrivenShader:setShaderVariable(unit)
	local px, py, pz = Vector3.to_elements(Unit.world_position(unit, self.parent_node_index))
	local ax, ay, az = Vector3.to_elements(Unit.world_position(unit, self.animated_node_index))
	local distance = math.sqrt((ax - px)^2 + (ay - py)^2 + (az - pz)^2)

	Unit.set_scalar_for_materials(unit, self.material_variable, distance, self.include_children)
end

AnimDrivenShader.component_data = {
	parent_node_name = {
		ui_type = "text_box",
		value = "",
		ui_name = "Parent Node"
	},
	animated_node_name = {
		ui_type = "text_box",
		value = "",
		ui_name = "Animated Node"
	},
	material_variable = {
		ui_type = "text_box",
		value = "",
		ui_name = "Material Variable"
	},
	include_children = {
		ui_type = "check_box",
		value = false,
		ui_name = "Unclude Children"
	}
}

return AnimDrivenShader
