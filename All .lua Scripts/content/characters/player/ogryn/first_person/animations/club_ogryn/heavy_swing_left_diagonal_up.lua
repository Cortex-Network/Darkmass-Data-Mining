local spline_matrices = {
	[0] = {
		0.76829,
		-0.613963,
		0.181053,
		0,
		0.591254,
		0.789053,
		0.166775,
		0,
		-0.245254,
		-0.021083,
		0.96923,
		0,
		1.354127,
		-0.082837,
		0.202871,
		1
	},
	[0.0166666666667] = {
		0.693713,
		-0.701496,
		0.163295,
		0,
		0.700643,
		0.709797,
		0.072719,
		0,
		-0.166918,
		0.063965,
		0.983894,
		0,
		1.367068,
		-0.030552,
		0.195887,
		1
	},
	[0.0333333333333] = {
		0.619915,
		-0.762807,
		0.183932,
		0,
		0.781059,
		0.622329,
		-0.051502,
		0,
		-0.075181,
		0.175589,
		0.981589,
		0,
		1.376865,
		0.017557,
		0.169216,
		1
	},
	[0.05] = {
		0.559047,
		-0.797865,
		0.225562,
		0,
		0.828596,
		0.527794,
		-0.186715,
		0,
		0.029923,
		0.291282,
		0.956169,
		0,
		1.381622,
		0.059597,
		0.126685,
		1
	},
	[0.0666666666667] = {
		0.516469,
		-0.813513,
		0.267313,
		0,
		0.844883,
		0.433294,
		-0.313735,
		0,
		0.139402,
		0.387882,
		0.911106,
		0,
		1.380741,
		0.094907,
		0.072831,
		1
	},
	[0.0833333333333] = {
		0.489162,
		-0.822684,
		0.289676,
		0,
		0.837761,
		0.350782,
		-0.418461,
		0,
		0.242648,
		0.447374,
		0.860801,
		0,
		1.375156,
		0.124228,
		0.011921,
		1
	},
	[0.116666666667] = {
		0.439594,
		-0.871717,
		0.216488,
		0,
		0.799198,
		0.26961,
		-0.537208,
		0,
		0.409926,
		0.409171,
		0.815193,
		0,
		1.357637,
		0.171695,
		-0.11818,
		1
	},
	[0.133333333333] = {
		0.395062,
		-0.914112,
		0.091242,
		0,
		0.793656,
		0.289601,
		-0.535016,
		0,
		0.462641,
		0.283779,
		0.839901,
		0,
		1.337388,
		0.21402,
		-0.177281,
		1
	},
	[0.15] = {
		0.315581,
		-0.923144,
		-0.219574,
		0,
		0.826522,
		0.38109,
		-0.414285,
		0,
		0.466122,
		-0.050742,
		0.883264,
		0,
		1.275434,
		0.360448,
		-0.27581,
		1
	},
	[0.166666666667] = {
		0.246057,
		-0.699434,
		-0.671006,
		0,
		0.888818,
		0.438952,
		-0.13162,
		0,
		0.386598,
		-0.564016,
		0.729676,
		0,
		1.172063,
		0.593569,
		-0.41159,
		1
	},
	[0.183333333333] = {
		0.254054,
		-0.293918,
		-0.921449,
		0,
		0.922676,
		0.359351,
		0.139769,
		0,
		0.290043,
		-0.885708,
		0.362486,
		0,
		1.060171,
		0.807108,
		-0.524828,
		1
	},
	[0.1] = {
		0.467548,
		-0.839035,
		0.278242,
		0,
		0.818807,
		0.292459,
		-0.493987,
		0,
		0.333099,
		0.458789,
		0.823746,
		0,
		1.366954,
		0.14908,
		-0.052898,
		1
	},
	[0.216666666667] = {
		0.044565,
		0.465701,
		-0.883819,
		0,
		0.842232,
		0.45828,
		0.283944,
		0,
		0.53727,
		-0.757035,
		-0.371805,
		0,
		0.901307,
		1.054005,
		-0.50677,
		1
	},
	[0.233333333333] = {
		-0.372168,
		0.793309,
		-0.481822,
		0,
		0.720317,
		0.574241,
		0.389089,
		0,
		0.58535,
		-0.202259,
		-0.785148,
		0,
		0.810932,
		1.199556,
		-0.464534,
		1
	},
	[0.25] = {
		-0.405071,
		0.812812,
		-0.418632,
		0,
		0.622953,
		0.580512,
		0.524343,
		0,
		0.669214,
		-0.048392,
		-0.741492,
		0,
		0.693545,
		1.301119,
		-0.398775,
		1
	},
	[0.266666666667] = {
		-0.415457,
		0.815715,
		-0.402499,
		0,
		0.441723,
		0.567742,
		0.694658,
		0,
		0.795158,
		0.110808,
		-0.596192,
		0,
		0.547145,
		1.356188,
		-0.333418,
		1
	},
	[0.283333333333] = {
		-0.763818,
		0.561713,
		-0.317901,
		0,
		-0.021559,
		0.470061,
		0.882371,
		0,
		0.645071,
		0.680824,
		-0.346931,
		0,
		0.195894,
		1.356042,
		-0.227385,
		1
	},
	[0.2] = {
		0.273747,
		-0.024121,
		-0.961499,
		0,
		0.903974,
		0.347862,
		0.248643,
		0,
		0.328472,
		-0.937235,
		0.117031,
		0,
		0.965314,
		0.939017,
		-0.542118,
		1
	},
	[0.316666666667] = {
		-0.822068,
		0.222563,
		-0.524089,
		0,
		-0.565424,
		-0.427533,
		0.705345,
		0,
		-0.067082,
		0.876174,
		0.477304,
		0,
		-0.341331,
		1.115696,
		-0.034613,
		1
	},
	[0.333333333333] = {
		-0.756699,
		0.337324,
		-0.560017,
		0,
		-0.573086,
		-0.754476,
		0.319903,
		0,
		-0.314609,
		0.563009,
		0.764227,
		0,
		-0.551314,
		0.906605,
		0.078871,
		1
	},
	[0.35] = {
		-0.442713,
		0.487323,
		-0.752676,
		0,
		-0.766332,
		-0.641467,
		0.035426,
		0,
		-0.465553,
		0.592484,
		0.657437,
		0,
		-0.745356,
		0.655128,
		0.089085,
		1
	},
	[0.366666666667] = {
		-0.324776,
		0.662888,
		-0.674611,
		0,
		-0.903871,
		-0.427541,
		0.015037,
		0,
		-0.278456,
		0.614645,
		0.73802,
		0,
		-0.885628,
		0.215137,
		0.098529,
		1
	},
	[0.383333333333] = {
		-0.507683,
		0.830247,
		-0.230104,
		0,
		-0.849604,
		-0.526771,
		-0.026167,
		0,
		-0.142937,
		0.182213,
		0.972814,
		0,
		-0.931579,
		-0.301463,
		0.167621,
		1
	},
	[0.3] = {
		-0.881594,
		0.193245,
		-0.430637,
		0,
		-0.429069,
		0.052109,
		0.901768,
		0,
		0.196702,
		0.979766,
		0.036977,
		0,
		-0.145526,
		1.293397,
		-0.126785,
		1
	},
	[0.416666666667] = {
		-0.487754,
		0.86453,
		-0.121173,
		0,
		-0.822755,
		-0.501644,
		-0.267258,
		0,
		-0.291839,
		-0.03066,
		0.955976,
		0,
		-0.72252,
		-0.738152,
		0.112631,
		1
	},
	[0.433333333333] = {
		-0.583592,
		0.811617,
		-0.026432,
		0,
		-0.768041,
		-0.562243,
		-0.306586,
		0,
		-0.263692,
		-0.15862,
		0.951476,
		0,
		-0.622278,
		-0.827417,
		0.092202,
		1
	},
	[0.45] = {
		-0.701985,
		0.710313,
		0.051703,
		0,
		-0.679981,
		-0.646881,
		-0.345213,
		0,
		-0.211763,
		-0.277491,
		0.937099,
		0,
		-0.479373,
		-0.850075,
		-0.012948,
		1
	},
	[0.466666666667] = {
		-0.81653,
		0.569565,
		0.094201,
		0,
		-0.555111,
		-0.729814,
		-0.399027,
		0,
		-0.158523,
		-0.37811,
		0.912088,
		0,
		-0.332247,
		-0.842325,
		-0.152401,
		1
	},
	[0.483333333333] = {
		-0.922078,
		0.364845,
		0.129075,
		0,
		-0.381744,
		-0.802664,
		-0.458259,
		0,
		-0.06359,
		-0.471824,
		0.879396,
		0,
		-0.170039,
		-0.825628,
		-0.299224,
		1
	},
	[0.4] = {
		-0.501018,
		0.860458,
		-0.092695,
		0,
		-0.841115,
		-0.50935,
		-0.181899,
		0,
		-0.203731,
		-0.013168,
		0.978938,
		0,
		-0.798209,
		-0.594126,
		0.120513,
		1
	},
	[0.516666666667] = {
		-0.963124,
		-0.217615,
		0.158228,
		0,
		0.084446,
		-0.802854,
		-0.590164,
		0,
		0.255463,
		-0.555039,
		0.791625,
		0,
		0.178528,
		-0.745509,
		-0.597403,
		1
	},
	[0.533333333333] = {
		-0.834311,
		-0.531183,
		0.147546,
		0,
		0.321017,
		-0.685676,
		-0.653296,
		0,
		0.448189,
		-0.497688,
		0.742586,
		0,
		0.345674,
		-0.675101,
		-0.738385,
		1
	},
	[0.55] = {
		-0.601019,
		-0.789504,
		0.124339,
		0,
		0.503938,
		-0.495094,
		-0.707764,
		0,
		0.620341,
		-0.36272,
		0.695421,
		0,
		0.491619,
		-0.58707,
		-0.867012,
		1
	},
	[0.566666666667] = {
		-0.298946,
		-0.949424,
		0.096046,
		0,
		0.602071,
		-0.265741,
		-0.752923,
		0,
		0.740366,
		-0.167257,
		0.651063,
		0,
		0.606335,
		-0.489888,
		-0.979021,
		1
	},
	[0.583333333333] = {
		0.020765,
		-0.997464,
		0.068078,
		0,
		0.608627,
		-0.04141,
		-0.792375,
		0,
		0.793185,
		0.057887,
		0.606223,
		0,
		0.68481,
		-0.39406,
		-1.071048,
		1
	},
	[0.5] = {
		-0.983758,
		0.095724,
		0.151845,
		0,
		-0.162164,
		-0.836651,
		-0.523181,
		0,
		0.07696,
		-0.539307,
		0.838585,
		0,
		0.002826,
		-0.794996,
		-0.449215,
		1
	},
	[0.616666666667] = {
		0.550491,
		-0.834823,
		0.005522,
		0,
		0.411248,
		0.265413,
		-0.872027,
		0,
		0.726522,
		0.482314,
		0.489427,
		0,
		0.731985,
		-0.239514,
		-1.18265,
		1
	},
	[0.633333333333] = {
		0.633845,
		-0.773372,
		0.011693,
		0,
		0.342453,
		0.26705,
		-0.900783,
		0,
		0.693518,
		0.574961,
		0.434112,
		0,
		0.735678,
		-0.198549,
		-1.207767,
		1
	},
	[0.65] = {
		0.709992,
		-0.704089,
		0.013007,
		0,
		0.270151,
		0.255266,
		-0.928363,
		0,
		0.65033,
		0.662645,
		0.371447,
		0,
		0.737299,
		-0.16191,
		-1.231889,
		1
	},
	[0.666666666667] = {
		0.776103,
		-0.630543,
		0.008918,
		0,
		0.19792,
		0.230133,
		-0.95282,
		0,
		0.598742,
		0.741252,
		0.303404,
		0,
		0.737299,
		-0.130412,
		-1.254283,
		1
	},
	[0.683333333333] = {
		0.83056,
		-0.55693,
		-0.000133,
		0,
		0.129387,
		0.193189,
		-0.972593,
		0,
		0.541691,
		0.807779,
		0.232515,
		0,
		0.736183,
		-0.10458,
		-1.274286,
		1
	},
	[0.6] = {
		0.313085,
		-0.948877,
		0.040117,
		0,
		0.537623,
		0.142253,
		-0.831099,
		0,
		0.782904,
		0.281772,
		0.554676,
		0,
		0.726338,
		-0.308609,
		-1.140054,
		1
	},
	[0.716666666667] = {
		0.904398,
		-0.425835,
		-0.02699,
		0,
		0.015276,
		0.095528,
		-0.99531,
		0,
		0.426416,
		0.899744,
		0.0929,
		0,
		0.732275,
		-0.070854,
		-1.305148,
		1
	},
	[0.733333333333] = {
		0.926163,
		-0.374961,
		-0.040315,
		0,
		-0.026534,
		0.041846,
		-0.998772,
		0,
		0.376188,
		0.926096,
		0.028807,
		0,
		0.729949,
		-0.063124,
		-1.315402,
		1
	},
	[0.75] = {
		0.940188,
		-0.336933,
		-0.050228,
		0,
		-0.057132,
		-0.010601,
		-0.99831,
		0,
		0.335832,
		0.941469,
		-0.029217,
		0,
		0.727402,
		-0.061584,
		-1.322002,
		1
	},
	[0.766666666667] = {
		0.948117,
		-0.313252,
		-0.054295,
		0,
		-0.076549,
		-0.059175,
		-0.995308,
		0,
		0.30857,
		0.947824,
		-0.080084,
		0,
		0.724484,
		-0.066416,
		-1.32487,
		1
	},
	[0.7] = {
		0.873052,
		-0.48746,
		-0.012786,
		0,
		0.067721,
		0.147173,
		-0.98679,
		0,
		0.482902,
		0.860653,
		0.161501,
		0,
		0.734402,
		-0.08469,
		-1.291366,
		1
	}
}

return spline_matrices