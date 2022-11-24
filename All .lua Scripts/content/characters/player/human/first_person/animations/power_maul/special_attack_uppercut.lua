local spline_matrices = {
	[0] = {
		-0.008096,
		-0.981679,
		-0.190372,
		0,
		0.948135,
		0.052962,
		-0.313426,
		0,
		0.317766,
		-0.183036,
		0.930335,
		0,
		0.350101,
		0.416703,
		-0.254439,
		1
	},
	{
		0.768168,
		0.274165,
		0.578577,
		0,
		0.089814,
		0.848597,
		-0.521361,
		0,
		-0.633917,
		0.452457,
		0.627241,
		0,
		-0.158776,
		0.068623,
		-0.268473,
		1
	},
	[0.0166666666667] = {
		-0.036861,
		-0.983186,
		-0.178847,
		0,
		0.975722,
		0.003254,
		-0.218988,
		0,
		0.215888,
		-0.182577,
		0.959197,
		0,
		0.349875,
		0.425855,
		-0.264193,
		1
	},
	[0.0333333333333] = {
		-0.064291,
		-0.984283,
		-0.164481,
		0,
		0.991127,
		-0.043766,
		-0.125503,
		0,
		0.116332,
		-0.17109,
		0.978363,
		0,
		0.349202,
		0.434953,
		-0.275971,
		1
	},
	[0.05] = {
		-0.09802,
		-0.982398,
		-0.159019,
		0,
		0.995156,
		-0.095546,
		-0.023146,
		0,
		0.007545,
		-0.160517,
		0.987004,
		0,
		0.3481,
		0.443246,
		-0.286658,
		1
	},
	[0.0666666666667] = {
		-0.139936,
		-0.974272,
		-0.176671,
		0,
		0.982464,
		-0.158825,
		0.097673,
		0,
		-0.123219,
		-0.159904,
		0.979412,
		0,
		0.346619,
		0.450056,
		-0.293103,
		1
	},
	[0.0833333333333] = {
		-0.182677,
		-0.955007,
		-0.233648,
		0,
		0.938617,
		-0.240133,
		0.247658,
		0,
		-0.292622,
		-0.174064,
		0.940252,
		0,
		0.356408,
		0.451906,
		-0.281607,
		1
	},
	[0.116666666667] = {
		-0.217859,
		-0.882998,
		-0.415754,
		0,
		0.725316,
		-0.431511,
		0.536391,
		0,
		-0.653035,
		-0.184695,
		0.734461,
		0,
		0.381429,
		0.466727,
		-0.209956,
		1
	},
	[0.133333333333] = {
		-0.219944,
		-0.842479,
		-0.491786,
		0,
		0.589994,
		-0.516359,
		0.62071,
		0,
		-0.776873,
		-0.153629,
		0.610628,
		0,
		0.384474,
		0.479674,
		-0.176049,
		1
	},
	[0.15] = {
		-0.264175,
		-0.803101,
		-0.534079,
		0,
		0.483994,
		-0.589366,
		0.646836,
		0,
		-0.834243,
		-0.087613,
		0.544392,
		0,
		0.378892,
		0.48748,
		-0.160558,
		1
	},
	[0.166666666667] = {
		-0.353159,
		-0.766734,
		-0.536096,
		0,
		0.421564,
		-0.641965,
		0.640441,
		0,
		-0.835202,
		0.000179,
		0.549943,
		0,
		0.372817,
		0.493557,
		-0.163288,
		1
	},
	[0.183333333333] = {
		-0.462681,
		-0.739036,
		-0.489645,
		0,
		0.412073,
		-0.66831,
		0.61932,
		0,
		-0.784935,
		0.084778,
		0.613751,
		0,
		0.36791,
		0.499694,
		-0.174144,
		1
	},
	[0.1] = {
		-0.212032,
		-0.92312,
		-0.320768,
		0,
		0.851528,
		-0.335572,
		0.402855,
		0,
		-0.479524,
		-0.187725,
		0.857214,
		0,
		0.371557,
		0.454643,
		-0.249447,
		1
	},
	[0.216666666667] = {
		-0.595421,
		-0.750055,
		-0.287909,
		0,
		0.511592,
		-0.630278,
		0.583972,
		0,
		-0.619474,
		0.200417,
		0.759003,
		0,
		0.370874,
		0.521652,
		-0.21254,
		1
	},
	[0.233333333333] = {
		-0.603415,
		-0.784473,
		-0.143152,
		0,
		0.610627,
		-0.570012,
		0.549747,
		0,
		-0.51286,
		0.244313,
		0.822974,
		0,
		0.376789,
		0.536646,
		-0.236632,
		1
	},
	[0.25] = {
		-0.570769,
		-0.82021,
		0.03844,
		0,
		0.743484,
		-0.496374,
		0.448157,
		0,
		-0.348502,
		0.284374,
		0.893128,
		0,
		0.371994,
		0.548413,
		-0.26116,
		1
	},
	[0.266666666667] = {
		-0.479363,
		-0.84844,
		0.224412,
		0,
		0.861892,
		-0.406935,
		0.302567,
		0,
		-0.165389,
		0.338458,
		0.926333,
		0,
		0.362818,
		0.560083,
		-0.284697,
		1
	},
	[0.283333333333] = {
		-0.368711,
		-0.858679,
		0.355982,
		0,
		0.928838,
		-0.325418,
		0.177097,
		0,
		-0.036226,
		0.395947,
		0.917559,
		0,
		0.353352,
		0.569522,
		-0.305804,
		1
	},
	[0.2] = {
		-0.553137,
		-0.728628,
		-0.403908,
		0,
		0.445594,
		-0.668408,
		0.595547,
		0,
		-0.703907,
		0.14944,
		0.694393,
		0,
		0.365054,
		0.507576,
		-0.191017,
		1
	},
	[0.316666666667] = {
		-0.339315,
		-0.890153,
		0.304125,
		0,
		0.928558,
		-0.265236,
		0.259673,
		0,
		-0.150484,
		0.370509,
		0.916557,
		0,
		0.354101,
		0.575678,
		-0.338628,
		1
	},
	[0.333333333333] = {
		-0.414579,
		-0.882959,
		0.220243,
		0,
		0.85201,
		-0.291592,
		0.434802,
		0,
		-0.319692,
		0.367909,
		0.873178,
		0,
		0.36117,
		0.566501,
		-0.36063,
		1
	},
	[0.35] = {
		-0.594331,
		-0.745513,
		0.301632,
		0,
		0.676147,
		-0.260137,
		0.689314,
		0,
		-0.435427,
		0.613628,
		0.658683,
		0,
		0.351061,
		0.545107,
		-0.398751,
		1
	},
	[0.366666666667] = {
		-0.750313,
		-0.556069,
		0.357516,
		0,
		0.521755,
		-0.166014,
		0.836786,
		0,
		-0.405958,
		0.814387,
		0.414695,
		0,
		0.337081,
		0.519298,
		-0.434777,
		1
	},
	[0.383333333333] = {
		-0.77322,
		-0.461729,
		0.434669,
		0,
		0.543412,
		-0.129147,
		0.829472,
		0,
		-0.326856,
		0.877569,
		0.350768,
		0,
		0.330547,
		0.491203,
		-0.458453,
		1
	},
	[0.3] = {
		-0.309664,
		-0.862542,
		0.400162,
		0,
		0.950626,
		-0.271779,
		0.149823,
		0,
		-0.020473,
		0.426799,
		0.904115,
		0,
		0.347673,
		0.574629,
		-0.323094,
		1
	},
	[0.416666666667] = {
		-0.606467,
		-0.374125,
		0.70159,
		0,
		0.77962,
		-0.106486,
		0.617134,
		0,
		-0.156175,
		0.921244,
		0.356256,
		0,
		0.326244,
		0.433463,
		-0.49656,
		1
	},
	[0.433333333333] = {
		-0.445694,
		-0.368164,
		0.815973,
		0,
		0.894128,
		-0.138801,
		0.425757,
		0,
		-0.043491,
		0.919342,
		0.391049,
		0,
		0.325341,
		0.406189,
		-0.504677,
		1
	},
	[0.45] = {
		-0.275057,
		-0.383154,
		0.88178,
		0,
		0.956032,
		-0.20604,
		0.208689,
		0,
		0.101721,
		0.900411,
		0.42298,
		0,
		0.323063,
		0.381509,
		-0.50512,
		1
	},
	[0.466666666667] = {
		-0.134075,
		-0.416149,
		0.899358,
		0,
		0.949597,
		-0.313455,
		-0.003477,
		0,
		0.283355,
		0.853561,
		0.4372,
		0,
		0.317335,
		0.360991,
		-0.498879,
		1
	},
	[0.483333333333] = {
		-0.057877,
		-0.459159,
		0.886467,
		0,
		0.863053,
		-0.469325,
		-0.186746,
		0,
		0.501787,
		0.754259,
		0.423442,
		0,
		0.306272,
		0.346172,
		-0.48326,
		1
	},
	[0.4] = {
		-0.722298,
		-0.403646,
		0.561565,
		0,
		0.646329,
		-0.105087,
		0.755788,
		0,
		-0.246058,
		0.90886,
		0.336792,
		0,
		0.327504,
		0.462142,
		-0.480098,
		1
	},
	[0.516666666667] = {
		-0.334574,
		-0.380059,
		0.862331,
		0,
		0.028391,
		-0.918717,
		-0.393894,
		0,
		0.941942,
		-0.107304,
		0.31817,
		0,
		0.200739,
		0.341334,
		-0.35058,
		1
	},
	[0.533333333333] = {
		-0.445715,
		-0.139244,
		0.884279,
		0,
		-0.590868,
		-0.696308,
		-0.407468,
		0,
		0.672468,
		-0.704107,
		0.22808,
		0,
		0.105408,
		0.357529,
		-0.261885,
		1
	},
	[0.55] = {
		-0.351261,
		-0.11882,
		0.928707,
		0,
		-0.733952,
		-0.580918,
		-0.351923,
		0,
		0.581318,
		-0.805243,
		0.116845,
		0,
		0.08186,
		0.382878,
		-0.259733,
		1
	},
	[0.566666666667] = {
		-0.205617,
		-0.17837,
		0.96224,
		0,
		-0.746627,
		-0.607061,
		-0.272075,
		0,
		0.632669,
		-0.774378,
		-0.008354,
		0,
		0.076778,
		0.411217,
		-0.258004,
		1
	},
	[0.583333333333] = {
		-0.04312,
		-0.313402,
		0.948641,
		0,
		-0.67825,
		-0.688003,
		-0.258124,
		0,
		0.733565,
		-0.654546,
		-0.182898,
		0,
		0.075154,
		0.440331,
		-0.256573,
		1
	},
	[0.5] = {
		-0.077282,
		-0.488357,
		0.869215,
		0,
		0.662655,
		-0.676552,
		-0.321195,
		0,
		0.744927,
		0.551167,
		0.375897,
		0,
		0.28807,
		0.338634,
		-0.455573,
		1
	},
	[0.616666666667] = {
		0.330101,
		-0.905981,
		0.265012,
		0,
		-0.468033,
		-0.400899,
		-0.787543,
		0,
		0.819743,
		0.135935,
		-0.556367,
		0,
		0.015308,
		0.497037,
		-0.187063,
		1
	},
	[0.633333333333] = {
		0.53279,
		-0.735048,
		-0.419331,
		0,
		-0.475558,
		0.149811,
		-0.866834,
		0,
		0.699986,
		0.661257,
		-0.26974,
		0,
		-0.04152,
		0.510389,
		-0.070265,
		1
	},
	[0.65] = {
		0.534372,
		-0.49823,
		-0.682798,
		0,
		-0.587473,
		0.361874,
		-0.723824,
		0,
		0.607718,
		0.787917,
		-0.099321,
		0,
		-0.073068,
		0.473133,
		0.047502,
		1
	},
	[0.666666666667] = {
		0.474512,
		-0.322553,
		-0.819022,
		0,
		-0.669566,
		0.471742,
		-0.573708,
		0,
		0.571419,
		0.820621,
		0.007877,
		0,
		-0.079784,
		0.414664,
		0.128917,
		1
	},
	[0.683333333333] = {
		0.444189,
		-0.143194,
		-0.884416,
		0,
		-0.701843,
		0.557957,
		-0.442832,
		0,
		0.556877,
		0.817422,
		0.147338,
		0,
		-0.079104,
		0.362374,
		0.148134,
		1
	},
	[0.6] = {
		0.114261,
		-0.551317,
		0.826434,
		0,
		-0.586486,
		-0.708884,
		-0.391813,
		0,
		0.801859,
		-0.439923,
		-0.404338,
		0,
		0.061888,
		0.468203,
		-0.25581,
		1
	},
	[0.716666666667] = {
		0.417954,
		0.20941,
		-0.884003,
		0,
		-0.735962,
		0.648533,
		-0.194331,
		0,
		0.53261,
		0.731814,
		0.425175,
		0,
		-0.08377,
		0.245489,
		0.170715,
		1
	},
	[0.733333333333] = {
		0.429714,
		0.363344,
		-0.826636,
		0,
		-0.742517,
		0.663126,
		-0.094513,
		0,
		0.513823,
		0.654405,
		0.554743,
		0,
		-0.089228,
		0.188002,
		0.177752,
		1
	},
	[0.75] = {
		0.459837,
		0.48587,
		-0.743291,
		0,
		-0.747997,
		0.663054,
		-0.029327,
		0,
		0.478592,
		0.569465,
		0.668326,
		0,
		-0.09969,
		0.13757,
		0.181381,
		1
	},
	[0.766666666667] = {
		0.507019,
		0.573097,
		-0.643811,
		0,
		-0.753476,
		0.657425,
		-0.008167,
		0,
		0.418577,
		0.489236,
		0.765141,
		0,
		-0.117311,
		0.098445,
		0.182765,
		1
	},
	[0.783333333333] = {
		0.581225,
		0.622613,
		-0.523957,
		0,
		-0.749983,
		0.659712,
		-0.048026,
		0,
		0.315759,
		0.420873,
		0.85039,
		0,
		-0.151192,
		0.070616,
		0.166972,
		1
	},
	[0.7] = {
		0.423962,
		0.036975,
		-0.904925,
		0,
		-0.724214,
		0.613826,
		-0.314218,
		0,
		0.543848,
		0.788575,
		0.287016,
		0,
		-0.081155,
		0.304909,
		0.160851,
		1
	},
	[0.816666666667] = {
		0.75206,
		0.62827,
		-0.199206,
		0,
		-0.658786,
		0.707298,
		-0.25638,
		0,
		-0.020177,
		0.324047,
		0.945826,
		0,
		-0.258477,
		0.036138,
		0.067887,
		1
	},
	[0.833333333333] = {
		0.797787,
		0.602642,
		-0.01894,
		0,
		-0.566866,
		0.738982,
		-0.364101,
		0,
		-0.205426,
		0.301211,
		0.931167,
		0,
		-0.311671,
		0.026942,
		0.004894,
		1
	},
	[0.85] = {
		0.806947,
		0.574441,
		0.137307,
		0,
		-0.469674,
		0.765074,
		-0.440532,
		0,
		-0.35811,
		0.290997,
		0.887174,
		0,
		-0.350812,
		0.02145,
		-0.053394,
		1
	},
	[0.866666666667] = {
		0.794925,
		0.555699,
		0.243502,
		0,
		-0.400321,
		0.781995,
		-0.477731,
		0,
		-0.455892,
		0.282281,
		0.844085,
		0,
		-0.365499,
		0.018382,
		-0.096635,
		1
	},
	[0.883333333333] = {
		0.782435,
		0.555589,
		0.281276,
		0,
		-0.384048,
		0.786068,
		-0.484359,
		0,
		-0.490206,
		0.270956,
		0.828421,
		0,
		-0.363669,
		0.016835,
		-0.121263,
		1
	},
	[0.8] = {
		0.67277,
		0.638412,
		-0.373913,
		0,
		-0.721535,
		0.677916,
		-0.140774,
		0,
		0.163609,
		0.3645,
		0.916718,
		0,
		-0.201631,
		0.050278,
		0.125242,
		1
	},
	[0.916666666667] = {
		0.779224,
		0.580042,
		0.237404,
		0,
		-0.432532,
		0.771815,
		-0.466066,
		0,
		-0.45357,
		0.260485,
		0.852304,
		0,
		-0.346836,
		0.019215,
		-0.144465,
		1
	},
	[0.933333333333] = {
		0.78568,
		0.578806,
		0.218381,
		0,
		-0.439831,
		0.770875,
		-0.46076,
		0,
		-0.435036,
		0.265959,
		0.860238,
		0,
		-0.326363,
		0.023741,
		-0.156251,
		1
	},
	[0.95] = {
		0.798564,
		0.550735,
		0.242872,
		0,
		-0.397904,
		0.785781,
		-0.47352,
		0,
		-0.451628,
		0.281496,
		0.846635,
		0,
		-0.294237,
		0.03091,
		-0.176977,
		1
	},
	[0.966666666667] = {
		0.812062,
		0.487345,
		0.321013,
		0,
		-0.290614,
		0.814742,
		-0.501737,
		0,
		-0.506062,
		0.314151,
		0.80325,
		0,
		-0.253031,
		0.040972,
		-0.205534,
		1
	},
	[0.983333333333] = {
		0.80954,
		0.392837,
		0.436262,
		0,
		-0.125569,
		0.841793,
		-0.524993,
		0,
		-0.573479,
		0.370222,
		0.730793,
		0,
		-0.207622,
		0.053674,
		-0.236155,
		1
	},
	[0.9] = {
		0.777966,
		0.568069,
		0.268454,
		0,
		-0.404725,
		0.779897,
		-0.47745,
		0,
		-0.480591,
		0.26279,
		0.836645,
		0,
		-0.358362,
		0.01701,
		-0.135006,
		1
	},
	[1.01666666667] = {
		0.669594,
		0.146652,
		0.728105,
		0,
		0.332626,
		0.817299,
		-0.470513,
		0,
		-0.664082,
		0.557239,
		0.498478,
		0,
		-0.107261,
		0.085424,
		-0.302121,
		1
	},
	[1.03333333333] = {
		0.51152,
		0.03181,
		0.858683,
		0,
		0.565854,
		0.73957,
		-0.364478,
		0,
		-0.64665,
		0.672327,
		0.360305,
		0,
		-0.053868,
		0.103664,
		-0.33673,
		1
	},
	[1.05] = {
		0.312,
		-0.051645,
		0.948677,
		0,
		0.752932,
		0.622421,
		-0.213739,
		0,
		-0.579438,
		0.780977,
		0.233081,
		0,
		0.000602,
		0.12297,
		-0.371935,
		1
	},
	[1.06666666667] = {
		0.099977,
		-0.096022,
		0.990346,
		0,
		0.87414,
		0.483912,
		-0.041327,
		0,
		-0.475272,
		0.869833,
		0.132317,
		0,
		0.055369,
		0.142987,
		-0.407373,
		1
	},
	[1.08333333333] = {
		-0.09939,
		-0.104912,
		0.989502,
		0,
		0.930333,
		0.342971,
		0.12981,
		0,
		-0.35299,
		0.933469,
		0.063515,
		0,
		0.109662,
		0.163339,
		-0.442682,
		1
	},
	[1.11666666667] = {
		-0.416396,
		-0.052852,
		0.907646,
		0,
		0.902555,
		0.096302,
		0.419668,
		0,
		-0.109588,
		0.993948,
		0.007602,
		0,
		0.213789,
		0.203431,
		-0.511469,
		1
	},
	[1.13333333333] = {
		-0.41496,
		-0.057482,
		0.908022,
		0,
		0.902914,
		0.096889,
		0.418759,
		0,
		-0.112048,
		0.993634,
		0.011696,
		0,
		0.212548,
		0.205986,
		-0.510963,
		1
	},
	[1.15] = {
		-0.413508,
		-0.062235,
		0.908371,
		0,
		0.903243,
		0.097676,
		0.417866,
		0,
		-0.114731,
		0.993271,
		0.015823,
		0,
		0.211259,
		0.208601,
		-0.510436,
		1
	},
	[1.16666666667] = {
		-0.412051,
		-0.067063,
		0.908689,
		0,
		0.903541,
		0.098634,
		0.416996,
		0,
		-0.117593,
		0.992861,
		0.019951,
		0,
		0.209937,
		0.211251,
		-0.509892,
		1
	},
	[1.18333333333] = {
		-0.410601,
		-0.071919,
		0.908975,
		0,
		0.903806,
		0.099737,
		0.416157,
		0,
		-0.120588,
		0.992411,
		0.024049,
		0,
		0.208594,
		0.213909,
		-0.509335,
		1
	},
	[1.1] = {
		-0.272504,
		-0.087504,
		0.958167,
		0,
		0.934702,
		0.212115,
		0.285201,
		0,
		-0.228198,
		0.973319,
		0.023988,
		0,
		0.162719,
		0.183629,
		-0.4775,
		1
	},
	[1.21666666667] = {
		-0.407763,
		-0.08153,
		0.909441,
		0,
		0.90424,
		0.102264,
		0.414599,
		0,
		-0.126805,
		0.991411,
		0.032024,
		0,
		0.205905,
		0.219149,
		-0.5082,
		1
	},
	[1.23333333333] = {
		-0.406399,
		-0.086191,
		0.909621,
		0,
		0.904409,
		0.10363,
		0.41389,
		0,
		-0.129938,
		0.990874,
		0.035836,
		0,
		0.204588,
		0.221681,
		-0.507633,
		1
	},
	[1.25] = {
		-0.405087,
		-0.090691,
		0.909769,
		0,
		0.904549,
		0.105028,
		0.413232,
		0,
		-0.133028,
		0.990325,
		0.039489,
		0,
		0.203307,
		0.22412,
		-0.507076,
		1
	},
	[1.26666666667] = {
		-0.40384,
		-0.094986,
		0.909885,
		0,
		0.90466,
		0.106428,
		0.412631,
		0,
		-0.136032,
		0.989773,
		0.04295,
		0,
		0.202078,
		0.226443,
		-0.506536,
		1
	},
	[1.28333333333] = {
		-0.402669,
		-0.099026,
		0.909973,
		0,
		0.904745,
		0.107802,
		0.412087,
		0,
		-0.138905,
		0.989228,
		0.046185,
		0,
		0.200915,
		0.228624,
		-0.506018,
		1
	},
	[1.2] = {
		-0.409167,
		-0.076758,
		0.909225,
		0,
		0.904039,
		0.100956,
		0.415356,
		0,
		-0.123674,
		0.991925,
		0.028084,
		0,
		0.207245,
		0.21655,
		-0.508769,
		1
	},
	[1.31666666667] = {
		-0.40061,
		-0.106159,
		0.910078,
		0,
		0.904849,
		0.110357,
		0.411181,
		0,
		-0.144084,
		0.988206,
		0.051848,
		0,
		0.198848,
		0.232463,
		-0.505085,
		1
	},
	[1.33333333333] = {
		-0.399746,
		-0.109158,
		0.910103,
		0,
		0.904875,
		0.11148,
		0.410821,
		0,
		-0.146303,
		0.987753,
		0.054211,
		0,
		0.197973,
		0.234072,
		-0.504685,
		1
	},
	[1.3] = {
		-0.401589,
		-0.102766,
		0.910036,
		0,
		0.904807,
		0.109121,
		0.411603,
		0,
		-0.141603,
		0.988702,
		0.049162,
		0,
		0.199834,
		0.230638,
		-0.505532,
		1
	}
}

return spline_matrices