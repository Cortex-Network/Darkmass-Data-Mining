local spline_matrices = {
	[0] = {
		0.997892,
		0.059987,
		-0.024746,
		0,
		-0.059001,
		0.997503,
		0.03881,
		0,
		0.027012,
		-0.037269,
		0.99894,
		0,
		0.500422,
		0.456689,
		-0.328436,
		1
	},
	{
		0.951126,
		0.024845,
		0.307803,
		0,
		0.146531,
		0.841084,
		-0.520679,
		0,
		-0.271824,
		0.540334,
		0.796336,
		0,
		0.858004,
		0.455897,
		-0.56029,
		1
	},
	[0.0166666666667] = {
		0.985536,
		0.1376,
		0.098915,
		0,
		-0.151125,
		0.977731,
		0.145616,
		0,
		-0.076675,
		-0.158458,
		0.984384,
		0,
		0.465369,
		0.467196,
		-0.360428,
		1
	},
	[0.0333333333333] = {
		0.955755,
		0.197003,
		0.218453,
		0,
		-0.247086,
		0.940622,
		0.232764,
		0,
		-0.159626,
		-0.276442,
		0.947681,
		0,
		0.427497,
		0.481569,
		-0.393772,
		1
	},
	[0.05] = {
		0.922474,
		0.232076,
		0.308518,
		0,
		-0.322611,
		0.902337,
		0.285849,
		0,
		-0.212049,
		-0.36322,
		0.907252,
		0,
		0.391395,
		0.513058,
		-0.421704,
		1
	},
	[0.0666666666667] = {
		0.88618,
		0.25718,
		0.385413,
		0,
		-0.391083,
		0.861241,
		0.324527,
		0,
		-0.248471,
		-0.438318,
		0.863794,
		0,
		0.354955,
		0.556244,
		-0.445898,
		1
	},
	[0.0833333333333] = {
		0.828465,
		0.29035,
		0.478898,
		0,
		-0.490346,
		0.789184,
		0.369796,
		0,
		-0.270568,
		-0.541189,
		0.796183,
		0,
		0.308573,
		0.614073,
		-0.468882,
		1
	},
	[0.116666666667] = {
		0.573386,
		0.336154,
		0.747147,
		0,
		-0.799447,
		0.429035,
		0.420493,
		0,
		-0.179202,
		-0.838409,
		0.514739,
		0,
		0.188893,
		0.772787,
		-0.542453,
		1
	},
	[0.133333333333] = {
		0.496699,
		0.322382,
		0.805829,
		0,
		-0.862322,
		0.288617,
		0.416055,
		0,
		-0.098447,
		-0.901537,
		0.421353,
		0,
		0.178083,
		0.81012,
		-0.583763,
		1
	},
	[0.15] = {
		0.449824,
		0.309213,
		0.837882,
		0,
		-0.893005,
		0.170573,
		0.416469,
		0,
		-0.014142,
		-0.93557,
		0.352857,
		0,
		0.18806,
		0.83145,
		-0.624129,
		1
	},
	[0.166666666667] = {
		0.408043,
		0.290483,
		0.865517,
		0,
		-0.911663,
		0.079079,
		0.403258,
		0,
		0.048696,
		-0.953607,
		0.29709,
		0,
		0.186841,
		0.843213,
		-0.645043,
		1
	},
	[0.183333333333] = {
		0.345007,
		0.253002,
		0.903859,
		0,
		-0.935917,
		0.019975,
		0.351652,
		0,
		0.070914,
		-0.96726,
		0.243681,
		0,
		0.14387,
		0.853616,
		-0.62988,
		1
	},
	[0.1] = {
		0.70884,
		0.33261,
		0.622027,
		0,
		-0.659448,
		0.62547,
		0.417032,
		0,
		-0.25035,
		-0.705803,
		0.662697,
		0,
		0.241215,
		0.699108,
		-0.500776,
		1
	},
	[0.216666666667] = {
		0.061854,
		0.107606,
		0.992268,
		0,
		-0.997636,
		0.036474,
		0.058233,
		0,
		-0.029926,
		-0.993524,
		0.109608,
		0,
		-0.163451,
		0.871009,
		-0.417129,
		1
	},
	[0.233333333333] = {
		-0.034744,
		0.064709,
		0.997299,
		0,
		-0.99131,
		0.124451,
		-0.04261,
		0,
		-0.126872,
		-0.990113,
		0.059823,
		0,
		-0.256174,
		0.895769,
		-0.318784,
		1
	},
	[0.25] = {
		-0.033234,
		0.058141,
		0.997755,
		0,
		-0.966038,
		0.254091,
		-0.046984,
		0,
		-0.256252,
		-0.965431,
		0.047722,
		0,
		-0.235874,
		0.941684,
		-0.272619,
		1
	},
	[0.266666666667] = {
		0.026632,
		0.060882,
		0.99779,
		0,
		-0.911284,
		0.411778,
		-0.000802,
		0,
		-0.410916,
		-0.909248,
		0.066447,
		0,
		-0.150067,
		1.002754,
		-0.24757,
		1
	},
	[0.283333333333] = {
		0.122274,
		0.055116,
		0.990965,
		0,
		-0.812831,
		0.578503,
		0.068119,
		0,
		-0.569522,
		-0.813816,
		0.115535,
		0,
		-0.014837,
		1.064458,
		-0.240049,
		1
	},
	[0.2] = {
		0.219211,
		0.183798,
		0.958209,
		0,
		-0.974869,
		0.001281,
		0.222776,
		0,
		0.039718,
		-0.982963,
		0.179459,
		0,
		0.008724,
		0.860886,
		-0.54512,
		1
	},
	[0.316666666667] = {
		0.307284,
		-0.010008,
		0.951565,
		0,
		-0.498048,
		0.850367,
		0.169776,
		0,
		-0.810879,
		-0.526094,
		0.25632,
		0,
		0.310104,
		1.130841,
		-0.260167,
		1
	},
	[0.333333333333] = {
		0.347805,
		-0.052135,
		0.936116,
		0,
		-0.323311,
		0.93054,
		0.171948,
		0,
		-0.880058,
		-0.362461,
		0.306791,
		0,
		0.438828,
		1.113651,
		-0.273577,
		1
	},
	[0.35] = {
		0.340624,
		-0.076585,
		0.937075,
		0,
		-0.146146,
		0.98025,
		0.133237,
		0,
		-0.928771,
		-0.182334,
		0.322704,
		0,
		0.510795,
		1.049282,
		-0.289506,
		1
	},
	[0.366666666667] = {
		0.312037,
		-0.088283,
		0.945959,
		0,
		0.04617,
		0.995906,
		0.077715,
		0,
		-0.948947,
		0.019425,
		0.314836,
		0,
		0.574334,
		0.936919,
		-0.313654,
		1
	},
	[0.383333333333] = {
		0.294968,
		-0.107891,
		0.949396,
		0,
		0.222527,
		0.974041,
		0.041555,
		0,
		-0.929234,
		0.199009,
		0.311319,
		0,
		0.679076,
		0.803641,
		-0.339658,
		1
	},
	[0.3] = {
		0.225279,
		0.030694,
		0.973811,
		0,
		-0.669871,
		0.730661,
		0.131936,
		0,
		-0.707476,
		-0.68205,
		0.185164,
		0,
		0.14766,
		1.111568,
		-0.24622,
		1
	},
	[0.416666666667] = {
		0.295956,
		-0.234966,
		0.925852,
		0,
		0.51633,
		0.854816,
		0.051889,
		0,
		-0.803625,
		0.462688,
		0.374308,
		0,
		1.086613,
		0.517621,
		-0.413621,
		1
	},
	[0.433333333333] = {
		0.261824,
		-0.286371,
		0.921651,
		0,
		0.633031,
		0.7718,
		0.059977,
		0,
		-0.728505,
		0.56773,
		0.383358,
		0,
		1.259074,
		0.41069,
		-0.484432,
		1
	},
	[0.45] = {
		0.236007,
		-0.301995,
		0.923634,
		0,
		0.710954,
		0.701616,
		0.047741,
		0,
		-0.662454,
		0.645394,
		0.380291,
		0,
		1.373215,
		0.317736,
		-0.614841,
		1
	},
	[0.466666666667] = {
		0.214939,
		-0.29952,
		0.929564,
		0,
		0.766769,
		0.641253,
		0.029326,
		0,
		-0.60487,
		0.706457,
		0.367493,
		0,
		1.470022,
		0.242819,
		-0.762573,
		1
	},
	[0.483333333333] = {
		0.195408,
		-0.289102,
		0.937142,
		0,
		0.806982,
		0.590413,
		0.01387,
		0,
		-0.557311,
		0.753547,
		0.348672,
		0,
		1.584144,
		0.193103,
		-0.902397,
		1
	},
	[0.4] = {
		0.308633,
		-0.166603,
		0.936477,
		0,
		0.370424,
		0.927867,
		0.042992,
		0,
		-0.876089,
		0.333625,
		0.348084,
		0,
		0.883628,
		0.651162,
		-0.369915,
		1
	},
	[0.516666666667] = {
		0.172697,
		-0.272746,
		0.946459,
		0,
		0.868018,
		0.496296,
		-0.015364,
		0,
		-0.465533,
		0.824197,
		0.322457,
		0,
		1.802515,
		0.185276,
		-1.079887,
		1
	},
	[0.533333333333] = {
		0.168797,
		-0.27275,
		0.947162,
		0,
		0.895001,
		0.444959,
		-0.031368,
		0,
		-0.412892,
		0.853006,
		0.319219,
		0,
		1.901303,
		0.206656,
		-1.112895,
		1
	},
	[0.55] = {
		0.167224,
		-0.271559,
		0.947783,
		0,
		0.921017,
		0.38605,
		-0.05189,
		0,
		-0.3518,
		0.881601,
		0.314668,
		0,
		1.982409,
		0.226767,
		-1.119322,
		1
	},
	[0.566666666667] = {
		0.168193,
		-0.269697,
		0.948143,
		0,
		0.943203,
		0.323578,
		-0.075276,
		0,
		-0.286496,
		0.906951,
		0.308803,
		0,
		2.043971,
		0.247348,
		-1.110179,
		1
	},
	[0.583333333333] = {
		0.171764,
		-0.26696,
		0.948277,
		0,
		0.96049,
		0.259358,
		-0.100962,
		0,
		-0.218991,
		0.928152,
		0.30096,
		0,
		2.076931,
		0.269595,
		-1.095282,
		1
	},
	[0.5] = {
		0.18142,
		-0.276736,
		0.943665,
		0,
		0.838807,
		0.544426,
		-0.001605,
		0,
		-0.513312,
		0.791844,
		0.330898,
		0,
		1.697915,
		0.173195,
		-1.018927,
		1
	},
	[0.616666666667] = {
		0.188882,
		-0.258185,
		0.947451,
		0,
		0.977861,
		0.137944,
		-0.157354,
		0,
		-0.090069,
		0.956197,
		0.278524,
		0,
		2.076561,
		0.320458,
		-1.051666,
		1
	},
	[0.633333333333] = {
		0.203159,
		-0.25215,
		0.946122,
		0,
		0.978551,
		0.085949,
		-0.187217,
		0,
		-0.034111,
		0.963864,
		0.264203,
		0,
		2.051777,
		0.34873,
		-1.02621,
		1
	},
	[0.65] = {
		0.221511,
		-0.245021,
		0.943874,
		0,
		0.975071,
		0.042696,
		-0.217748,
		0,
		0.013053,
		0.968577,
		0.248371,
		0,
		2.022213,
		0.374952,
		-1.000185,
		1
	},
	[0.666666666667] = {
		0.244268,
		-0.237231,
		0.940242,
		0,
		0.968447,
		0.010251,
		-0.249009,
		0,
		0.049434,
		0.971399,
		0.23225,
		0,
		1.985622,
		0.400234,
		-0.973498,
		1
	},
	[0.683333333333] = {
		0.271473,
		-0.228642,
		0.934893,
		0,
		0.959666,
		-0.009464,
		-0.280982,
		0,
		0.073092,
		0.973465,
		0.216851,
		0,
		1.942529,
		0.422995,
		-0.946515,
		1
	},
	[0.6] = {
		0.178518,
		-0.263234,
		0.948071,
		0,
		0.972064,
		0.196414,
		-0.128501,
		0,
		-0.152388,
		0.944526,
		0.290944,
		0,
		2.087957,
		0.293919,
		-1.074775,
		1
	},
	[0.716666666667] = {
		0.340458,
		-0.209978,
		0.916514,
		0,
		0.937406,
		-8.1e-05,
		-0.348237,
		0,
		0.073197,
		0.977706,
		0.196807,
		0,
		1.839087,
		0.462704,
		-0.892028,
		1
	},
	[0.733333333333] = {
		0.381679,
		-0.199599,
		0.902486,
		0,
		0.922983,
		0.030302,
		-0.383646,
		0,
		0.049228,
		0.979409,
		0.195792,
		0,
		1.782644,
		0.475217,
		-0.863884,
		1
	},
	[0.75] = {
		0.426756,
		-0.188227,
		0.884562,
		0,
		0.904301,
		0.077022,
		-0.419889,
		0,
		0.010904,
		0.979101,
		0.203084,
		0,
		1.723565,
		0.478423,
		-0.835486,
		1
	},
	[0.766666666667] = {
		0.474263,
		-0.175547,
		0.862704,
		0,
		0.879585,
		0.136205,
		-0.455827,
		0,
		-0.037486,
		0.975003,
		0.219005,
		0,
		1.667122,
		0.475407,
		-0.80891,
		1
	},
	[0.783333333333] = {
		0.523327,
		-0.161597,
		0.836669,
		0,
		0.847128,
		0.204911,
		-0.490291,
		0,
		-0.092213,
		0.965349,
		0.244129,
		0,
		1.612644,
		0.466492,
		-0.78388,
		1
	},
	[0.7] = {
		0.303418,
		-0.219669,
		0.927191,
		0,
		0.949314,
		-0.014157,
		-0.314012,
		0,
		0.082105,
		0.975472,
		0.204239,
		0,
		1.893657,
		0.443928,
		-0.919205,
		1
	},
	[0.816666666667] = {
		0.621192,
		-0.129355,
		0.772909,
		0,
		0.756231,
		0.3576,
		-0.547939,
		0,
		-0.205513,
		0.924873,
		0.31996,
		0,
		1.50205,
		0.446112,
		-0.739613,
		1
	},
	[0.833333333333] = {
		0.667934,
		-0.111314,
		0.735849,
		0,
		0.698495,
		0.435002,
		-0.568224,
		0,
		-0.256845,
		0.893522,
		0.368305,
		0,
		1.446049,
		0.437043,
		-0.719958,
		1
	},
	[0.85] = {
		0.712066,
		-0.092699,
		0.695966,
		0,
		0.634634,
		0.508992,
		-0.581521,
		0,
		-0.300334,
		0.855765,
		0.421266,
		0,
		1.389649,
		0.430068,
		-0.70257,
		1
	},
	[0.866666666667] = {
		0.752887,
		-0.073655,
		0.654016,
		0,
		0.567082,
		0.576947,
		-0.587835,
		0,
		-0.334036,
		0.813454,
		0.476144,
		0,
		1.3322,
		0.42501,
		-0.686416,
		1
	},
	[0.883333333333] = {
		0.78996,
		-0.055264,
		0.610663,
		0,
		0.498951,
		0.636804,
		-0.587818,
		0,
		-0.356387,
		0.769043,
		0.530623,
		0,
		1.273508,
		0.422805,
		-0.671704,
		1
	},
	[0.8] = {
		0.572606,
		-0.146058,
		0.806715,
		0,
		0.806079,
		0.279772,
		-0.521501,
		0,
		-0.149527,
		0.948891,
		0.277934,
		0,
		1.557314,
		0.455992,
		-0.760914,
		1
	},
	[0.916666666667] = {
		0.852156,
		-0.022994,
		0.522783,
		0,
		0.373891,
		0.725711,
		-0.577537,
		0,
		-0.366109,
		0.687616,
		0.627016,
		0,
		1.15144,
		0.42559,
		-0.641399,
		1
	},
	[0.933333333333] = {
		0.877735,
		-0.010277,
		0.479036,
		0,
		0.320188,
		0.75635,
		-0.570452,
		0,
		-0.356456,
		0.654087,
		0.667165,
		0,
		1.089052,
		0.430253,
		-0.625249,
		1
	},
	[0.95] = {
		0.900054,
		0.000402,
		0.435778,
		0,
		0.272186,
		0.780428,
		-0.562891,
		0,
		-0.34032,
		0.625245,
		0.702318,
		0,
		1.027074,
		0.435941,
		-0.608078,
		1
	},
	[0.966666666667] = {
		0.919584,
		0.00932,
		0.392782,
		0,
		0.228164,
		0.8012,
		-0.553191,
		0,
		-0.319853,
		0.598324,
		0.734644,
		0,
		0.96704,
		0.442542,
		-0.591143,
		1
	},
	[0.983333333333] = {
		0.936596,
		0.017645,
		0.349965,
		0,
		0.185806,
		0.821756,
		-0.538696,
		0,
		-0.297091,
		0.569567,
		0.766375,
		0,
		0.910599,
		0.44913,
		-0.575333,
		1
	},
	[0.9] = {
		0.823118,
		-0.037891,
		0.566604,
		0,
		0.433126,
		0.687177,
		-0.583258,
		0,
		-0.367257,
		0.725502,
		0.582039,
		0,
		1.213514,
		0.422861,
		-0.657041,
		1
	},
	[1.01666666667] = {
		0.963317,
		0.030705,
		0.266605,
		0,
		0.110845,
		0.859212,
		-0.499468,
		0,
		-0.244407,
		0.510697,
		0.82429,
		0,
		0.809777,
		0.462757,
		-0.546026,
		1
	},
	[1.03333333333] = {
		0.973318,
		0.035367,
		0.226719,
		0,
		0.078937,
		0.876139,
		-0.475552,
		0,
		-0.215456,
		0.48076,
		0.84997,
		0,
		0.76664,
		0.469603,
		-0.532415,
		1
	},
	[1.05] = {
		0.981309,
		0.038793,
		0.18849,
		0,
		0.051067,
		0.891863,
		-0.449414,
		0,
		-0.185541,
		0.450639,
		0.873212,
		0,
		0.729174,
		0.476332,
		-0.519372,
		1
	},
	[1.06666666667] = {
		0.987491,
		0.041209,
		0.152195,
		0,
		0.027153,
		0.906381,
		-0.421588,
		0,
		-0.15532,
		0.420447,
		0.893924,
		0,
		0.698173,
		0.482836,
		-0.506818,
		1
	},
	[1.08333333333] = {
		0.992076,
		0.04274,
		0.118145,
		0,
		0.007134,
		0.919677,
		-0.39261,
		0,
		-0.125435,
		0.390342,
		0.912085,
		0,
		0.675451,
		0.489007,
		-0.494642,
		1
	},
	[1.11666666667] = {
		0.997371,
		0.043779,
		0.057746,
		0,
		-0.022094,
		0.942649,
		-0.333054,
		0,
		-0.069015,
		0.330902,
		0.941138,
		0,
		0.645604,
		0.499989,
		-0.471227,
		1
	},
	[1.13333333333] = {
		0.998542,
		0.043575,
		0.031862,
		0,
		-0.031881,
		0.952356,
		-0.303318,
		0,
		-0.043561,
		0.30186,
		0.952357,
		0,
		0.634956,
		0.50465,
		-0.459899,
		1
	},
	[1.15] = {
		0.99903,
		0.043063,
		0.009154,
		0,
		-0.038909,
		0.960913,
		-0.274104,
		0,
		-0.0206,
		0.273482,
		0.961656,
		0,
		0.623413,
		0.508718,
		-0.448757,
		1
	},
	[1.16666666667] = {
		0.999047,
		0.042428,
		-0.010208,
		0,
		-0.043636,
		0.968366,
		-0.245687,
		0,
		-0.000539,
		0.245899,
		0.969295,
		0,
		0.612076,
		0.512005,
		-0.437842,
		1
	},
	[1.18333333333] = {
		0.998784,
		0.041867,
		-0.02602,
		0,
		-0.046548,
		0.974764,
		-0.218329,
		0,
		0.016223,
		0.219275,
		0.975528,
		0,
		0.600992,
		0.51432,
		-0.427124,
		1
	},
	[1.1] = {
		0.995293,
		0.043553,
		0.086572,
		0,
		-0.009204,
		0.931766,
		-0.362943,
		0,
		-0.096472,
		0.360437,
		0.927781,
		0,
		0.658375,
		0.49475,
		-0.482811,
		1
	},
	[1.21666666667] = {
		0.998078,
		0.041342,
		-0.046159,
		0,
		-0.048535,
		0.984672,
		-0.167525,
		0,
		0.038526,
		0.169444,
		0.984787,
		0,
		0.579982,
		0.51592,
		-0.406432,
		1
	},
	[1.23333333333] = {
		0.997861,
		0.041522,
		-0.050481,
		0,
		-0.048429,
		0.98834,
		-0.144357,
		0,
		0.043899,
		0.146494,
		0.988237,
		0,
		0.570235,
		0.515228,
		-0.396511,
		1
	},
	[1.25] = {
		0.997811,
		0.042078,
		-0.05101,
		0,
		-0.048082,
		0.991261,
		-0.122837,
		0,
		0.045395,
		0.12502,
		0.991115,
		0,
		0.561163,
		0.513648,
		-0.386936,
		1
	},
	[1.26666666667] = {
		0.997891,
		0.042998,
		-0.048635,
		0,
		-0.047827,
		0.993536,
		-0.102949,
		0,
		0.043894,
		0.105058,
		0.993497,
		0,
		0.552777,
		0.511291,
		-0.377713,
		1
	},
	[1.28333333333] = {
		0.998044,
		0.044363,
		-0.044046,
		0,
		-0.047975,
		0.995254,
		-0.084663,
		0,
		0.040081,
		0.086611,
		0.995436,
		0,
		0.545177,
		0.508266,
		-0.368847,
		1
	},
	[1.2] = {
		0.998413,
		0.041454,
		-0.038123,
		0,
		-0.048036,
		0.980176,
		-0.192216,
		0,
		0.029399,
		0.193742,
		0.980612,
		0,
		0.590263,
		0.51566,
		-0.416654,
		1
	},
	[1.31666666667] = {
		0.998362,
		0.048562,
		-0.030257,
		0,
		-0.05013,
		0.997311,
		-0.053455,
		0,
		0.027579,
		0.054884,
		0.998112,
		0,
		0.532416,
		0.50051,
		-0.35239,
		1
	},
	[1.33333333333] = {
		0.998446,
		0.051153,
		-0.022133,
		0,
		-0.052024,
		0.997813,
		-0.040772,
		0,
		0.019999,
		0.04186,
		0.998923,
		0,
		0.527207,
		0.495928,
		-0.344959,
		1
	},
	[1.35] = {
		0.998462,
		0.053663,
		-0.01392,
		0,
		-0.054067,
		0.998073,
		-0.030433,
		0,
		0.01226,
		0.031138,
		0.99944,
		0,
		0.522656,
		0.490948,
		-0.338138,
		1
	},
	[1.36666666667] = {
		0.99842,
		0.055859,
		-0.006137,
		0,
		-0.055981,
		0.998192,
		-0.021878,
		0,
		0.004904,
		0.022187,
		0.999742,
		0,
		0.518679,
		0.485679,
		-0.332251,
		1
	},
	[1.38333333333] = {
		0.998356,
		0.057312,
		0.000685,
		0,
		-0.057296,
		0.998248,
		-0.014792,
		0,
		-0.001532,
		0.014728,
		0.99989,
		0,
		0.515163,
		0.480186,
		-0.327646,
		1
	},
	[1.3] = {
		0.998221,
		0.046152,
		-0.037738,
		0,
		-0.048648,
		0.99649,
		-0.068132,
		0,
		0.034461,
		0.069847,
		0.996962,
		0,
		0.538357,
		0.504643,
		-0.3604,
		1
	},
	[1.41666666667] = {
		0.998215,
		0.059018,
		0.009102,
		0,
		-0.058991,
		0.998253,
		-0.003203,
		0,
		-0.009275,
		0.002661,
		0.999953,
		0,
		0.509575,
		0.46914,
		-0.322241,
		1
	},
	[1.43333333333] = {
		0.998179,
		0.059465,
		0.010141,
		0,
		-0.059485,
		0.998228,
		0.001688,
		0,
		-0.010023,
		-0.002289,
		0.999947,
		0,
		0.507436,
		0.463878,
		-0.321239,
		1
	},
	[1.45] = {
		0.998173,
		0.059767,
		0.008828,
		0,
		-0.059821,
		0.998192,
		0.005887,
		0,
		-0.00846,
		-0.006404,
		0.999944,
		0,
		0.505643,
		0.458995,
		-0.32096,
		1
	},
	[1.46666666667] = {
		0.998185,
		0.059931,
		0.005975,
		0,
		-0.059986,
		0.998154,
		0.009473,
		0,
		-0.005396,
		-0.009815,
		0.999937,
		0,
		0.504188,
		0.454647,
		-0.321332,
		1
	},
	[1.48333333333] = {
		0.998197,
		0.059983,
		0.002218,
		0,
		-0.060006,
		0.99812,
		0.01244,
		0,
		-0.001468,
		-0.012551,
		0.99992,
		0,
		0.503045,
		0.450969,
		-0.322252,
		1
	},
	[1.4] = {
		0.998279,
		0.058326,
		0.006021,
		0,
		-0.058272,
		0.998262,
		-0.008762,
		0,
		-0.006522,
		0.008396,
		0.999943,
		0,
		0.512126,
		0.474632,
		-0.324255,
		1
	},
	[1.51666666667] = {
		0.998183,
		0.059848,
		-0.007051,
		0,
		-0.059718,
		0.998064,
		0.017377,
		0,
		0.008078,
		-0.016924,
		0.999824,
		0,
		0.501556,
		0.446425,
		-0.324993,
		1
	},
	[1.53333333333] = {
		0.998144,
		0.059716,
		-0.01193,
		0,
		-0.059474,
		0.998036,
		0.019647,
		0,
		0.01308,
		-0.018901,
		0.999736,
		0,
		0.501139,
		0.445883,
		-0.326502,
		1
	},
	[1.55] = {
		0.998086,
		0.05958,
		-0.01655,
		0,
		-0.059211,
		0.998004,
		0.02196,
		0,
		0.017826,
		-0.020938,
		0.999622,
		0,
		0.50089,
		0.446947,
		-0.32791,
		1
	},
	[1.56666666667] = {
		0.998017,
		0.059472,
		-0.020597,
		0,
		-0.058964,
		0.997961,
		0.024448,
		0,
		0.022009,
		-0.023185,
		0.999489,
		0,
		0.500761,
		0.448956,
		-0.329076,
		1
	},
	[1.58333333333] = {
		0.99795,
		0.059426,
		-0.023755,
		0,
		-0.058774,
		0.997899,
		0.027244,
		0,
		0.025324,
		-0.025792,
		0.999347,
		0,
		0.500705,
		0.451639,
		-0.329857,
		1
	},
	[1.5] = {
		0.998199,
		0.059946,
		-0.00223,
		0,
		-0.059906,
		0.998091,
		0.015014,
		0,
		0.003126,
		-0.014853,
		0.999885,
		0,
		0.502178,
		0.448161,
		-0.32353,
		1
	},
	[1.61666666667] = {
		0.997888,
		0.059702,
		-0.025599,
		0,
		-0.058803,
		0.997672,
		0.034522,
		0,
		0.0276,
		-0.032944,
		0.999076,
		0,
		0.500571,
		0.455688,
		-0.329385,
		1
	},
	[1.63333333333] = {
		0.997892,
		0.059987,
		-0.024746,
		0,
		-0.059001,
		0.997503,
		0.03881,
		0,
		0.027012,
		-0.037269,
		0.99894,
		0,
		0.500422,
		0.456689,
		-0.328436,
		1
	},
	[1.6] = {
		0.997899,
		0.059474,
		-0.025709,
		0,
		-0.058684,
		0.997811,
		0.030482,
		0,
		0.027466,
		-0.028909,
		0.999205,
		0,
		0.500669,
		0.454244,
		-0.330108,
		1
	}
}

return spline_matrices