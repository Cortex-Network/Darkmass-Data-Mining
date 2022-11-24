local Corruptor = component("Corruptor")

function Corruptor:init(unit)
	local corruptor_extension = ScriptUnit.fetch_component_extension(unit, "corruptor_system")

	if corruptor_extension then
		local use_trigger = self:get_data(unit, "use_trigger")

		corruptor_extension:setup_from_component(use_trigger)

		self._corruptor_extension = corruptor_extension
	end
end

function Corruptor:editor_init(unit)
end

function Corruptor:enable(unit)
end

function Corruptor:disable(unit)
end

function Corruptor:destroy(unit)
end

function Corruptor.events:demolition_segment_start()
	if self._corruptor_extension then
		self._corruptor_extension:awake()
	end
end

function Corruptor.events:demolition_stage_start()
	if self._corruptor_extension then
		self._corruptor_extension:expose()
	end
end

function Corruptor.events:died()
	if Managers.stats.can_record_stats() then
		Managers.stats:record_team_corruptor_destroyed()
	end

	if self._corruptor_extension then
		self._corruptor_extension:died()
	end
end

function Corruptor.events:add_damage(damage, hit_actor, attack_direction)
	if self._corruptor_extension then
		self._corruptor_extension:damaged(damage)
	end
end

function Corruptor:activate_segment_units()
	if self._corruptor_extension then
		self._corruptor_extension:activate_segment_units()
	end
end

Corruptor.component_data = {
	use_trigger = {
		ui_type = "check_box",
		value = false,
		ui_name = "Use Trigger"
	},
	inputs = {
		activate_segment_units = {
			accessibility = "private",
			type = "event"
		}
	},
	extensions = {
		"CorruptorExtension"
	}
}

return Corruptor
