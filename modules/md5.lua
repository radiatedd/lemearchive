--[[
	https://github.com/awesomeusername69420/miscellaneous-gmod-stuff

	https://github.com/kikito/md5.lua but as a module and cleaned up a little; This is version 0.5.0
]]

local bit_band = bit.band
local bit_bor = bit.bor
local bit_bxor = bit.bxor
local bit_lshift = bit.lshift
local bit_rshift = bit.rshift

module("md5", package.seeall)

Const = {
	0xd76aa478, 0xe8c7b756, 0x242070db, 0xc1bdceee,
	0xf57c0faf, 0x4787c62a, 0xa8304613, 0xfd469501,
	0x698098d8, 0x8b44f7af, 0xffff5bb1, 0x895cd7be,
	0x6b901122, 0xfd987193, 0xa679438e, 0x49b40821,
	0xf61e2562, 0xc040b340, 0x265e5a51, 0xe9b6c7aa,
	0xd62f105d, 0x02441453, 0xd8a1e681, 0xe7d3fbc8,
	0x21e1cde6, 0xc33707d6, 0xf4d50d87, 0x455a14ed,
	0xa9e3e905, 0xfcefa3f8, 0x676f02d9, 0x8d2a4c8a,
	0xfffa3942, 0x8771f681, 0x6d9d6122, 0xfde5380c,
	0xa4beea44, 0x4bdecfa9, 0xf6bb4b60, 0xbebfbc70,
	0x289b7ec6, 0xeaa127fa, 0xd4ef3085, 0x04881d05,
	0xd9d4d039, 0xe6db99e5, 0x1fa27cf8, 0xc4ac5665,
	0xf4292244, 0x432aff97, 0xab9423a7, 0xfc93a039,
	0x655b59c3, 0x8f0ccc92, 0xffeff47d, 0x85845dd1,
	0x6fa87e4f, 0xfe2ce6e0, 0xa3014314, 0x4e0811a1,
	0xf7537e82, 0xbd3af235, 0x2ad7d2bb, 0xeb86d391,
	0x67452301, 0xefcdab89, 0x98badcfe, 0x10325476
}

local f = function(x, y, z)
	return bit_bor(bit_band(x, y), bit_band(-x - 1, z))
end

local g = function(x, y, z)
	return bit_bor(bit_band(x, z), bit_band(y, -z - 1))
end

local h = function(x, y, z)
	return bit_bxor(x, bit_bxor(y, z))
end

local i = function(x, y, z)
	return bit_bxor(y, bit_bor(x, -z - 1))
end

local z = function(f, a, b, c, d, x, s, ac)
	a = bit_band(a + f(b, c, d) + x + ac, 0xffffffff)
	return bit_bor(bit_lshift(bit_band(a, bit_rshift(0xffffffff, s)), s), bit_rshift(a, 32 - s)) + b
end

local MAX = 2 ^ 31
local SUB = 2 ^ 32

function Fix(a)
	if a > MAX then
		return a - SUB
	end

	return a
end

