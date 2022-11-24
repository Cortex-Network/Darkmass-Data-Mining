local spline_matrices = {
	[0] = {
		0.972015,
		-0.233887,
		0.021986,
		0,
		0.050738,
		0.117633,
		-0.99176,
		0,
		0.229374,
		0.965121,
		0.126208,
		0,
		0.807086,
		-0.047223,
		-1.370142,
		1
	},
	{
		0.972015,
		-0.233887,
		0.021986,
		0,
		0.050738,
		0.117633,
		-0.99176,
		0,
		0.229374,
		0.965121,
		0.126208,
		0,
		0.300182,
		-0.346942,
		-1.11897,
		1
	},
	[0.0166666666667] = {
		0.970121,
		-0.228722,
		-0.080939,
		0,
		0.013102,
		0.382503,
		-0.923861,
		0,
		0.242267,
		0.895197,
		0.374071,
		0,
		0.803473,
		-0.024331,
		-1.252043,
		1
	},
	[0.0333333333333] = {
		0.963932,
		-0.195533,
		-0.180563,
		0,
		-0.02085,
		0.620862,
		-0.783643,
		0,
		0.265332,
		0.759143,
		0.594391,
		0,
		0.802584,
		-0.027114,
		-1.028511,
		1
	},
	[0.05] = {
		0.955212,
		-0.159989,
		-0.248944,
		0,
		-0.043069,
		0.757131,
		-0.651842,
		0,
		0.29277,
		0.633369,
		0.71633,
		0,
		0.804548,
		-0.058808,
		-0.702604,
		1
	},
	[0.0666666666667] = {
		0.942996,
		-0.08095,
		-0.322808,
		0,
		-0.059886,
		0.91286,
		-0.403857,
		0,
		0.327371,
		0.400167,
		0.855976,
		0,
		0.806476,
		-0.083274,
		-0.350948,
		1
	},
	[0.0833333333333] = {
		0.929991,
		0.017207,
		-0.367179,
		0,
		-0.074161,
		0.987146,
		-0.141573,
		0,
		0.360023,
		0.158892,
		0.919313,
		0,
		0.805988,
		-0.109333,
		-0.073865,
		1
	},
	[0.116666666667] = {
		0.905673,
		0.162675,
		-0.391527,
		0,
		-0.075971,
		0.970783,
		0.227615,
		0,
		0.417115,
		-0.1764,
		0.891571,
		0,
		0.796112,
		0.06027,
		0.392156,
		1
	},
	[0.133333333333] = {
		0.893524,
		0.222388,
		-0.390076,
		0,
		-0.060878,
		0.920713,
		0.385462,
		0,
		0.44487,
		-0.320672,
		0.836218,
		0,
		0.783043,
		0.250172,
		0.588947,
		1
	},
	[0.15] = {
		0.880016,
		0.281289,
		-0.382686,
		0,
		-0.048592,
		0.854845,
		0.516604,
		0,
		0.472452,
		-0.436024,
		0.765945,
		0,
		0.758759,
		0.4568,
		0.745044,
		1
	},
	[0.166666666667] = {
		0.86785,
		0.327598,
		-0.373517,
		0,
		-0.035956,
		0.791251,
		0.610433,
		0,
		0.495523,
		-0.516334,
		0.698467,
		0,
		0.722473,
		0.639775,
		0.848359,
		1
	},
	[0.183333333333] = {
		0.849353,
		0.335982,
		-0.407082,
		0,
		-0.04991,
		0.818911,
		0.571747,
		0,
		0.52546,
		-0.465297,
		0.712313,
		0,
		0.667083,
		0.83756,
		0.8237,
		1
	},
	[0.1] = {
		0.91891,
		0.073758,
		-0.38751,
		0,
		-0.063911,
		0.997222,
		0.038257,
		0,
		0.389256,
		-0.010389,
		0.921071,
		0,
		0.806518,
		-0.051325,
		0.164499,
		1
	},
	[0.216666666667] = {
		0.792144,
		0.289524,
		-0.537294,
		0,
		-0.125622,
		0.93882,
		0.320681,
		0,
		0.597267,
		-0.18653,
		0.780051,
		0,
		0.451344,
		1.285515,
		0.497628,
		1
	},
	[0.233333333333] = {
		0.769512,
		0.20308,
		-0.605483,
		0,
		-0.209887,
		0.975849,
		0.060555,
		0,
		0.603157,
		0.080485,
		0.793551,
		0,
		0.286858,
		1.403209,
		0.285689,
		1
	},
	[0.25] = {
		0.831546,
		0.128982,
		-0.540272,
		0,
		-0.332525,
		0.894709,
		-0.298199,
		0,
		0.444924,
		0.42762,
		0.786882,
		0,
		0.08755,
		1.434035,
		0.023522,
		1
	},
	[0.266666666667] = {
		0.848165,
		0.042894,
		-0.527993,
		0,
		-0.388189,
		0.728535,
		-0.564399,
		0,
		0.360452,
		0.683664,
		0.634569,
		0,
		-0.121097,
		1.436981,
		-0.262062,
		1
	},
	[0.283333333333] = {
		0.830292,
		-0.030731,
		-0.556481,
		0,
		-0.477028,
		0.47714,
		-0.738093,
		0,
		0.288202,
		0.87829,
		0.381506,
		0,
		-0.31541,
		1.392669,
		-0.519251,
		1
	},
	[0.2] = {
		0.818694,
		0.324621,
		-0.473669,
		0,
		-0.076568,
		0.879222,
		0.470219,
		0,
		0.569103,
		-0.348698,
		0.744669,
		0,
		0.587649,
		1.071076,
		0.683687,
		1
	},
	[0.316666666667] = {
		0.743297,
		0.184726,
		-0.642951,
		0,
		-0.50976,
		-0.465972,
		-0.723197,
		0,
		-0.433191,
		0.865301,
		-0.25219,
		0,
		-0.453664,
		0.444573,
		-1.030881,
		1
	},
	[0.333333333333] = {
		0.651026,
		0.307995,
		-0.69376,
		0,
		-0.505447,
		-0.505972,
		-0.698939,
		0,
		-0.566293,
		0.805687,
		-0.173726,
		0,
		-0.372282,
		0.19645,
		-1.232824,
		1
	},
	[0.35] = {
		0.518651,
		0.37336,
		-0.769158,
		0,
		-0.392627,
		-0.69514,
		-0.602183,
		0,
		-0.759503,
		0.614315,
		-0.213944,
		0,
		-0.262019,
		-0.024122,
		-1.36041,
		1
	},
	[0.366666666667] = {
		0.511609,
		0.408609,
		-0.755841,
		0,
		-0.330912,
		-0.718124,
		-0.612205,
		0,
		-0.79294,
		0.563326,
		-0.232184,
		0,
		-0.174053,
		-0.150343,
		-1.407699,
		1
	},
	[0.383333333333] = {
		0.649488,
		0.403817,
		-0.64428,
		0,
		-0.356842,
		-0.586344,
		-0.72723,
		0,
		-0.671438,
		0.702234,
		-0.236725,
		0,
		-0.093636,
		-0.245718,
		-1.37468,
		1
	},
	[0.3] = {
		0.805622,
		0.092476,
		-0.585168,
		0,
		-0.590264,
		0.040904,
		-0.806173,
		0,
		-0.050616,
		0.994874,
		0.087539,
		0,
		-0.47421,
		0.942533,
		-0.824571,
		1
	},
	[0.416666666667] = {
		0.96865,
		0.104746,
		-0.225269,
		0,
		-0.207653,
		-0.156387,
		-0.965621,
		0,
		-0.136374,
		0.982126,
		-0.129734,
		0,
		0.133609,
		-0.342479,
		-1.253703,
		1
	},
	[0.433333333333] = {
		0.991248,
		-0.121964,
		-0.050526,
		0,
		-0.047393,
		0.028459,
		-0.998471,
		0,
		0.123215,
		0.992126,
		0.02243,
		0,
		0.233262,
		-0.328213,
		-1.179136,
		1
	},
	[0.45] = {
		0.956799,
		-0.285222,
		0.056433,
		0,
		0.10049,
		0.142267,
		-0.984714,
		0,
		0.272833,
		0.947844,
		0.164782,
		0,
		0.293544,
		-0.318158,
		-1.128895,
		1
	},
	[0.466666666667] = {
		0.932676,
		-0.350152,
		0.086657,
		0,
		0.165918,
		0.203123,
		-0.964993,
		0,
		0.320292,
		0.914404,
		0.247545,
		0,
		0.317313,
		-0.313065,
		-1.12551,
		1
	},
	[0.483333333333] = {
		0.905167,
		-0.411588,
		0.106151,
		0,
		0.209047,
		0.21362,
		-0.954288,
		0,
		0.370097,
		0.885981,
		0.279403,
		0,
		0.330387,
		-0.312065,
		-1.123699,
		1
	},
	[0.4] = {
		0.833413,
		0.306863,
		-0.459628,
		0,
		-0.33494,
		-0.381073,
		-0.861742,
		0,
		-0.439589,
		0.872134,
		-0.21481,
		0,
		0.010677,
		-0.310585,
		-1.320707,
		1
	},
	[0.516666666667] = {
		0.888891,
		-0.447146,
		0.099665,
		0,
		0.218042,
		0.221605,
		-0.950447,
		0,
		0.402902,
		0.866575,
		0.29448,
		0,
		0.329233,
		-0.306538,
		-1.121655,
		1
	},
	[0.533333333333] = {
		0.889546,
		-0.447122,
		0.093753,
		0,
		0.210947,
		0.219972,
		-0.952425,
		0,
		0.405227,
		0.867003,
		0.289994,
		0,
		0.326789,
		-0.30612,
		-1.121433,
		1
	},
	[0.55] = {
		0.893689,
		-0.440006,
		0.087835,
		0,
		0.200351,
		0.216177,
		-0.955577,
		0,
		0.401471,
		0.871586,
		0.28135,
		0,
		0.324746,
		-0.30771,
		-1.121515,
		1
	},
	[0.566666666667] = {
		0.900558,
		-0.426977,
		0.081769,
		0,
		0.186891,
		0.210414,
		-0.959582,
		0,
		0.392515,
		0.879441,
		0.269288,
		0,
		0.32192,
		-0.31002,
		-1.121792,
		1
	},
	[0.583333333333] = {
		0.90933,
		-0.409189,
		0.075392,
		0,
		0.171225,
		0.202871,
		-0.964119,
		0,
		0.379212,
		0.889611,
		0.25454,
		0,
		0.3185,
		-0.312955,
		-1.122181,
		1
	},
	[0.5] = {
		0.892343,
		-0.438822,
		0.105636,
		0,
		0.221045,
		0.22082,
		-0.949936,
		0,
		0.393526,
		0.871019,
		0.294047,
		0,
		0.332195,
		-0.308979,
		-1.122255,
		1
	},
	[0.616666666667] = {
		0.929375,
		-0.364028,
		0.061198,
		0,
		0.135943,
		0.183392,
		-0.973595,
		0,
		0.343192,
		0.913154,
		0.219927,
		0,
		0.310651,
		-0.32027,
		-1.122986,
		1
	},
	[0.633333333333] = {
		0.939239,
		-0.339102,
		0.053288,
		0,
		0.117627,
		0.172109,
		-0.97803,
		0,
		0.322481,
		0.924872,
		0.201539,
		0,
		0.30659,
		-0.324386,
		-1.12328,
		1
	},
	[0.65] = {
		0.948256,
		-0.314315,
		0.044915,
		0,
		0.099672,
		0.160374,
		-0.982011,
		0,
		0.301458,
		0.935674,
		0.183404,
		0,
		0.302663,
		-0.328597,
		-1.123444,
		1
	},
	[0.666666666667] = {
		0.956043,
		-0.290977,
		0.036241,
		0,
		0.082621,
		0.148727,
		-0.985421,
		0,
		0.281345,
		0.945099,
		0.16623,
		0,
		0.299013,
		-0.332717,
		-1.123458,
		1
	},
	[0.683333333333] = {
		0.962353,
		-0.270408,
		0.027509,
		0,
		0.066961,
		0.137779,
		-0.988197,
		0,
		0.263427,
		0.952836,
		0.150698,
		0,
		0.295768,
		-0.336541,
		-1.123317,
		1
	},
	[0.6] = {
		0.919188,
		-0.387806,
		0.068563,
		0,
		0.154021,
		0.193769,
		-0.968881,
		0,
		0.362452,
		0.901144,
		0.23784,
		0,
		0.314681,
		-0.316412,
		-1.122602,
		1
	},
	[0.716666666667] = {
		0.967478,
		-0.25222,
		0.019289,
		0,
		0.052926,
		0.127268,
		-0.990455,
		0,
		0.247357,
		0.959264,
		0.136478,
		0,
		0.29365,
		-0.340498,
		-1.122677,
		1
	},
	[0.733333333333] = {
		0.96791,
		-0.250537,
		0.019561,
		0,
		0.052725,
		0.126356,
		-0.990583,
		0,
		0.245706,
		0.959826,
		0.135511,
		0,
		0.294256,
		-0.341129,
		-1.122327,
		1
	},
	[0.75] = {
		0.968331,
		-0.248881,
		0.019823,
		0,
		0.052528,
		0.125462,
		-0.990707,
		0,
		0.244081,
		0.960374,
		0.134562,
		0,
		0.29485,
		-0.341744,
		-1.121983,
		1
	},
	[0.766666666667] = {
		0.96874,
		-0.247263,
		0.020075,
		0,
		0.052335,
		0.124595,
		-0.990826,
		0,
		0.242493,
		0.960904,
		0.133641,
		0,
		0.29543,
		-0.342336,
		-1.12165,
		1
	},
	[0.783333333333] = {
		0.969135,
		-0.245691,
		0.020316,
		0,
		0.052147,
		0.123758,
		-0.990941,
		0,
		0.240951,
		0.961415,
		0.132751,
		0,
		0.295992,
		-0.342904,
		-1.121328,
		1
	},
	[0.7] = {
		0.967038,
		-0.25392,
		0.019011,
		0,
		0.053128,
		0.128191,
		-0.990325,
		0,
		0.249027,
		0.958693,
		0.137455,
		0,
		0.293037,
		-0.339857,
		-1.123031,
		1
	},
	[0.816666666667] = {
		0.969873,
		-0.242727,
		0.020757,
		0,
		0.051794,
		0.122194,
		-0.991154,
		0,
		0.238043,
		0.962368,
		0.131084,
		0,
		0.29705,
		-0.343956,
		-1.120727,
		1
	},
	[0.833333333333] = {
		0.970211,
		-0.241353,
		0.020957,
		0,
		0.05163,
		0.121475,
		-0.991251,
		0,
		0.236695,
		0.962805,
		0.130317,
		0,
		0.297539,
		-0.344435,
		-1.12045,
		1
	},
	[0.85] = {
		0.970527,
		-0.240064,
		0.021141,
		0,
		0.051476,
		0.120804,
		-0.991341,
		0,
		0.235431,
		0.963211,
		0.129601,
		0,
		0.297997,
		-0.344879,
		-1.120191,
		1
	},
	[0.866666666667] = {
		0.970818,
		-0.23887,
		0.021309,
		0,
		0.051333,
		0.120184,
		-0.991424,
		0,
		0.234261,
		0.963585,
		0.128939,
		0,
		0.29842,
		-0.345287,
		-1.119953,
		1
	},
	[0.883333333333] = {
		0.971082,
		-0.237781,
		0.021461,
		0,
		0.051203,
		0.119622,
		-0.991498,
		0,
		0.233192,
		0.963925,
		0.128338,
		0,
		0.298806,
		-0.345655,
		-1.119736,
		1
	},
	[0.8] = {
		0.969513,
		-0.244176,
		0.020543,
		0,
		0.051967,
		0.122957,
		-0.991051,
		0,
		0.239465,
		0.961904,
		0.131897,
		0,
		0.296533,
		-0.343445,
		-1.12102,
		1
	},
	[0.916666666667] = {
		0.971522,
		-0.235954,
		0.021711,
		0,
		0.050985,
		0.118684,
		-0.991622,
		0,
		0.2314,
		0.964489,
		0.127334,
		0,
		0.299453,
		-0.346266,
		-1.119375,
		1
	},
	[0.933333333333] = {
		0.971694,
		-0.235235,
		0.021807,
		0,
		0.050899,
		0.118317,
		-0.99167,
		0,
		0.230696,
		0.96471,
		0.126942,
		0,
		0.299706,
		-0.346503,
		-1.119234,
		1
	},
	[0.95] = {
		0.971831,
		-0.23466,
		0.021884,
		0,
		0.05083,
		0.118025,
		-0.991709,
		0,
		0.230132,
		0.964886,
		0.126628,
		0,
		0.299909,
		-0.346691,
		-1.119121,
		1
	},
	[0.966666666667] = {
		0.971932,
		-0.234237,
		0.02194,
		0,
		0.05078,
		0.11781,
		-0.991737,
		0,
		0.229717,
		0.965015,
		0.126398,
		0,
		0.300059,
		-0.346829,
		-1.119038,
		1
	},
	[0.983333333333] = {
		0.971994,
		-0.233976,
		0.021975,
		0,
		0.050749,
		0.117678,
		-0.991754,
		0,
		0.229461,
		0.965094,
		0.126257,
		0,
		0.30015,
		-0.346914,
		-1.118987,
		1
	},
	[0.9] = {
		0.971317,
		-0.236805,
		0.021595,
		0,
		0.051087,
		0.11912,
		-0.991565,
		0,
		0.232236,
		0.964227,
		0.127801,
		0,
		0.299151,
		-0.345982,
		-1.119543,
		1
	}
}

return spline_matrices