local BakedPhysics = component("BakedPhysics")

function BakedPhysics:editor_init(unit)
end

function BakedPhysics:editor_reset_physics(unit)
	self:enable_actors(unit)
end

function BakedPhysics:enable_actors(unit)
	local num_actors = Unit.num_actors(unit)

	for i = 1, Unit.num_actors(unit) do
		Unit.create_actor(unit, i, false)
		Actor.put_to_sleep(Unit.actor(unit, i))
	end
end

function BakedPhysics:init(unit)
	self:enable(unit)

	if Unit.has_data(unit, "dynamic_ingame") and Unit.get_data(unit, "dynamic_ingame") then
		self:enable_actors(unit)
	end
end

function BakedPhysics:enable(unit)
	Unit.set_visibility(unit, "picking", false)
end

function BakedPhysics:disable(unit)
end

function BakedPhysics:destroy(unit)
end

BakedPhysics.component_config = {
	disable_event_public = false,
	enable_event_public = false,
	starts_enabled_default = true
}

return BakedPhysics
