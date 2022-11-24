local spline_matrices = {
	[0] = {
		0.721959,
		0.37755,
		0.579854,
		0,
		-0.438438,
		0.897925,
		-0.038765,
		0,
		-0.535301,
		-0.226244,
		0.813797,
		0,
		0.184834,
		0.276274,
		-0.27229,
		1
	},
	{
		0.996934,
		-0.005431,
		-0.078063,
		0,
		-0.001164,
		0.996449,
		-0.084193,
		0,
		0.078243,
		0.084026,
		0.993387,
		0,
		0.157038,
		0.333862,
		-0.21074,
		1
	},
	[0.0333333333333] = {
		0.677747,
		0.358021,
		0.642246,
		0,
		-0.517826,
		0.852517,
		0.071213,
		0,
		-0.522029,
		-0.380836,
		0.763184,
		0,
		0.16915,
		0.282241,
		-0.2766,
		1
	},
	[0.0666666666667] = {
		0.569934,
		0.29248,
		0.767874,
		0,
		-0.699458,
		0.663091,
		0.266587,
		0,
		-0.431199,
		-0.689033,
		0.582496,
		0,
		0.139993,
		0.299967,
		-0.281715,
		1
	},
	[0.133333333333] = {
		0.362046,
		-0.056198,
		0.930465,
		0,
		-0.930612,
		0.035722,
		0.364261,
		0,
		-0.053709,
		-0.99778,
		-0.039366,
		0,
		0.137275,
		0.360889,
		-0.258904,
		1
	},
	[0.166666666667] = {
		0.293219,
		-0.313106,
		0.90332,
		0,
		-0.919733,
		-0.350312,
		0.177123,
		0,
		0.260985,
		-0.882749,
		-0.390692,
		0,
		0.144039,
		0.423217,
		-0.206407,
		1
	},
	[0.1] = {
		0.454612,
		0.177995,
		0.872723,
		0,
		-0.856561,
		0.356001,
		0.373586,
		0,
		-0.244193,
		-0.917377,
		0.314306,
		0,
		0.123151,
		0.3237,
		-0.279475,
		1
	},
	[0.233333333333] = {
		0.474278,
		-0.391091,
		0.788739,
		0,
		-0.307477,
		-0.913078,
		-0.267854,
		0,
		0.824936,
		-0.115482,
		-0.553304,
		0,
		-0.240396,
		0.432058,
		-0.036611,
		1
	},
	[0.266666666667] = {
		0.619463,
		-0.298004,
		0.726264,
		0,
		0.147929,
		-0.86426,
		-0.480803,
		0,
		0.770962,
		0.405275,
		-0.491294,
		0,
		-0.486587,
		0.302192,
		-0.048046,
		1
	},
	[0.2] = {
		0.462773,
		-0.390215,
		0.795974,
		0,
		-0.539224,
		-0.8366,
		-0.096631,
		0,
		0.703619,
		-0.38449,
		-0.597569,
		0,
		-0.00014,
		0.546608,
		-0.095808,
		1
	},
	[0.333333333333] = {
		0.630303,
		-0.220388,
		0.744411,
		0,
		0.154309,
		-0.904165,
		-0.39834,
		0,
		0.760859,
		0.365944,
		-0.53589,
		0,
		-0.783476,
		0.236972,
		-0.317214,
		1
	},
	[0.366666666667] = {
		0.638876,
		-0.170004,
		0.750291,
		0,
		0.152249,
		-0.928048,
		-0.339921,
		0,
		0.754094,
		0.331399,
		-0.567025,
		0,
		-0.845182,
		0.2218,
		-0.440848,
		1
	},
	[0.3] = {
		0.626507,
		-0.253438,
		0.737061,
		0,
		0.159374,
		-0.884021,
		-0.439439,
		0,
		0.762948,
		0.39278,
		-0.513454,
		0,
		-0.643214,
		0.262798,
		-0.163104,
		1
	},
	[0.433333333333] = {
		0.581102,
		-0.016929,
		0.813655,
		0,
		0.044525,
		-0.997625,
		-0.052555,
		0,
		0.812612,
		0.066768,
		-0.578968,
		0,
		-0.691311,
		0.34256,
		-0.619587,
		1
	},
	[0.466666666667] = {
		0.517756,
		0.069586,
		0.852693,
		0,
		-0.092597,
		-0.986274,
		0.136712,
		0,
		0.850502,
		-0.14974,
		-0.504206,
		0,
		-0.542288,
		0.431011,
		-0.69876,
		1
	},
	[0.4] = {
		0.627198,
		-0.09972,
		0.77245,
		0,
		0.125074,
		-0.966003,
		-0.226262,
		0,
		0.768752,
		0.238524,
		-0.593403,
		0,
		-0.801503,
		0.258887,
		-0.529987,
		1
	},
	[0.533333333333] = {
		0.407671,
		0.234153,
		0.882596,
		0,
		-0.436804,
		-0.798794,
		0.41368,
		0,
		0.801877,
		-0.554167,
		-0.223366,
		0,
		-0.243137,
		0.488059,
		-0.781217,
		1
	},
	[0.566666666667] = {
		0.348961,
		0.324897,
		0.879015,
		0,
		-0.617089,
		-0.626255,
		0.476452,
		0,
		0.705285,
		-0.708694,
		-0.018048,
		0,
		-0.147281,
		0.504875,
		-0.771966,
		1
	},
	[0.5] = {
		0.460059,
		0.150951,
		0.874963,
		0,
		-0.261914,
		-0.918519,
		0.296181,
		0,
		0.848379,
		-0.365426,
		-0.383036,
		0,
		-0.383332,
		0.483099,
		-0.755605,
		1
	},
	[0.633333333333] = {
		0.253766,
		0.491094,
		0.833325,
		0,
		-0.911635,
		-0.16653,
		0.375752,
		0,
		0.323304,
		-0.855041,
		0.405438,
		0,
		-0.027052,
		0.533437,
		-0.668657,
		1
	},
	[0.666666666667] = {
		0.236078,
		0.551099,
		0.800348,
		0,
		-0.970131,
		0.086377,
		0.226682,
		0,
		0.055793,
		-0.829957,
		0.55503,
		0,
		0.023759,
		0.538644,
		-0.590406,
		1
	},
	[0.6] = {
		0.294202,
		0.413401,
		0.86171,
		0,
		-0.784692,
		-0.41024,
		0.464717,
		0,
		0.545623,
		-0.812898,
		0.203699,
		0,
		-0.084746,
		0.521285,
		-0.732113,
		1
	},
	[0.733333333333] = {
		0.571046,
		0.597298,
		0.563153,
		0,
		-0.758616,
		0.646104,
		0.083971,
		0,
		-0.3137,
		-0.475169,
		0.822075,
		0,
		0.089047,
		0.528174,
		-0.448518,
		1
	},
	[0.766666666667] = {
		0.655453,
		0.483036,
		0.580567,
		0,
		-0.562201,
		0.825364,
		-0.05199,
		0,
		-0.504292,
		-0.292318,
		0.812551,
		0,
		0.110884,
		0.525385,
		-0.390092,
		1
	},
	[0.7] = {
		0.393609,
		0.587316,
		0.7072,
		0,
		-0.898916,
		0.406922,
		0.162372,
		0,
		-0.192412,
		-0.699625,
		0.688115,
		0,
		0.062269,
		0.533077,
		-0.515908,
		1
	},
	[0.833333333333] = {
		0.824156,
		0.242681,
		0.511736,
		0,
		-0.12556,
		0.959353,
		-0.252738,
		0,
		-0.55227,
		0.144042,
		0.821127,
		0,
		0.13121,
		0.51685,
		-0.307251,
		1
	},
	[0.866666666667] = {
		0.910314,
		0.167763,
		0.378396,
		0,
		-0.063175,
		0.959783,
		-0.273542,
		0,
		-0.409068,
		0.225104,
		0.884303,
		0,
		0.140548,
		0.502907,
		-0.277818,
		1
	},
	[0.8] = {
		0.732802,
		0.322258,
		0.599292,
		0,
		-0.28737,
		0.944912,
		-0.156718,
		0,
		-0.616782,
		-0.057375,
		0.78504,
		0,
		0.122082,
		0.520408,
		-0.345817,
		1
	},
	[0.933333333333] = {
		0.996235,
		0.046916,
		0.072899,
		0,
		-0.033351,
		0.983601,
		-0.17725,
		0,
		-0.080019,
		0.174152,
		0.981462,
		0,
		0.153896,
		0.430078,
		-0.23836,
		1
	},
	[0.966666666667] = {
		0.999306,
		0.009385,
		-0.036036,
		0,
		-0.013895,
		0.991802,
		-0.127028,
		0,
		0.034549,
		0.12744,
		0.991244,
		0,
		0.156279,
		0.381951,
		-0.223153,
		1
	},
	[0.9] = {
		0.969843,
		0.10148,
		0.221601,
		0,
		-0.049472,
		0.972237,
		-0.228711,
		0,
		-0.238658,
		0.21085,
		0.947937,
		0,
		0.148808,
		0.472391,
		-0.256411,
		1
	},
	[1.03333333333] = {
		0.998262,
		-0.007058,
		-0.058502,
		0,
		0.003686,
		0.998336,
		-0.05755,
		0,
		0.058811,
		0.057234,
		0.996627,
		0,
		0.155602,
		0.291576,
		-0.200798,
		1
	},
	[1.06666666667] = {
		0.999734,
		-0.007957,
		-0.021669,
		0,
		0.006991,
		0.998994,
		-0.044299,
		0,
		0.022,
		0.044136,
		0.998783,
		0,
		0.151258,
		0.252275,
		-0.193582,
		1
	},
	[1.13333333333] = {
		0.999971,
		0.000213,
		-0.007638,
		0,
		-0.000388,
		0.999738,
		-0.022879,
		0,
		0.007632,
		0.022881,
		0.999709,
		0,
		0.138013,
		0.256284,
		-0.184391,
		1
	},
	[1.16666666667] = {
		0.999781,
		0.000276,
		-0.020938,
		0,
		-0.000577,
		0.999897,
		-0.014376,
		0,
		0.020932,
		0.014384,
		0.999677,
		0,
		0.135426,
		0.259508,
		-0.181437,
		1
	},
	[1.1] = {
		0.99999,
		-0.003963,
		-0.001908,
		0,
		0.003898,
		0.999453,
		-0.032834,
		0,
		0.002037,
		0.032826,
		0.999459,
		0,
		0.144474,
		0.25355,
		-0.188394,
		1
	},
	[1.23333333333] = {
		0.998752,
		-0.000657,
		-0.049938,
		0,
		0.000553,
		0.999998,
		-0.00211,
		0,
		0.049939,
		0.002079,
		0.99875,
		0,
		0.137087,
		0.267267,
		-0.178188,
		1
	},
	[1.26666666667] = {
		0.998455,
		-0.00138,
		-0.05554,
		0,
		0.001488,
		0.999997,
		0.001896,
		0,
		0.055538,
		-0.001976,
		0.998455,
		0,
		0.139207,
		0.271017,
		-0.17755,
		1
	},
	[1.2] = {
		0.999325,
		-5.7e-05,
		-0.036724,
		0,
		-0.000219,
		0.999972,
		-0.007492,
		0,
		0.036723,
		0.007495,
		0.999297,
		0,
		0.135706,
		0.263302,
		-0.179427,
		1
	},
	[1.33333333333] = {
		0.998825,
		-0.002583,
		-0.048397,
		0,
		0.002887,
		0.999977,
		0.006215,
		0,
		0.04838,
		-0.006347,
		0.998809,
		0,
		0.143464,
		0.276331,
		-0.177346,
		1
	},
	[1.36666666667] = {
		0.998944,
		-0.002783,
		-0.045862,
		0,
		0.003094,
		0.999973,
		0.006718,
		0,
		0.045842,
		-0.006853,
		0.998925,
		0,
		0.144244,
		0.277137,
		-0.177392,
		1
	},
	[1.3] = {
		0.998588,
		-0.002071,
		-0.053084,
		0,
		0.002321,
		0.999987,
		0.004639,
		0,
		0.053073,
		-0.004756,
		0.998579,
		0,
		0.141565,
		0.274165,
		-0.177335,
		1
	}
}

return spline_matrices