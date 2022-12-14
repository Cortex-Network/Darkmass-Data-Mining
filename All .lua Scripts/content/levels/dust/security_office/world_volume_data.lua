local volume_data = {
	{
		height = 16,
		type = "content/volume_types/nav_tag_volumes/no_spawn",
		name = "volume",
		alt_max_vector = {
			-9.5,
			-20.5,
			-50
		},
		alt_min_vector = {
			-9.5,
			-20.5,
			-66
		},
		bottom_points = {
			{
				-98,
				-71,
				-66
			},
			{
				1,
				-35,
				-66
			},
			{
				13,
				-13.67989730834961,
				-66
			},
			{
				9,
				8.5,
				-66
			},
			{
				-32.5,
				24.5,
				-66
			},
			{
				-63,
				-4.500000953674316,
				-66
			}
		},
		color = {
			255,
			120,
			120,
			255
		},
		up_vector = {
			0,
			0,
			1
		}
	},
	{
		height = 2,
		type = "content/volume_types/player_instakill",
		name = "volume_001",
		alt_max_vector = {
			20,
			-4.5448222160339355,
			-67.25
		},
		alt_min_vector = {
			20,
			-4.5448222160339355,
			-69.25
		},
		bottom_points = {
			{
				15.45094108581543,
				-19.583126068115234,
				-69.25
			},
			{
				24.54905891418457,
				-19.583126068115234,
				-69.25
			},
			{
				24.54905891418457,
				10.49348258972168,
				-69.25
			},
			{
				15.45094108581543,
				10.49348258972168,
				-69.25
			}
		},
		color = {
			255,
			255,
			64,
			0
		},
		up_vector = {
			0,
			0,
			1
		}
	},
	{
		height = 2,
		type = "content/volume_types/player_mover_blocker",
		name = "volume_blocker_shaft",
		alt_max_vector = {
			42.999996185302734,
			-17.809711456298828,
			-55.83715057373047
		},
		alt_min_vector = {
			42.999996185302734,
			-17.809711456298828,
			-59.95600128173828
		},
		bottom_points = {
			{
				39.80744934082031,
				-18.287214279174805,
				-59.95600128173828
			},
			{
				46.192543029785156,
				-18.287214279174805,
				-59.95600128173828
			},
			{
				46.192543029785156,
				-17.33220863342285,
				-59.95600128173828
			},
			{
				39.80744934082031,
				-17.33220863342285,
				-59.95600128173828
			}
		},
		color = {
			255,
			255,
			125,
			0
		},
		up_vector = {
			0,
			0,
			2.059425115585327
		}
	},
	{
		height = 2,
		type = "content/volume_types/player_mover_blocker",
		name = "volume_003",
		alt_max_vector = {
			15.086780548095703,
			-6.9462127685546875,
			-47.13969802856445
		},
		alt_min_vector = {
			15.086780548095703,
			-6.9462127685546875,
			-52.02941131591797
		},
		bottom_points = {
			{
				16.086780548095703,
				-17.49689483642578,
				-52.02941131591797
			},
			{
				16.086780548095703,
				3.6044692993164062,
				-52.02941131591797
			},
			{
				14.086780548095703,
				3.6044692993164062,
				-52.02941131591797
			},
			{
				14.086780548095703,
				-17.49689483642578,
				-52.02941131591797
			}
		},
		color = {
			255,
			255,
			125,
			0
		},
		up_vector = {
			-0,
			[2.0] = 0,
			[3.0] = 2.444856882095337
		}
	},
	{
		height = 2,
		type = "content/volume_types/player_mover_blocker",
		name = "volume_002",
		alt_max_vector = {
			18.94248390197754,
			2,
			-46.52838897705078
		},
		alt_min_vector = {
			18.94248390197754,
			2,
			-55.5
		},
		bottom_points = {
			{
				15.813796043395996,
				1,
				-55.5
			},
			{
				22.0711727142334,
				1,
				-55.5
			},
			{
				22.0711727142334,
				3,
				-55.5
			},
			{
				15.813796043395996,
				3,
				-55.5
			}
		},
		color = {
			255,
			255,
			125,
			0
		},
		up_vector = {
			0,
			0,
			4.485805988311768
		}
	},
	{
		height = 2,
		type = "core/gwnav/volumes/gwnavexclusivetagvolume",
		name = "volume_nav_blocker_security_001",
		alt_max_vector = {
			27.537694931030273,
			-47.615997314453125,
			-48.25
		},
		alt_min_vector = {
			27.537694931030273,
			-47.615997314453125,
			-50.25
		},
		bottom_points = {
			{
				26.537694931030273,
				-48.615997314453125,
				-50.25
			},
			{
				28.537694931030273,
				-48.615997314453125,
				-50.25
			},
			{
				28.537694931030273,
				-46.615997314453125,
				-50.25
			},
			{
				26.537694931030273,
				-46.615997314453125,
				-50.25
			}
		},
		color = {
			255,
			255,
			0,
			0
		},
		up_vector = {
			0,
			0,
			1
		}
	}
}

return {
	volume_data = volume_data
}
