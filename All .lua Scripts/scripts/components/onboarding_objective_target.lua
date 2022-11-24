local OnboardingObjectiveTarget = component("OnboardingObjectiveTarget")

function OnboardingObjectiveTarget:init(unit)
	self._unit = unit

	self:enable(unit)
end

function OnboardingObjectiveTarget:enable(unit)
end

function OnboardingObjectiveTarget:disable(unit)
end

function OnboardingObjectiveTarget:destroy(unit)
end

function OnboardingObjectiveTarget:is_primary_marker()
	return self:get_data(self._unit, "primary_marker")
end

OnboardingObjectiveTarget.component_data = {
	primary_marker = {
		ui_type = "check_box",
		value = false,
		ui_name = "Primary Marker"
	},
	extensions = {}
}

return OnboardingObjectiveTarget
