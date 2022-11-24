local SplineFollower = component("SplineFollower")

function SplineFollower:init(unit)
end

function SplineFollower:enable(unit)
end

function SplineFollower:disable(unit)
end

function SplineFollower:destroy(unit)
end

SplineFollower.component_data = {
	extensions = {
		"SplineFollowerExtension"
	}
}

return SplineFollower
