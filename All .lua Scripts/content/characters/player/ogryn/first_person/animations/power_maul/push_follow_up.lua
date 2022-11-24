local spline_matrices = {
	[0] = {
		0.576668,
		-0.591498,
		-0.563546,
		0,
		0.219618,
		-0.552167,
		0.804288,
		0,
		-0.786907,
		-0.587572,
		-0.188513,
		0,
		-0.859025,
		0.657308,
		-0.530887,
		1
	},
	[0.0333333333333] = {
		0.620037,
		-0.5126,
		-0.593966,
		0,
		0.354571,
		-0.492259,
		0.794959,
		0,
		-0.699881,
		-0.703507,
		-0.123465,
		0,
		-0.835988,
		0.614432,
		-0.554191,
		1
	},
	[0.0666666666667] = {
		0.648797,
		-0.428433,
		-0.628895,
		0,
		0.478765,
		-0.412558,
		0.774971,
		0,
		-0.591478,
		-0.803891,
		-0.062548,
		0,
		-0.788683,
		0.55147,
		-0.608388,
		1
	},
	[0.133333333333] = {
		0.63327,
		-0.409157,
		-0.656932,
		0,
		0.540597,
		-0.373566,
		0.753793,
		0,
		-0.553827,
		-0.83249,
		-0.015379,
		0,
		-0.804781,
		0.453164,
		-0.606252,
		1
	},
	[0.166666666667] = {
		0.591451,
		-0.479405,
		-0.648349,
		0,
		0.481421,
		-0.43508,
		0.760881,
		0,
		-0.646853,
		-0.762153,
		-0.026533,
		0,
		-0.904454,
		0.422258,
		-0.54242,
		1
	},
	[0.1] = {
		0.653944,
		-0.381881,
		-0.653088,
		0,
		0.54804,
		-0.35599,
		0.756917,
		0,
		-0.521545,
		-0.8529,
		-0.023512,
		0,
		-0.760313,
		0.493133,
		-0.63567,
		1
	},
	[0.233333333333] = {
		0.553233,
		-0.553177,
		-0.622839,
		0,
		0.416589,
		-0.46375,
		0.781914,
		0,
		-0.721378,
		-0.692049,
		-0.026114,
		0,
		-1.043797,
		0.33516,
		-0.391929,
		1
	},
	[0.266666666667] = {
		0.671405,
		-0.422199,
		-0.609068,
		0,
		0.542847,
		-0.279315,
		0.792023,
		0,
		-0.504513,
		-0.862399,
		0.041656,
		0,
		-1.021368,
		0.223251,
		-0.324394,
		1
	},
	[0.2] = {
		0.551233,
		-0.540782,
		-0.635371,
		0,
		0.418777,
		-0.47932,
		0.771284,
		0,
		-0.721642,
		-0.691236,
		-0.037749,
		0,
		-1.001437,
		0.38771,
		-0.464286,
		1
	},
	[0.333333333333] = {
		0.757119,
		-0.185948,
		-0.626254,
		0,
		0.646444,
		0.074965,
		0.759269,
		0,
		-0.094238,
		-0.979696,
		0.176962,
		0,
		-0.846916,
		0.070015,
		-0.189841,
		1
	},
	[0.366666666667] = {
		0.512165,
		-0.571915,
		-0.640781,
		0,
		0.530664,
		-0.375912,
		0.759662,
		0,
		-0.675339,
		-0.729111,
		0.110966,
		0,
		-0.697665,
		0.518158,
		-0.151695,
		1
	},
	[0.3] = {
		0.762435,
		-0.20197,
		-0.614737,
		0,
		0.628805,
		0.007163,
		0.77753,
		0,
		-0.152635,
		-0.979365,
		0.132461,
		0,
		-0.943487,
		0.104885,
		-0.252163,
		1
	},
	[0.433333333333] = {
		-0.734799,
		-0.479997,
		-0.479243,
		0,
		-0.337069,
		-0.354728,
		0.872096,
		0,
		-0.588604,
		0.802354,
		0.098862,
		0,
		-0.011109,
		1.442701,
		-0.123589,
		1
	},
	[0.466666666667] = {
		-0.916094,
		-0.099954,
		-0.388304,
		0,
		-0.37381,
		-0.137408,
		0.91727,
		0,
		-0.145041,
		0.985458,
		0.088515,
		0,
		0.404874,
		1.477194,
		-0.133841,
		1
	},
	[0.4] = {
		-0.102202,
		-0.751258,
		-0.652047,
		0,
		0.01957,
		-0.656871,
		0.753749,
		0,
		-0.994571,
		0.064274,
		0.081836,
		0,
		-0.393615,
		1.19343,
		-0.116953,
		1
	},
	[0.533333333333] = {
		-0.642189,
		0.682639,
		-0.348707,
		0,
		-0.377416,
		0.11437,
		0.918954,
		0,
		0.667196,
		0.72175,
		0.184192,
		0,
		1.22228,
		0.894033,
		-0.233286,
		1
	},
	[0.566666666667] = {
		-0.567055,
		0.785568,
		-0.247652,
		0,
		-0.267369,
		0.108834,
		0.957428,
		0,
		0.779078,
		0.609129,
		0.148321,
		0,
		1.415739,
		0.54142,
		-0.41675,
		1
	},
	[0.5] = {
		-0.866047,
		0.34441,
		-0.362414,
		0,
		-0.37634,
		0.028125,
		0.926055,
		0,
		0.329136,
		0.938398,
		0.105258,
		0,
		0.925285,
		1.225858,
		-0.165703,
		1
	},
	[0.633333333333] = {
		-0.593072,
		0.804225,
		0.038568,
		0,
		0.06407,
		-0.00061,
		0.997945,
		0,
		0.802596,
		0.594325,
		-0.051164,
		0,
		1.459425,
		0.18786,
		-0.738218,
		1
	},
	[0.666666666667] = {
		-0.612433,
		0.759177,
		0.220401,
		0,
		0.269556,
		-0.061546,
		0.961016,
		0,
		0.743146,
		0.647968,
		-0.166948,
		0,
		1.32915,
		0.110331,
		-0.885622,
		1
	},
	[0.6] = {
		-0.573708,
		0.810901,
		-0.115317,
		0,
		-0.114186,
		0.060233,
		0.991632,
		0,
		0.811061,
		0.582075,
		0.058038,
		0,
		1.512893,
		0.292156,
		-0.59677,
		1
	},
	[0.733333333333] = {
		-0.555341,
		0.579793,
		0.596185,
		0,
		0.669287,
		-0.113916,
		0.734219,
		0,
		0.49361,
		0.806761,
		-0.324786,
		0,
		0.972138,
		0.02464,
		-1.130584,
		1
	},
	[0.766666666667] = {
		-0.462499,
		0.476825,
		0.747484,
		0,
		0.817721,
		-0.096443,
		0.567478,
		0,
		0.342677,
		0.873692,
		-0.345305,
		0,
		0.819932,
		0.008928,
		-1.199841,
		1
	},
	[0.7] = {
		-0.60508,
		0.68011,
		0.413919,
		0,
		0.480057,
		-0.103095,
		0.871158,
		0,
		0.635156,
		0.725825,
		-0.264111,
		0,
		1.154685,
		0.057216,
		-1.021676,
		1
	},
	[0.833333333333] = {
		-0.33571,
		0.389189,
		0.857806,
		0,
		0.918883,
		-0.065055,
		0.389129,
		0,
		0.207249,
		0.918858,
		-0.33578,
		0,
		0.736331,
		0.006734,
		-1.220022,
		1
	},
	[0.866666666667] = {
		-0.334712,
		0.390048,
		0.857806,
		0,
		0.918714,
		-0.067409,
		0.389129,
		0,
		0.209603,
		0.918324,
		-0.33578,
		0,
		0.736346,
		0.004848,
		-1.220022,
		1
	},
	[0.8] = {
		-0.336786,
		0.388258,
		0.857806,
		0,
		0.91906,
		-0.062511,
		0.389129,
		0,
		0.204705,
		0.919428,
		-0.33578,
		0,
		0.736309,
		0.008772,
		-1.220022,
		1
	},
	[0.933333333333] = {
		-0.333319,
		0.391239,
		0.857806,
		0,
		0.918467,
		-0.070685,
		0.389129,
		0,
		0.212877,
		0.91757,
		-0.33578,
		0,
		0.736358,
		0.002221,
		-1.220022,
		1
	},
	[0.966666666667] = {
		-0.33311,
		0.391417,
		0.857806,
		0,
		0.918429,
		-0.071176,
		0.389129,
		0,
		0.213367,
		0.917456,
		-0.33578,
		0,
		0.736359,
		0.001828,
		-1.220022,
		1
	},
	[0.9] = {
		-0.333884,
		0.390757,
		0.857806,
		0,
		0.918568,
		-0.069358,
		0.389129,
		0,
		0.211551,
		0.917877,
		-0.33578,
		0,
		0.736354,
		0.003285,
		-1.220022,
		1
	}
}

return spline_matrices