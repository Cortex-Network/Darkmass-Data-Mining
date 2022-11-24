local spline_matrices = {
	[0] = {
		-0.403629,
		0.019807,
		0.914708,
		0,
		0.889756,
		-0.224377,
		0.397477,
		0,
		0.213112,
		0.974301,
		0.072942,
		0,
		0.727642,
		0.0031,
		-1.311343,
		1
	},
	{
		-0.403629,
		0.019807,
		0.914708,
		0,
		0.889756,
		-0.224377,
		0.397477,
		0,
		0.213112,
		0.974301,
		0.072942,
		0,
		0.727641,
		0.003099,
		-1.311344,
		1
	},
	[0.0333333333333] = {
		-0.330697,
		0.047072,
		0.942562,
		0,
		0.865057,
		-0.384122,
		0.322687,
		0,
		0.377249,
		0.922081,
		0.086308,
		0,
		0.726705,
		0.027994,
		-1.304223,
		1
	},
	[0.0666666666667] = {
		-0.237753,
		0.065086,
		0.969143,
		0,
		0.801465,
		-0.550536,
		0.233591,
		0,
		0.548751,
		0.83227,
		0.078728,
		0,
		0.717262,
		0.084188,
		-1.291482,
		1
	},
	[0.133333333333] = {
		0.014987,
		0.002684,
		0.999884,
		0,
		0.524581,
		-0.851342,
		-0.005577,
		0,
		0.851228,
		0.524604,
		-0.014167,
		0,
		0.67911,
		0.271669,
		-1.248857,
		1
	},
	[0.166666666667] = {
		0.149913,
		-0.107933,
		0.98279,
		0,
		0.306199,
		-0.940084,
		-0.14995,
		0,
		0.94009,
		0.323408,
		-0.107882,
		0,
		0.666062,
		0.393158,
		-1.218532,
		1
	},
	[0.1] = {
		-0.120349,
		0.056386,
		0.991129,
		0,
		0.689973,
		-0.713074,
		0.124348,
		0,
		0.71376,
		0.698817,
		0.046913,
		0,
		0.700667,
		0.166995,
		-1.273096,
		1
	},
	[0.233333333333] = {
		0.309982,
		-0.452084,
		0.83638,
		0,
		-0.243297,
		-0.88814,
		-0.38989,
		0,
		0.919085,
		-0.08263,
		-0.385298,
		0,
		0.809806,
		0.657779,
		-1.146253,
		1
	},
	[0.266666666667] = {
		0.315872,
		-0.620483,
		0.717792,
		0,
		-0.475723,
		-0.758133,
		-0.446007,
		0,
		0.820921,
		-0.200589,
		-0.534651,
		0,
		0.917187,
		0.786751,
		-1.106593,
		1
	},
	[0.2] = {
		0.255307,
		-0.269805,
		0.928452,
		0,
		0.034663,
		-0.957104,
		-0.287662,
		0,
		0.966238,
		0.105625,
		-0.235003,
		0,
		0.715715,
		0.52457,
		-1.183797,
		1
	},
	[0.333333333333] = {
		0.262965,
		-0.847389,
		0.461282,
		0,
		-0.721067,
		-0.490274,
		-0.489586,
		0,
		0.641025,
		-0.203871,
		-0.739949,
		0,
		1.05434,
		1.015316,
		-1.015564,
		1
	},
	[0.366666666667] = {
		0.248063,
		-0.908879,
		0.335266,
		0,
		-0.739208,
		-0.401273,
		-0.54088,
		0,
		0.626128,
		-0.113659,
		-0.771392,
		0,
		0.999062,
		1.108683,
		-0.942605,
		1
	},
	[0.3] = {
		0.291967,
		-0.754012,
		0.588406,
		0,
		-0.635671,
		-0.612651,
		-0.46966,
		0,
		0.714617,
		-0.236908,
		-0.658178,
		0,
		1.008171,
		0.907313,
		-1.063761,
		1
	},
	[0.433333333333] = {
		0.329003,
		-0.937422,
		0.114001,
		0,
		-0.623482,
		-0.306301,
		-0.71934,
		0,
		0.709244,
		0.165587,
		-0.68524,
		0,
		0.622,
		1.386488,
		-0.680847,
		1
	},
	[0.466666666667] = {
		0.515598,
		-0.851575,
		-0.094759,
		0,
		-0.577033,
		-0.263345,
		-0.773099,
		0,
		0.633397,
		0.453287,
		-0.627167,
		0,
		0.435658,
		1.440919,
		-0.485702,
		1
	},
	[0.4] = {
		0.260102,
		-0.937418,
		0.231506,
		0,
		-0.692316,
		-0.348182,
		-0.632034,
		0,
		0.673087,
		0.004118,
		-0.739552,
		0,
		0.822295,
		1.251017,
		-0.828396,
		1
	},
	[0.533333333333] = {
		0.874779,
		-0.212734,
		-0.435322,
		0,
		-0.451403,
		-0.031364,
		-0.891769,
		0,
		0.176057,
		0.976607,
		-0.123465,
		0,
		0.088447,
		1.352492,
		-0.056857,
		1
	},
	[0.566666666667] = {
		0.872441,
		0.299751,
		-0.386001,
		0,
		-0.460529,
		0.239866,
		-0.854621,
		0,
		-0.163585,
		0.923371,
		0.347313,
		0,
		-0.310192,
		1.051666,
		0.253605,
		1
	},
	[0.5] = {
		0.774384,
		-0.535668,
		-0.336734,
		0,
		-0.510522,
		-0.214605,
		-0.832654,
		0,
		0.373761,
		0.816703,
		-0.439657,
		0,
		0.213371,
		1.416247,
		-0.246566,
		1
	},
	[0.633333333333] = {
		0.626977,
		0.778756,
		-0.020943,
		0,
		-0.77433,
		0.625913,
		0.092985,
		0,
		0.085521,
		-0.042083,
		0.995447,
		0,
		-0.534124,
		-0.537747,
		0.394692,
		1
	},
	[0.666666666667] = {
		0.617923,
		0.785422,
		0.035831,
		0,
		-0.786163,
		0.616589,
		0.042019,
		0,
		0.01091,
		-0.054133,
		0.998474,
		0,
		-0.35465,
		-0.672734,
		0.265167,
		1
	},
	[0.6] = {
		0.732775,
		0.615551,
		-0.290066,
		0,
		-0.677615,
		0.621066,
		-0.393846,
		0,
		-0.062282,
		0.485154,
		0.872208,
		0,
		-0.456941,
		0.381624,
		0.411237,
		1
	},
	[0.733333333333] = {
		0.016097,
		0.964994,
		0.261778,
		0,
		-0.985039,
		-0.029622,
		0.169764,
		0,
		0.171576,
		-0.260594,
		0.95008,
		0,
		0.236967,
		-0.568972,
		-0.312409,
		1
	},
	[0.766666666667] = {
		-0.46345,
		0.786334,
		0.408526,
		0,
		-0.801847,
		-0.568376,
		0.184364,
		0,
		0.377168,
		-0.242132,
		0.893933,
		0,
		0.530926,
		-0.429848,
		-0.607859,
		1
	},
	[0.7] = {
		0.409116,
		0.903732,
		0.126067,
		0,
		-0.910856,
		0.396224,
		0.115537,
		0,
		0.054464,
		-0.162097,
		0.985271,
		0,
		-0.07388,
		-0.644782,
		-0.008252,
		1
	},
	[0.833333333333] = {
		-0.766761,
		-0.053154,
		0.639729,
		0,
		0.238244,
		-0.948953,
		0.206706,
		0,
		0.596086,
		0.310905,
		0.740284,
		0,
		0.795624,
		-0.112137,
		-1.034854,
		1
	},
	[0.866666666667] = {
		-0.642903,
		-0.186807,
		0.742818,
		0,
		0.538582,
		-0.799816,
		0.264997,
		0,
		0.544615,
		0.570436,
		0.614815,
		0,
		0.777987,
		-0.044584,
		-1.125385,
		1
	},
	[0.8] = {
		-0.765935,
		0.364671,
		0.529488,
		0,
		-0.315,
		-0.930806,
		0.185403,
		0,
		0.560462,
		-0.024783,
		0.827809,
		0,
		0.728479,
		-0.256058,
		-0.857629,
		1
	},
	[0.933333333333] = {
		-0.493107,
		-0.108843,
		0.863133,
		0,
		0.785893,
		-0.481248,
		0.388293,
		0,
		0.373118,
		0.869801,
		0.322846,
		0,
		0.750521,
		0.007057,
		-1.252374,
		1
	},
	[0.966666666667] = {
		-0.43921,
		-0.046632,
		0.897173,
		0,
		0.855061,
		-0.328077,
		0.401542,
		0,
		0.275617,
		0.943499,
		0.183968,
		0,
		0.73766,
		0.011662,
		-1.292133,
		1
	},
	[0.9] = {
		-0.562787,
		-0.157063,
		0.811543,
		0,
		0.676948,
		-0.650982,
		0.343459,
		0,
		0.474355,
		0.742667,
		0.472688,
		0,
		0.765039,
		-0.011886,
		-1.195228,
		1
	}
}

return spline_matrices