function Transform(A, B, C, D, X)
	local a, b, c, d = A, B, C, D

	a=z(f,a,b,c,d,X[ 0], 7,Const[ 1]) -- I'm not even gonna try with this cluster fuck
	a=Fix(a) b=Fix(b) c=Fix(c) d=Fix(d)
	d=z(f,d,a,b,c,X[ 1],12,Const[ 2])
	a=Fix(a) b=Fix(b) c=Fix(c) d=Fix(d)
	c=z(f,c,d,a,b,X[ 2],17,Const[ 3])
	a=Fix(a) b=Fix(b) c=Fix(c) d=Fix(d)
	b=z(f,b,c,d,a,X[ 3],22,Const[ 4])
	a=Fix(a) b=Fix(b) c=Fix(c) d=Fix(d)
	a=z(f,a,b,c,d,X[ 4], 7,Const[ 5])
	a=Fix(a) b=Fix(b) c=Fix(c) d=Fix(d)
	d=z(f,d,a,b,c,X[ 5],12,Const[ 6])
	a=Fix(a) b=Fix(b) c=Fix(c) d=Fix(d)
	c=z(f,c,d,a,b,X[ 6],17,Const[ 7])
	a=Fix(a) b=Fix(b) c=Fix(c) d=Fix(d)
	b=z(f,b,c,d,a,X[ 7],22,Const[ 8])
	a=Fix(a) b=Fix(b) c=Fix(c) d=Fix(d)
	a=z(f,a,b,c,d,X[ 8], 7,Const[ 9])
	a=Fix(a) b=Fix(b) c=Fix(c) d=Fix(d)
	d=z(f,d,a,b,c,X[ 9],12,Const[10])
	a=Fix(a) b=Fix(b) c=Fix(c) d=Fix(d)
	c=z(f,c,d,a,b,X[10],17,Const[11])
	a=Fix(a) b=Fix(b) c=Fix(c) d=Fix(d)
	b=z(f,b,c,d,a,X[11],22,Const[12])
	a=Fix(a) b=Fix(b) c=Fix(c) d=Fix(d)
	a=z(f,a,b,c,d,X[12], 7,Const[13])
	a=Fix(a) b=Fix(b) c=Fix(c) d=Fix(d)
	d=z(f,d,a,b,c,X[13],12,Const[14])
	a=Fix(a) b=Fix(b) c=Fix(c) d=Fix(d)
	c=z(f,c,d,a,b,X[14],17,Const[15])
	a=Fix(a) b=Fix(b) c=Fix(c) d=Fix(d)
	b=z(f,b,c,d,a,X[15],22,Const[16])
	a=Fix(a) b=Fix(b) c=Fix(c) d=Fix(d)

	a=z(g,a,b,c,d,X[ 1], 5,Const[17])
	a=Fix(a) b=Fix(b) c=Fix(c) d=Fix(d)
	d=z(g,d,a,b,c,X[ 6], 9,Const[18])
	a=Fix(a) b=Fix(b) c=Fix(c) d=Fix(d)
	c=z(g,c,d,a,b,X[11],14,Const[19])
	a=Fix(a) b=Fix(b) c=Fix(c) d=Fix(d)
	b=z(g,b,c,d,a,X[ 0],20,Const[20])
	a=Fix(a) b=Fix(b) c=Fix(c) d=Fix(d)
	a=z(g,a,b,c,d,X[ 5], 5,Const[21])
	a=Fix(a) b=Fix(b) c=Fix(c) d=Fix(d)
	d=z(g,d,a,b,c,X[10], 9,Const[22])
	a=Fix(a) b=Fix(b) c=Fix(c) d=Fix(d)
	c=z(g,c,d,a,b,X[15],14,Const[23])
	a=Fix(a) b=Fix(b) c=Fix(c) d=Fix(d)
	b=z(g,b,c,d,a,X[ 4],20,Const[24])
	a=Fix(a) b=Fix(b) c=Fix(c) d=Fix(d)
	a=z(g,a,b,c,d,X[ 9], 5,Const[25])
	a=Fix(a) b=Fix(b) c=Fix(c) d=Fix(d)
	d=z(g,d,a,b,c,X[14], 9,Const[26])
	a=Fix(a) b=Fix(b) c=Fix(c) d=Fix(d)
	c=z(g,c,d,a,b,X[ 3],14,Const[27])
	a=Fix(a) b=Fix(b) c=Fix(c) d=Fix(d)
	b=z(g,b,c,d,a,X[ 8],20,Const[28])
	a=Fix(a) b=Fix(b) c=Fix(c) d=Fix(d)
	a=z(g,a,b,c,d,X[13], 5,Const[29])
	a=Fix(a) b=Fix(b) c=Fix(c) d=Fix(d)
	d=z(g,d,a,b,c,X[ 2], 9,Const[30])
	a=Fix(a) b=Fix(b) c=Fix(c) d=Fix(d)
	c=z(g,c,d,a,b,X[ 7],14,Const[31])
	a=Fix(a) b=Fix(b) c=Fix(c) d=Fix(d)
	b=z(g,b,c,d,a,X[12],20,Const[32])
	a=Fix(a) b=Fix(b) c=Fix(c) d=Fix(d)

	a=z(h,a,b,c,d,X[ 5], 4,Const[33])
	a=Fix(a) b=Fix(b) c=Fix(c) d=Fix(d)
	d=z(h,d,a,b,c,X[ 8],11,Const[34])
	a=Fix(a) b=Fix(b) c=Fix(c) d=Fix(d)
	c=z(h,c,d,a,b,X[11],16,Const[35])
	a=Fix(a) b=Fix(b) c=Fix(c) d=Fix(d)
	b=z(h,b,c,d,a,X[14],23,Const[36])
	a=Fix(a) b=Fix(b) c=Fix(c) d=Fix(d)
	a=z(h,a,b,c,d,X[ 1], 4,Const[37])
	a=Fix(a) b=Fix(b) c=Fix(c) d=Fix(d)
	d=z(h,d,a,b,c,X[ 4],11,Const[38])
	a=Fix(a) b=Fix(b) c=Fix(c) d=Fix(d)
	c=z(h,c,d,a,b,X[ 7],16,Const[39])
	a=Fix(a) b=Fix(b) c=Fix(c) d=Fix(d)
	b=z(h,b,c,d,a,X[10],23,Const[40])
	a=Fix(a) b=Fix(b) c=Fix(c) d=Fix(d)
	a=z(h,a,b,c,d,X[13], 4,Const[41])
	a=Fix(a) b=Fix(b) c=Fix(c) d=Fix(d)
	d=z(h,d,a,b,c,X[ 0],11,Const[42])
	a=Fix(a) b=Fix(b) c=Fix(c) d=Fix(d)
	c=z(h,c,d,a,b,X[ 3],16,Const[43])
	a=Fix(a) b=Fix(b) c=Fix(c) d=Fix(d)
	b=z(h,b,c,d,a,X[ 6],23,Const[44])
	a=Fix(a) b=Fix(b) c=Fix(c) d=Fix(d)
	a=z(h,a,b,c,d,X[ 9], 4,Const[45])
	a=Fix(a) b=Fix(b) c=Fix(c) d=Fix(d)
	d=z(h,d,a,b,c,X[12],11,Const[46])
	a=Fix(a) b=Fix(b) c=Fix(c) d=Fix(d)
	c=z(h,c,d,a,b,X[15],16,Const[47])
	a=Fix(a) b=Fix(b) c=Fix(c) d=Fix(d)
	b=z(h,b,c,d,a,X[ 2],23,Const[48])
	a=Fix(a) b=Fix(b) c=Fix(c) d=Fix(d)

	a=z(i,a,b,c,d,X[ 0], 6,Const[49])
	a=Fix(a) b=Fix(b) c=Fix(c) d=Fix(d)
	d=z(i,d,a,b,c,X[ 7],10,Const[50])
	a=Fix(a) b=Fix(b) c=Fix(c) d=Fix(d)
	c=z(i,c,d,a,b,X[14],15,Const[51])
	a=Fix(a) b=Fix(b) c=Fix(c) d=Fix(d)
	b=z(i,b,c,d,a,X[ 5],21,Const[52])
	a=Fix(a) b=Fix(b) c=Fix(c) d=Fix(d)
	a=z(i,a,b,c,d,X[12], 6,Const[53])
	a=Fix(a) b=Fix(b) c=Fix(c) d=Fix(d)
	d=z(i,d,a,b,c,X[ 3],10,Const[54])
	a=Fix(a) b=Fix(b) c=Fix(c) d=Fix(d)
	c=z(i,c,d,a,b,X[10],15,Const[55])
	a=Fix(a) b=Fix(b) c=Fix(c) d=Fix(d)
	b=z(i,b,c,d,a,X[ 1],21,Const[56])
	a=Fix(a) b=Fix(b) c=Fix(c) d=Fix(d)
	a=z(i,a,b,c,d,X[ 8], 6,Const[57])
	a=Fix(a) b=Fix(b) c=Fix(c) d=Fix(d)
	d=z(i,d,a,b,c,X[15],10,Const[58])
	a=Fix(a) b=Fix(b) c=Fix(c) d=Fix(d)
	c=z(i,c,d,a,b,X[ 6],15,Const[59])
	a=Fix(a) b=Fix(b) c=Fix(c) d=Fix(d)
	b=z(i,b,c,d,a,X[13],21,Const[60])
	a=Fix(a) b=Fix(b) c=Fix(c) d=Fix(d)
	a=z(i,a,b,c,d,X[ 4], 6,Const[61])
	a=Fix(a) b=Fix(b) c=Fix(c) d=Fix(d)
	d=z(i,d,a,b,c,X[11],10,Const[62])
	a=Fix(a) b=Fix(b) c=Fix(c) d=Fix(d)
	c=z(i,c,d,a,b,X[ 2],15,Const[63])
	a=Fix(a) b=Fix(b) c=Fix(c) d=Fix(d)
	b=z(i,b,c,d,a,X[ 9],21,Const[64])
	a=Fix(a) b=Fix(b) c=Fix(c) d=Fix(d)

	return A + a, B + b, C + c, D + d
