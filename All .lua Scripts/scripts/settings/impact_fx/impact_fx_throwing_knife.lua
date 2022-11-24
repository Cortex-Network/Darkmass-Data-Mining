local ArmorSettings = require("scripts/settings/damage/armor_settings")
local SurfaceMaterialSettings = require("scripts/settings/surface_material_settings")
local ImpactFxHelper = require("scripts/utilities/impact_fx_helper")
local armor_types = ArmorSettings.types
local hit_types = SurfaceMaterialSettings.hit_types
local default_armor_decal = nil
local blood_ball = {
	"content/decals/blood_ball/blood_ball"
}
local disgusting_blood_ball = {
	"content/decals/blood_ball/blood_ball_poxwalker"
}
local unarmored = {
	sfx = {
		weakspot_died = {
			{
				event = "wwise/events/weapon/play_bullet_hits_gen_unarmored",
				append_husk_to_event_name = false
			},
			{
				event = "wwise/events/weapon/play_psyker_throwing_knife_hit_death",
				only_1p = true
			},
			{
				event = "wwise/events/weapon/play_hit_indicator_death_knife",
				only_1p = true
			}
		},
		died = {
			{
				event = "wwise/events/weapon/play_bullet_hits_gen_unarmored",
				append_husk_to_event_name = false
			},
			{
				event = "wwise/events/weapon/play_hit_indicator_death_knife",
				only_1p = true
			},
			{
				event = "wwise/events/weapon/play_psyker_throwing_knife_hit_death",
				only_1p = true
			}
		},
		weakspot_damage = {
			{
				event = "wwise/events/weapon/play_bullet_hits_gen_unarmored",
				append_husk_to_event_name = false
			},
			{
				event = "wwise/events/weapon/play_psyker_throwing_knife_hit",
				only_1p = true
			}
		},
		damage = {
			{
				event = "wwise/events/weapon/play_bullet_hits_gen_unarmored",
				append_husk_to_event_name = false
			},
			{
				event = "wwise/events/weapon/play_psyker_throwing_knife_hit",
				only_1p = true
			}
		},
		damage_reduced = {
			{
				event = "wwise/events/weapon/play_bullet_hits_gen_unarmored",
				append_husk_to_event_name = false
			},
			{
				event = "wwise/events/weapon/play_psyker_throwing_knife_hit",
				only_1p = true
			}
		},
		damage_negated = {
			{
				event = "wwise/events/weapon/play_bullet_hits_gen_damage_negated",
				append_husk_to_event_name = false
			}
		},
		dead = {
			{
				event = "wwise/events/weapon/play_bullet_hits_gen_unarmored",
				append_husk_to_event_name = false
			}
		}
	},
	vfx = {
		weakspot_died = {
			{
				effects = {
					"content/fx/particles/impacts/flesh/blood_splatter_weakspot_ranged_01"
				}
			},
			{
				effects = {
					"content/fx/particles/impacts/abilities/gunslinger_knife_impact"
				}
			},
			{
				effects = {
					"content/fx/particles/impacts/generic_dust_unarmored"
				}
			}
		},
		died = {
			{
				effects = {
					"content/fx/particles/impacts/flesh/blood_splatter_01"
				}
			},
			{
				effects = {
					"content/fx/particles/impacts/abilities/gunslinger_knife_impact"
				}
			},
			{
				effects = {
					"content/fx/particles/impacts/generic_dust_unarmored"
				}
			}
		},
		weakspot_damage = {
			{
				effects = {
					"content/fx/particles/impacts/flesh/blood_splatter_weakspot_ranged_01"
				}
			},
			{
				effects = {
					"content/fx/particles/impacts/abilities/gunslinger_knife_impact"
				}
			},
			{
				effects = {
					"content/fx/particles/impacts/generic_dust_unarmored"
				}
			}
		},
		damage = {
			{
				effects = {
					"content/fx/particles/impacts/flesh/blood_splatter_small_01"
				}
			},
			{
				effects = {
					"content/fx/particles/impacts/abilities/gunslinger_knife_impact"
				}
			},
			{
				effects = {
					"content/fx/particles/impacts/generic_dust_unarmored"
				}
			}
		},
		damage_reduced = {
			{
				effects = {
					"content/fx/particles/impacts/abilities/gunslinger_knife_impact"
				}
			},
			{
				effects = {
					"content/fx/particles/impacts/generic_dust_unarmored"
				}
			}
		},
		damage_negated = {
			{
				effects = {
					"content/fx/particles/impacts/armor_ricochet"
				}
			}
		},
		dead = {
			{
				effects = {
					"content/fx/particles/impacts/flesh/blood_splatter_reduced_damage_01"
				}
			}
		}
	},
	linked_decal = {
		weakspot_died = default_armor_decal,
		died = default_armor_decal,
		weakspot_damage = default_armor_decal,
		damage = default_armor_decal,
		damage_reduced = default_armor_decal
	},
	blood_ball = {
		weakspot_died = blood_ball,
		died = blood_ball,
		weakspot_damage = blood_ball,
		damage = blood_ball
	}
}
local armored = {
	sfx = {
		weakspot_died = {
			{
				event = "wwise/events/weapon/play_bullet_hits_gen_unarmored",
				append_husk_to_event_name = false
			},
			{
				event = "wwise/events/weapon/play_psyker_throwing_knife_hit_death",
				only_1p = true
			},
			{
				event = "wwise/events/weapon/play_hit_indicator_death_knife",
				only_1p = true
			}
		},
		died = {
			{
				event = "wwise/events/weapon/play_bullet_hits_gen_unarmored",
				append_husk_to_event_name = false
			},
			{
				event = "wwise/events/weapon/play_psyker_throwing_knife_hit_death",
				only_1p = true
			},
			{
				event = "wwise/events/weapon/play_psyker_throwing_knife_hit",
				only_1p = true
			}
		},
		weakspot_damage = {
			{
				event = "wwise/events/weapon/play_bullet_hits_gen_unarmored",
				append_husk_to_event_name = false
			},
			{
				event = "wwise/events/weapon/play_psyker_throwing_knife_hit",
				only_1p = true
			}
		},
		damage = {
			{
				event = "wwise/events/weapon/play_bullet_hits_gen_armored",
				append_husk_to_event_name = false
			},
			{
				event = "wwise/events/weapon/play_psyker_throwing_knife_hit",
				only_1p = true
			}
		},
		damage_reduced = {
			{
				event = "wwise/events/weapon/play_bullet_hits_gen_armored",
				append_husk_to_event_name = false
			},
			{
				event = "wwise/events/weapon/play_psyker_throwing_knife_hit",
				only_1p = true
			}
		},
		damage_negated = {
			{
				event = "wwise/events/weapon/play_bullet_hits_gen_damage_negated",
				append_husk_to_event_name = false
			},
			{
				event = "wwise/events/weapon/play_psyker_throwing_knife_hit_negate",
				only_1p = true
			}
		},
		shield_blocked = {
			{
				event = "wwise/events/weapon/play_bullet_hits_gen_damage_negated",
				append_husk_to_event_name = false
			},
			{
				event = "wwise/events/weapon/play_psyker_throwing_knife_hit_negate",
				only_1p = true
			}
		},
		blocked = {
			{
				event = "wwise/events/weapon/play_bullet_hits_gen_damage_negated",
				append_husk_to_event_name = false
			},
			{
				event = "wwise/events/weapon/play_psyker_throwing_knife_hit_negate",
				only_1p = true
			}
		},
		dead = {
			{
				event = "wwise/events/weapon/play_bullet_hits_gen_unarmored",
				append_husk_to_event_name = false
			}
		}
	},
	vfx = {
		weakspot_died = {
			{
				effects = {
					"content/fx/particles/impacts/flesh/blood_splatter_weakspot_01"
				}
			},
			{
				effects = {
					"content/fx/particles/weapons/rifles/autogun/autogun_impact_armored"
				}
			}
		},
		died = {
			{
				effects = {
					"content/fx/particles/impacts/flesh/blood_splatter_01"
				}
			},
			{
				effects = {
					"content/fx/particles/weapons/rifles/autogun/autogun_impact_armored"
				}
			}
		},
		weakspot_damage = {
			{
				effects = {
					"content/fx/particles/impacts/flesh/blood_splatter_weakspot_01"
				}
			},
			{
				effects = {
					"content/fx/particles/weapons/rifles/autogun/autogun_impact_armored"
				}
			}
		},
		damage = {
			{
				effects = {
					"content/fx/particles/impacts/flesh/blood_splatter_small_01"
				}
			},
			{
				effects = {
					"content/fx/particles/weapons/rifles/autogun/autogun_impact_armored"
				}
			}
		},
		damage_reduced = {
			{
				effects = {
					"content/fx/particles/impacts/flesh/blood_splatter_reduced_damage_01"
				}
			},
			{
				effects = {
					"content/fx/particles/weapons/rifles/autogun/autogun_impact_armored"
				}
			}
		},
		damage_negated = {
			{
				effects = {
					"content/fx/particles/impacts/armor_ricochet"
				}
			}
		},
		dead = {
			{
				effects = {
					"content/fx/particles/impacts/flesh/blood_splatter_reduced_damage_01"
				}
			}
		}
	},
	linked_decal = {
		weakspot_died = default_armor_decal,
		died = default_armor_decal,
		weakspot_damage = default_armor_decal,
		damage = default_armor_decal,
		damage_reduced = default_armor_decal
	},
	blood_ball = {
		weakspot_died = blood_ball,
		died = blood_ball
	}
}
local super_armor = table.clone(armored)
local disgustingly_resilient = {
	sfx = {
		weakspot_died = {
			{
				event = "wwise/events/weapon/play_bullet_hits_gen_unarmored",
				append_husk_to_event_name = false
			},
			{
				event = "wwise/events/weapon/play_psyker_throwing_knife_hit_death",
				only_1p = true
			},
			{
				event = "wwise/events/weapon/play_hit_indicator_death_knife",
				only_1p = true
			}
		},
		died = {
			{
				event = "wwise/events/weapon/play_bullet_hits_gen_unarmored",
				append_husk_to_event_name = false
			},
			{
				event = "wwise/events/weapon/play_hit_indicator_death_knife",
				only_1p = true
			},
			{
				event = "wwise/events/weapon/play_psyker_throwing_knife_hit_death",
				only_1p = true
			}
		},
		weakspot_damage = {
			{
				event = "wwise/events/weapon/play_bullet_hits_gen_unarmored",
				append_husk_to_event_name = false
			},
			{
				event = "wwise/events/weapon/play_psyker_throwing_knife_hit",
				only_1p = true
			}
		},
		damage = {
			{
				event = "wwise/events/weapon/play_bullet_hits_gen_unarmored",
				append_husk_to_event_name = false
			},
			{
				event = "wwise/events/weapon/play_psyker_throwing_knife_hit",
				only_1p = true
			}
		},
		damage_reduced = {
			{
				event = "wwise/events/weapon/play_bullet_hits_gen_unarmored",
				append_husk_to_event_name = false
			},
			{
				event = "wwise/events/weapon/play_psyker_throwing_knife_hit",
				only_1p = true
			}
		},
		damage_negated = {
			{
				event = "wwise/events/weapon/play_bullet_hits_gen_damage_negated",
				append_husk_to_event_name = false
			},
			{
				event = "wwise/events/weapon/play_psyker_throwing_knife_hit_negate",
				only_1p = true
			}
		},
		dead = {
			{
				event = "wwise/events/weapon/play_bullet_hits_gen_unarmored",
				append_husk_to_event_name = false
			}
		}
	},
	vfx = {
		weakspot_died = {
			{
				effects = {
					"content/fx/particles/impacts/flesh/blood_splatter_weakspot_ranged_01"
				}
			},
			{
				effects = {
					"content/fx/particles/impacts/abilities/gunslinger_knife_impact"
				}
			}
		},
		died = {
			{
				effects = {
					"content/fx/particles/impacts/flesh/poxwalker_blood_splatter_01"
				}
			},
			{
				effects = {
					"content/fx/particles/impacts/abilities/gunslinger_knife_impact"
				}
			}
		},
		weakspot_damage = {
			{
				effects = {
					"content/fx/particles/impacts/flesh/blood_splatter_weakspot_ranged_01"
				}
			},
			{
				effects = {
					"content/fx/particles/impacts/abilities/gunslinger_knife_impact"
				}
			}
		},
		damage = {
			{
				effects = {
					"content/fx/particles/impacts/flesh/poxwalker_blood_splatter_small_01"
				}
			},
			{
				effects = {
					"content/fx/particles/impacts/abilities/gunslinger_knife_impact"
				}
			}
		},
		damage_negated = {
			{
				effects = {
					"content/fx/particles/impacts/armor_ricochet"
				}
			}
		},
		dead = {
			{
				effects = {
					"content/fx/particles/impacts/flesh/poxwalker_blood_splatter_small_01"
				}
			}
		}
	},
	linked_decal = {
		weakspot_died = default_armor_decal,
		died = default_armor_decal,
		weakspot_damage = default_armor_decal,
		damage = default_armor_decal,
		damage_reduced = default_armor_decal
	},
	blood_ball = {
		weakspot_died = disgusting_blood_ball,
		died = disgusting_blood_ball
	}
}
local resistant = table.clone(unarmored)
local berserker = table.clone(unarmored)
local prop_armor = table.clone(armored)
local player = {
	sfx = {
		weakspot_died = {
			{
				event = "wwise/events/weapon/play_bullet_hits_gen_unarmored",
				append_husk_to_event_name = false
			}
		},
		died = {
			{
				event = "wwise/events/weapon/play_bullet_hits_gen_unarmored",
				append_husk_to_event_name = false
			}
		},
		weakspot_damage = {
			{
				event = "wwise/events/weapon/play_bullet_hits_gen_unarmored",
				append_husk_to_event_name = false
			}
		},
		damage = {
			{
				event = "wwise/events/weapon/play_bullet_hits_gen_unarmored",
				append_husk_to_event_name = false
			}
		},
		damage_reduced = {
			{
				event = "wwise/events/weapon/play_bullet_hits_gen_unarmored",
				append_husk_to_event_name = false
			}
		},
		damage_negated = {
			{
				event = "wwise/events/weapon/play_bullet_hits_gen_damage_negated",
				append_husk_to_event_name = true
			}
		}
	},
	vfx = {
		damage = {
			{
				effects = {
					"content/fx/particles/impacts/flesh/blood_splatter_01"
				}
			},
			{
				effects = {
					"content/fx/particles/impacts/abilities/gunslinger_knife_impact"
				}
			}
		},
		damage_negated = {
			{
				effects = {
					"content/fx/particles/impacts/surfaces/impact_super_armor"
				}
			}
		}
	},
	linked_decal = {},
	blood_ball = {}
}
local default_surface_decal = {
	Vector3(0.2, 0.2, 0.2),
	Vector3(0.2, 0.2, 0.2),
	{
		"content/fx/units/decal_cross_01"
	}
}
local default_surface_fx = {
	sfx = {
		{
			group = "surface_material",
			append_husk_to_event_name = false,
			event = "wwise/events/weapon/play_bullet_hits_sharp_object",
			normal_rotation = true
		}
	},
	vfx = {
		{
			normal_rotation = true,
			effects = {
				"content/fx/particles/impacts/weapons/autogun/autogun_impact_wall"
			}
		}
	}
}
local surface_decal = {}

ImpactFxHelper.create_missing_surface_decals(surface_decal)

return {
	armor = {
		[armor_types.armored] = armored,
		[armor_types.berserker] = berserker,
		[armor_types.disgustingly_resilient] = disgustingly_resilient,
		[armor_types.player] = player,
		[armor_types.resistant] = resistant,
		[armor_types.super_armor] = super_armor,
		[armor_types.unarmored] = unarmored,
		[armor_types.prop_armor] = prop_armor
	},
	surface = {
		[hit_types.stop] = default_surface_fx,
		[hit_types.penetration_entry] = default_surface_fx,
		[hit_types.penetration_exit] = nil
	},
	surface_decal = surface_decal
}