local spline_matrices = {
	[0] = {
		0.242047,
		0.032618,
		0.969716,
		0,
		-0.00104,
		0.999443,
		-0.033358,
		0,
		-0.970264,
		0.007066,
		0.241946,
		0,
		0.866551,
		-0.126506,
		-0.407546,
		1
	},
	{
		0.947778,
		0.034969,
		0.317009,
		0,
		0.317128,
		0.002243,
		-0.94838,
		0,
		-0.033875,
		0.999386,
		-0.008963,
		0,
		0.570398,
		0.142449,
		-1.020725,
		1
	},
	[0.0333333333333] = {
		0.240182,
		0.035845,
		0.970066,
		0,
		-0.00618,
		0.999354,
		-0.035397,
		0,
		-0.970708,
		0.002507,
		0.240249,
		0,
		0.867914,
		-0.122552,
		-0.411575,
		1
	},
	[0.0666666666667] = {
		0.237869,
		0.039585,
		0.97049,
		0,
		-0.011605,
		0.999214,
		-0.037912,
		0,
		-0.971228,
		-0.002245,
		0.238141,
		0,
		0.869506,
		-0.116899,
		-0.42502,
		1
	},
	[0.133333333333] = {
		0.233207,
		0.046003,
		0.971338,
		0,
		-0.020355,
		0.998892,
		-0.042421,
		0,
		-0.972214,
		-0.009878,
		0.233885,
		0,
		0.872489,
		-0.095743,
		-0.471068,
		1
	},
	[0.166666666667] = {
		0.232517,
		0.046455,
		0.971482,
		0,
		-0.020788,
		0.998868,
		-0.042789,
		0,
		-0.97237,
		-0.010246,
		0.233219,
		0,
		0.872774,
		-0.078674,
		-0.499981,
		1
	},
	[0.1] = {
		0.234934,
		0.044004,
		0.971015,
		0,
		-0.017771,
		0.999002,
		-0.040973,
		0,
		-0.971849,
		-0.00763,
		0.235481,
		0,
		0.87145,
		-0.107557,
		-0.445149,
		1
	},
	[0.233333333333] = {
		0.11828,
		-0.06083,
		0.991115,
		0,
		-0.021232,
		0.997739,
		0.06377,
		0,
		-0.992753,
		-0.028586,
		0.116721,
		0,
		0.774108,
		0.138321,
		-0.425975,
		1
	},
	[0.266666666667] = {
		0.074257,
		-0.199369,
		0.977107,
		0,
		-0.123048,
		0.970493,
		0.207371,
		0,
		-0.989619,
		-0.13563,
		0.047534,
		0,
		0.427399,
		0.767439,
		-0.267685,
		1
	},
	[0.2] = {
		-0.011837,
		0.001946,
		0.999928,
		0,
		0.011446,
		0.999933,
		-0.001811,
		0,
		-0.999864,
		0.011424,
		-0.011859,
		0,
		0.891926,
		-0.051354,
		-0.508457,
		1
	},
	[0.333333333333] = {
		0.094291,
		-0.299067,
		0.949562,
		0,
		-0.197386,
		0.92926,
		0.312273,
		0,
		-0.975781,
		-0.216874,
		0.028589,
		0,
		0.162316,
		1.470371,
		-0.1757,
		1
	},
	[0.366666666667] = {
		0.088876,
		-0.292581,
		0.952102,
		0,
		-0.200706,
		0.931017,
		0.304836,
		0,
		-0.975612,
		-0.218185,
		0.024022,
		0,
		0.15207,
		1.454823,
		-0.181695,
		1
	},
	[0.3] = {
		0.088708,
		-0.309578,
		0.946727,
		0,
		-0.190377,
		0.927682,
		0.321189,
		0,
		-0.977695,
		-0.208727,
		0.023356,
		0,
		0.16028,
		1.184832,
		-0.192014,
		1
	},
	[0.433333333333] = {
		0.074727,
		-0.272742,
		0.959181,
		0,
		-0.205803,
		0.936945,
		0.282453,
		0,
		-0.975736,
		-0.218509,
		0.013884,
		0,
		0.137592,
		1.477109,
		-0.203057,
		1
	},
	[0.466666666667] = {
		0.068888,
		-0.263809,
		0.962112,
		0,
		-0.207649,
		0.939489,
		0.272473,
		0,
		-0.975775,
		-0.218551,
		0.00994,
		0,
		0.130391,
		1.489718,
		-0.212677,
		1
	},
	[0.4] = {
		0.081976,
		-0.282777,
		0.955676,
		0,
		-0.203655,
		0.933918,
		0.293807,
		0,
		-0.975605,
		-0.218713,
		0.01897,
		0,
		0.144097,
		1.461654,
		-0.192149,
		1
	},
	[0.533333333333] = {
		0.063487,
		-0.250458,
		0.966043,
		0,
		-0.213923,
		0.942081,
		0.258304,
		0,
		-0.974785,
		-0.223058,
		0.006231,
		0,
		0.10754,
		1.489772,
		-0.225555,
		1
	},
	[0.566666666667] = {
		0.061203,
		-0.24423,
		0.967784,
		0,
		-0.217948,
		0.942934,
		0.251742,
		0,
		-0.974039,
		-0.226334,
		0.004481,
		0,
		0.094533,
		1.488694,
		-0.231262,
		1
	},
	[0.5] = {
		0.065734,
		-0.256932,
		0.964191,
		0,
		-0.209893,
		0.941102,
		0.265088,
		0,
		-0.975512,
		-0.219802,
		0.007934,
		0,
		0.120553,
		1.490792,
		-0.219491,
		1
	},
	[0.633333333333] = {
		0.065626,
		-0.255754,
		0.964512,
		0,
		-0.237548,
		0.934802,
		0.264039,
		0,
		-0.969157,
		-0.246445,
		0.000593,
		0,
		0.060139,
		1.486145,
		-0.245618,
		1
	},
	[0.666666666667] = {
		0.080553,
		-0.287484,
		0.954392,
		0,
		-0.265026,
		0.916859,
		0.298547,
		0,
		-0.960871,
		-0.276988,
		-0.002335,
		0,
		0.038833,
		1.482896,
		-0.253875,
		1
	},
	[0.6] = {
		0.058917,
		-0.237481,
		0.969604,
		0,
		-0.220716,
		0.944154,
		0.244659,
		0,
		-0.973557,
		-0.228422,
		0.003211,
		0,
		0.083291,
		1.487251,
		-0.237927,
		1
	},
	[0.733333333333] = {
		0.184585,
		-0.34705,
		0.919502,
		0,
		-0.436038,
		0.809543,
		0.39308,
		0,
		-0.880795,
		-0.473494,
		-0.001898,
		0,
		-0.010734,
		1.449977,
		-0.28367,
		1
	},
	[0.766666666667] = {
		0.260079,
		-0.364984,
		0.893949,
		0,
		-0.537844,
		0.71413,
		0.448043,
		0,
		-0.801925,
		-0.597331,
		-0.010574,
		0,
		-0.03201,
		1.404448,
		-0.300598,
		1
	},
	[0.7] = {
		0.11969,
		-0.318849,
		0.940218,
		0,
		-0.333807,
		0.878968,
		0.340571,
		0,
		-0.935012,
		-0.354615,
		-0.00123,
		0,
		0.014564,
		1.471504,
		-0.26749,
		1
	},
	[0.833333333333] = {
		0.376399,
		-0.2263,
		0.898394,
		0,
		-0.594572,
		0.684663,
		0.421569,
		0,
		-0.710499,
		-0.692838,
		0.123155,
		0,
		0.018244,
		1.24203,
		-0.423315,
		1
	},
	[0.866666666667] = {
		0.413233,
		0.003692,
		0.910618,
		0,
		-0.472342,
		0.855818,
		0.210877,
		0,
		-0.778544,
		-0.517264,
		0.355396,
		0,
		0.086282,
		1.151322,
		-0.564823,
		1
	},
	[0.8] = {
		0.31264,
		-0.344358,
		0.885254,
		0,
		-0.618152,
		0.63386,
		0.464876,
		0,
		-0.721211,
		-0.69256,
		-0.014696,
		0,
		-0.03571,
		1.326626,
		-0.33869,
		1
	},
	[0.933333333333] = {
		0.591334,
		0.401135,
		0.699582,
		0,
		0.093739,
		0.827436,
		-0.553681,
		0,
		-0.80096,
		0.392988,
		0.451689,
		0,
		0.268986,
		0.789527,
		-0.876927,
		1
	},
	[0.966666666667] = {
		0.839754,
		0.259715,
		0.476824,
		0,
		0.364409,
		0.381436,
		-0.849537,
		0,
		-0.402515,
		0.887161,
		0.22567,
		0,
		0.420443,
		0.468337,
		-0.976281,
		1
	},
	[0.9] = {
		0.433478,
		0.260795,
		0.862602,
		0,
		-0.28428,
		0.947907,
		-0.143729,
		0,
		-0.85515,
		-0.182917,
		0.485035,
		0,
		0.153947,
		1.014529,
		-0.731423,
		1
	}
}

return spline_matrices