end

function PseudoRandom(number)
    local a, b, c, d = Fix(Const[65]), Fix(Const[66]), Fix(Const[67]), Fix(Const[68])

    local m = {}

    for i= 0, 15 do
		m[i] = 0
	end

    m[0] = number
    m[1] = 128
    m[14] = 32

    local a,b,c,d = Transform(a,b,c,d,m)

    return bit_rshift( Fix(b) , 16) % 256
end

EngineSpread = {
    [0] = {-0.492036, 0.286111},
    [1] = {-0.492036, 0.286111},
    [2] = {-0.255320, 0.128480},
    [3] = {0.456165, 0.356030},
    [4] = {-0.361731, 0.406344},
    [5] = {-0.146730, 0.834589},
    [6] = {-0.253288, -0.421936},
    [7] = {-0.448694, 0.111650},
    [8] = {-0.880700, 0.904610},
    [9] = {-0.379932, 0.138833},
    [10] = {0.502579, -0.494285},
    [11] = {-0.263847, -0.594805},
    [12] = {0.818612, 0.090368},
    [13] = {-0.063552, 0.044356},
    [14] = {0.490455, 0.304820},
    [15] = {-0.192024, 0.195162},
    [16] = {-0.139421, 0.857106},
    [17] = {0.715745, 0.336956},
    [18] = {-0.150103, -0.044842},
    [19] = {-0.176531, 0.275787},
    [20] = {0.155707, -0.152178},
    [21] = {-0.136486, -0.591896},
    [22] = {-0.021022, -0.761979},
    [23] = {-0.166004, -0.733964},
    [24] = {-0.102439, -0.132059},
    [25] = {-0.607531, -0.249979},
    [26] = {-0.500855, -0.185902},
    [27] = {-0.080884, 0.516556},
    [28] = {-0.003334, 0.138612},
    [29] = {-0.546388, -0.000115},
    [30] = {-0.228092, -0.018492},
    [31] = {0.542539, 0.543196},
    [32] = {-0.355162, 0.197473},
    [33] = {-0.041726, -0.015735},
    [34] = {-0.713230, -0.551701},
    [35] = {-0.045056, 0.090208},
    [36] = {0.061028, 0.417744},
    [37] = {-0.171149, -0.048811},
    [38] = {0.241499, 0.164562},
    [39] = {-0.129817, -0.111200},
    [40] = {0.007366, 0.091429},
    [41] = {-0.079268, -0.008285},
    [42] = {0.010982, -0.074707},
    [43] = {-0.517782, -0.682470},
    [44] = {-0.663822, -0.024972},
    [45] = {0.058213, -0.078307},
    [46] = {-0.302041, -0.132280},
    [47] = {0.217689, -0.209309},
    [48] = {-0.143615, 0.830349},
    [49] = {0.270912, 0.071245},
    [50] = {-0.258170, -0.598358},
    [51] = {0.099164, -0.257525},
    [52] = {-0.214676, -0.595918},
    [53] = {-0.427053, -0.523764},
    [54] = {-0.585472, 0.088522},
    [55] = {0.564305, -0.533822},
    [56] = {-0.387545, -0.422206},
    [57] = {0.690505, -0.299197},
    [58] = {0.475553, 0.169785},
    [59] = {0.347436, 0.575364},
    [60] = {-0.069555, -0.103340},
    [61] = {0.286197, -0.618916},
    [62] = {-0.505259, 0.106581},
    [63] = {-0.420214, -0.714843},
    [64] = {0.032596, -0.401891},
    [65] = {-0.238702, -0.087387},
    [66] = {0.714358, 0.197811},
    [67] = {0.208960, 0.319015},
    [68] = {-0.361140, 0.222130},
    [69] = {-0.133284, -0.492274},
    [70] = {0.022824, -0.133955},
    [71] = {-0.100850, 0.271962},
    [72] = {-0.050582, -0.319538},
    [73] = {0.577980, 0.095507},
    [74] = {0.224871, 0.242213},
    [75] = {-0.628274, 0.097248},
    [76] = {0.184266, 0.091959},
    [77] = {-0.036716, 0.474259},
    [78] = {-0.502566, -0.279520},
    [79] = {-0.073201, -0.036658},
    [80] = {0.339952, -0.293667},
    [81] = {0.042811, 0.130387},
    [82] = {0.125881, 0.007040},
    [83] = {0.138374, -0.418355},
    [84] = {0.261396, -0.392697},
    [85] = {-0.453318, -0.039618},
    [86] = {0.890159, -0.335165},
    [87] = {0.466437, -0.207762},
    [88] = {0.593253, 0.418018},
    [89] = {0.566934, -0.643837},
    [90] = {0.150918, 0.639588},
    [91] = {0.150112, 0.215963},
    [92] = {-0.130520, 0.324801},
    [93] = {-0.369819, -0.019127},
    [94] = {-0.038889, -0.650789},
    [95] = {0.490519, -0.065375},
    [96] = {-0.305940, 0.454759},
    [97] = {-0.521967, -0.550004},
    [98] = {-0.040366, 0.683259},
    [99] = {0.137676, -0.376445},
    [100] = {0.839301, 0.085979},
    [101] = {-0.319140, 0.481838},
    [102] = {0.201437, -0.033135},
    [103] = {0.384637, -0.036685},
    [104] = {0.598419, 0.144371},
    [105] = {-0.061424, -0.608645},
    [106] = {-0.065337, 0.308992},
    [107] = {-0.029356, -0.634337},
    [108] = {0.326532, 0.047639},
    [109] = {0.505681, -0.067187},
    [110] = {0.691612, 0.629364},
    [111] = {-0.038588, -0.635947},
    [112] = {0.637837, -0.011815},
    [113] = {0.765338, 0.563945},
    [114] = {0.213416, 0.068664},
    [115] = {-0.576581, 0.554824},
    [116] = {0.246580, 0.132726},
    [117] = {0.385548, -0.070054},
    [118] = {0.538735, -0.291010},
    [119] = {0.609944, 0.590973},
    [120] = {-0.463240, 0.010302},
    [121] = {-0.047718, 0.741086},
    [122] = {0.308590, -0.322179},
    [123] = {-0.291173, 0.256367},
    [124] = {0.287413, -0.510402},
    [125] = {0.864716, 0.158126},
    [126] = {0.572344, 0.561319},
    [127] = {-0.090544, 0.332633},
    [128] = {0.644714, 0.196736},
    [129] = {-0.204198, 0.603049},
    [130] = {-0.504277, -0.641931},
    [131] = {0.218554, 0.343778},
    [132] = {0.466971, 0.217517},
    [133] = {-0.400880, -0.299746},
    [134] = {-0.582451, 0.591832},
    [135] = {0.421843, 0.118453},
    [136] = {-0.215617, -0.037630},
    [137] = {0.341048, -0.283902},
    [138] = {-0.246495, -0.138214},
    [139] = {0.214287, -0.196102},
    [140] = {0.809797, -0.498168},
    [141] = {-0.115958, -0.260677},
    [142] = {-0.025448, 0.043173},
    [143] = {-0.416803, -0.180813},
    [144] = {-0.782066, 0.335273},
    [145] = {0.192178, -0.151171},
    [146] = {0.109733, 0.165085},
    [147] = {-0.617935, -0.274392},
    [148] = {0.283301, 0.171837},
    [149] = {-0.150202, 0.048709},
    [150] = {-0.179954, -0.288559},
    [151] = {-0.288267, -0.134894},
    [152] = {-0.049203, 0.231717},
    [153] = {-0.065761, 0.495457},
    [154] = {0.082018, -0.457869},
    [155] = {-0.159553, 0.032173},
    [156] = {0.508305, -0.090690},
    [157] = {0.232269, -0.338245},
    [158] = {-0.374490, -0.480945},
    [159] = {-0.541244, 0.194144},
    [160] = {-0.040063, -0.073532},
    [161] = {0.136516, -0.167617},
    [162] = {-0.237350, 0.456912},
    [163] = {-0.446604, -0.494381},
    [164] = {0.078626, -0.020068},
    [165] = {0.163208, 0.600330},
    [166] = {-0.886186, -0.345326},
    [167] = {-0.732948, -0.689349},
    [168] = {0.460564, -0.719006},
    [169] = {-0.033688, -0.333340},
    [170] = {-0.325414, -0.111704},
    [171] = {0.010928, 0.723791},
    [172] = {0.713581, -0.077733},
    [173] = {-0.050912, -0.444684},
    [174] = {-0.268509, 0.381144},
    [175] = {-0.175387, 0.147070},
    [176] = {-0.429779, 0.144737},
    [177] = {-0.054564, 0.821354},
    [178] = {0.003205, 0.178130},
    [179] = {-0.552814, 0.199046},
    [180] = {0.225919, -0.195013},
    [181] = {0.056040, -0.393974},
    [182] = {-0.505988, 0.075184},
    [183] = {-0.510223, 0.156271},
    [184] = {-0.209616, 0.111174},
    [185] = {-0.605132, -0.117104},
    [186] = {0.412433, -0.035510},
    [187] = {-0.573947, -0.691295},
    [188] = {-0.712686, 0.021719},
    [189] = {-0.643297, 0.145307},
    [190] = {0.245038, 0.343062},
    [191] = {-0.235623, -0.159307},
    [192] = {-0.834004, 0.088725},
    [193] = {0.121377, 0.671713},
    [194] = {0.528614, 0.607035},
    [195] = {-0.285699, -0.111312},
    [196] = {0.603385, 0.401094},
    [197] = {0.632098, -0.439659},
    [198] = {0.681016, -0.242436},
    [199] = {-0.261709, 0.304265},
    [200] = {-0.653737, -0.199245},
    [201] = {-0.435512, -0.762978},
    [202] = {0.701105, 0.389527},
    [203] = {0.093495, -0.148484},
    [204] = {0.715218, 0.638291},
    [205] = {-0.055431, -0.085173},
    [206] = {-0.727438, 0.889783},
    [207] = {-0.007230, -0.519183},
    [208] = {-0.359615, 0.058657},
    [209] = {0.294681, 0.601155},
    [210] = {0.226879, -0.255430},
    [211] = {-0.307847, -0.617373},
    [212] = {0.340916, -0.780086},
    [213] = {-0.028277, 0.610455},
    [214] = {-0.365067, 0.323311},
    [215] = {0.001059, -0.270451},
    [216] = {0.304025, 0.047478},
    [217] = {0.297389, 0.383859},
    [218] = {0.288059, 0.262816},
    [219] = {-0.889315, 0.533731},
    [220] = {0.215887, 0.678889},
    [221] = {0.287135, 0.343899},
    [222] = {0.423951, 0.672285},
    [223] = {0.411912, -0.812886},
    [224] = {0.081615, -0.497358},
    [225] = {-0.051963, -0.117891},
    [226] = {-0.062387, 0.331698},
    [227] = {0.020458, -0.734125},
    [228] = {-0.160176, 0.196321},
    [229] = {0.044898, -0.024032},
    [230] = {-0.153162, 0.930951},
    [231] = {-0.015084, 0.233476},
    [232] = {0.395043, 0.645227},
    [233] = {-0.232095, 0.283834},
    [234] = {-0.507699, 0.317122},
    [235] = {-0.606604, -0.227259},
    [236] = {0.526430, -0.408765},
    [237] = {0.304079, 0.135680},
    [238] = {-0.134042, 0.508741},
    [239] = {-0.276770, 0.383958},
    [240] = {-0.298963, -0.233668},
    [241] = {0.171889, 0.697367},
    [242] = {-0.292571, -0.317604},
    [243] = {0.587806, 0.115584},
    [244] = {-0.346690, -0.098320},
    [245] = {0.956701, -0.040982},
    [246] = {0.040838, 0.595304},
    [247] = {0.365201, -0.519547},
    [248] = {-0.397271, -0.090567},
    [249] = {-0.124873, -0.356800},
    [250] = {-0.122144, 0.617725},
    [251] = {0.191266, -0.197764},
    [252] = {-0.178092, 0.503667},
    [253] = {0.103221, 0.547538},
    [254] = {0.019524, 0.621226},
    [255] = {0.663918, -0.573476}
}