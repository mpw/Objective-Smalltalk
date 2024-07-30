#!env stui
#-<void>gezira
framework:Gezira load.

class  Snowflake : GeziraShape
{
  -initWithCoords:coords windowSize:size
  {
    self ← super init.
    this:x ← 0 to: size x | random.
    this:y ← 0 to: size y | random.
    this:dy ← 0.5 to: 3.0  | random.
    this:scale ← 0.2 to: 0.7 | random.
    this:angle ← 0 to: 300 | random.
    this:dangle ← -0.1 to: 0.1 | random.
    this:windowSize ← size.
    this:color ← NSColor colorWithRed: 0.8 green: 0.9 blue: 1.0 alpha: 0.7 .
    this:coords ← coords.
    self.
  }
  -<void>renderWithParent:parent on:bitmap {
     transform ← MPWTransformBeziers stream.
     transform setMatrix: self transformationMatrix.
     filters ← [
	 transform,
         (parent clipToSize: bitmap pixelsWide @ bitmap pixelsHigh),
         (parent rasterize),
         (parent compositorImage: bitmap color: this:color ),
     ].
     pipeline ← parent pipeline:filters.
     pipeline writeObject: self coords.
  }

  -transformationMatrix {

    var m.
    m ← MPWMatrix matrixIdentity.
    m ← m matrixTranslatedBy: this:x y: this:y.
    m ← m matrixRotatedBy: this:angle.
    m ← m matrixScaledBy: this:scale.
    m.
   }
   -<void>update {
      this:y ← this:y + this:dy.
      this:angle ← this:angle + this:dangle.
      (this:y > (this:windowSize y + 10)) ifTrue: {
          this:y ← -10.
      }.
   }
}.

coords ← #MPWRealArray[ 
    16.8063, -26.3434, 17.7989, -25.3508, 16.8009, -22.7501,
    16.8009, -22.7501, 16.3070, -21.4629, 16.5456, -21.1093,
    16.5456, -21.1093, 16.6644, -20.9332, 16.9645, -20.9931,
    16.9645, -20.9931, 17.2654, -21.0532, 17.7455, -21.3499,
    17.7455, -21.3499, 18.6092, -21.8837, 19.1487, -21.5293,
    19.1487, -21.5293, 19.6882, -21.1749, 19.6882, -20.0737,
    19.6882, -20.0737, 19.6882, -17.5969, 16.1479, -16.4732,
    16.1479, -16.4732, 14.0548, -15.8089, 13.8003, -15.2770,
    13.8003, -15.2770, 13.6623, -14.9887, 13.9414, -14.6446,
    13.9414, -14.6446, 14.2041, -14.3207, 14.9025, -13.8707,
    14.9025, -13.8707, 16.3494, -12.9382, 16.3133, -12.3628,
    16.3133, -12.3628, 16.2771, -11.7875, 14.7068, -10.7566,
    14.7068, -10.7566, 12.2161, -9.1216, 10.3181, -9.0962,
    10.3181, -9.0962, 8.4202, -9.0707, 7.4644, -6.5800,
    7.4644, -6.5800, 7.0056, -5.3844, 7.6667, -4.7020,
    7.6667, -4.7020, 8.2718, -4.0775, 9.5712, -4.0812,
    9.5712, -4.0812, 12.6401, -4.0898, 14.7238, -6.6005,
    14.7238, -6.6005, 15.9127, -8.0330, 16.8479, -8.1677,
    16.8479, -8.1677, 17.7831, -8.3023, 19.0783, -7.2274,
    19.0783, -7.2274, 20.3558, -6.1671, 21.3969, -6.2071,
    21.3969, -6.2071, 22.4379, -6.2471, 23.8394, -7.4103,
    23.8394, -7.4103, 24.8668, -8.2629, 25.5985, -8.5665,
    25.5985, -8.5665, 25.9438, -8.7099, 26.1336, -8.6820,
    26.1336, -8.6820, 26.2297, -8.6679, 26.2793, -8.6092,
    26.2793, -8.6092, 26.3301, -8.5490, 26.3301, -8.4438,
    26.3301, -8.4438, 26.3301, -5.0516, 28.9388, -3.5917,
    28.9388, -3.5917, 31.2406, -2.3035, 31.1691, -0.4840,
    31.1691, -0.4840, 31.0976, 1.3355, 28.5951, 5.1548,
    28.5951, 5.1548, 26.7219, 8.0136, 25.8517, 8.2511,
    25.8517, 8.2511, 24.9814, 8.4887, 22.9886, 6.6852,
    22.9886, 6.6852, 21.0119, 4.8963, 20.3861, 4.9237,
    20.3861, 4.9237, 19.7603, 4.9510, 19.0285, 6.8582,
    19.0285, 6.8582, 18.2849, 8.7960, 17.6638, 8.8069,
    17.6638, 8.8069, 17.0427, 8.8178, 14.9565, 6.9298,
    14.9565, 6.9298, 11.9546, 4.2131, 8.9762, 4.2131,
    8.9762, 4.2131, 7.1317, 4.2131, 6.9583, 4.6873,
    6.9583, 4.6873, 6.7848, 5.1614, 8.0649, 6.7038,
    8.0649, 6.7038, 10.1320, 9.1945, 12.3214, 9.1945,
    12.3214, 9.1945, 14.7027, 9.1945, 15.6210, 11.1190,
    15.6210, 11.1190, 16.0194, 11.9541, 15.8094, 12.7617,
    15.8094, 12.7617, 15.5824, 13.6348, 14.7001, 14.1801,
    14.7001, 14.1801, 14.1325, 14.5309, 13.9378, 14.8353,
    13.9378, 14.8353, 13.7389, 15.1460, 13.9115, 15.4341,
    13.9115, 15.4341, 14.2467, 15.9936, 16.1479, 16.5970,
    16.1479, 16.5970, 18.7443, 17.4211, 19.5750, 19.1195,
    19.5750, 19.1195, 19.9313, 19.8481, 19.6103, 20.3129,
    19.6103, 20.3129, 19.2615, 20.8179, 18.2122, 20.8179,
    18.2122, 20.8179, 17.6034, 20.8179, 17.2376, 21.6705,
    17.2376, 21.6705, 16.8717, 22.5231, 16.9669, 23.7204,
    16.9669, 23.7204, 17.1008, 25.4064, 15.8033, 26.0897,
    15.8033, 26.0897, 14.5057, 26.7730, 10.7752, 26.9810,
    10.7752, 26.9810, 6.0003, 27.2472, 5.2937, 26.6088,
    5.2937, 26.6088, 4.5872, 25.9703, 5.2663, 22.0029,
    5.2663, 22.0029, 5.6431, 19.8017, 5.6598, 18.8439,
    5.6598, 18.8439, 5.6678, 18.3914, 5.5838, 18.3574,
    5.5838, 18.3574, 5.5413, 18.3400, 5.4768, 18.4343,
    5.4768, 18.4343, 5.4106, 18.5310, 5.3234, 18.7423,
    5.3234, 18.7423, 4.7144, 20.2184, 4.0071, 20.6781,
    4.0071, 20.6781, 3.3408, 21.1112, 2.7449, 20.5553,
    2.7449, 20.5553, 1.4230, 19.3223, 1.4230, 15.1042,
    1.4230, 15.1042, 1.4230, 9.3905, -0.2375, 8.3643,
    -0.2375, 8.3643, -0.9317, 7.9353, -1.3335, 8.1224,
    -1.3335, 8.1224, -1.7565, 8.3193, -1.9463, 9.2332,
    -1.9463, 9.2332, -2.3005, 10.9392, -1.9242, 16.4867,
    -1.9242, 16.4867, -1.7256, 19.4124, -2.2139, 20.1385,
    -2.2139, 20.1385, -2.7021, 20.8646, -4.4236, 20.2040,
    -4.4236, 20.2040, -5.3338, 19.8547, -5.8063, 19.8228,
    -5.8063, 19.8228, -6.3221, 19.7879, -6.5134, 20.1092,
    -6.5134, 20.1092, -6.8561, 20.6848, -6.2197, 23.2205,
    -6.2197, 23.2205, -5.4941, 26.1115, -6.2628, 26.6654,
    -6.2628, 26.6654, -7.0315, 27.2192, -11.4315, 26.9754,
    -11.4315, 26.9754, -14.6467, 26.7972, -16.1596, 26.1096,
    -16.1596, 26.1096, -17.6725, 25.4220, -17.6725, 24.1388,
    -17.6725, 24.1388, -17.6725, 21.6481, -20.1399, 20.1010,
    -20.1399, 20.1010, -20.9108, 19.6177, -21.1498, 19.2429,
    -21.1498, 19.2429, -21.4069, 18.8398, -21.1359, 18.4415,
    -21.1359, 18.4415, -20.6423, 17.7160, -17.6492, 16.4398,
    -17.6492, 16.4398, -15.6040, 15.5678, -14.7573, 14.9247,
    -14.7573, 14.9247, -14.3575, 14.6212, -14.3520, 14.4467,
    -14.3520, 14.4467, -14.3492, 14.3583, -14.4510, 14.3090,
    -14.4510, 14.3090, -14.5554, 14.2584, -14.7667, 14.2508,
    -14.7667, 14.2508, -16.0660, 14.2039, -16.5691, 13.6374,
    -16.5691, 13.6374, -17.0373, 13.1100, -16.7011, 12.2910,
    -16.7011, 12.2910, -15.9365, 10.4285, -12.6911, 9.1945,
    -12.6911, 9.1945, -8.5399, 7.6163, -8.5399, 5.9147,
    -8.5399, 5.9147, -8.5399, 4.9917, -9.2468, 4.5611,
    -9.2468, 4.5611, -9.9051, 4.1601, -10.9785, 4.2876,
    -10.9785, 4.2876, -13.4170, 4.5773, -15.1818, 6.7038,
    -15.1818, 6.7038, -17.2242, 9.1648, -18.6937, 9.0888,
    -18.6937, 9.0888, -19.3865, 9.0531, -19.7678, 8.3917,
    -19.7678, 8.3917, -20.1632, 7.7061, -20.1632, 6.4465,
    -20.1632, 6.4465, -20.1632, 5.4062, -20.2449, 5.0202,
    -20.2449, 5.0202, -20.2958, 4.7792, -20.3888, 4.6657,
    -20.3888, 4.6657, -20.4850, 4.5484, -20.6388, 4.5510,
    -20.6388, 4.5510, -21.1144, 4.5592, -23.2585, 6.4995,
    -23.2585, 6.4995, -25.4562, 8.4884, -26.3237, 8.2555,
    -26.3237, 8.2555, -27.1911, 8.0226, -29.2418, 4.8929,
    -29.2418, 4.8929, -32.8702, -0.6449, -27.2854, -8.9222,
    -27.2854, -8.9222, -27.1923, -9.0603, -26.8440, -8.9490,
    -26.8440, -8.9490, -26.5078, -8.8416, -25.9821, -8.5181,
    -25.9821, -8.5181, -24.8684, -7.8328, -23.4944, -6.5892,
    -23.4944, -6.5892, -21.2502, -4.5582, -20.7067, -4.5148,
    -20.7067, -4.5148, -20.5369, -4.5012, -20.4282, -4.6082,
    -20.4282, -4.6082, -20.3227, -4.7121, -20.2629, -4.9421,
    -20.2629, -4.9421, -20.1632, -5.3259, -20.1632, -6.3227,
    -20.1632, -6.3227, -20.1632, -7.5823, -19.7678, -8.2679,
    -19.7678, -8.2679, -19.3865, -8.9293, -18.6937, -8.9650,
    -18.6937, -8.9650, -17.2242, -9.0410, -15.1818, -6.5800,
    -15.1818, -6.5800, -13.1147, -4.0893, -9.5819, -4.1446,
    -9.5819, -4.1446, -8.0423, -4.1686, -7.6019, -4.2262,
    -7.6019, -4.2262, -7.2663, -4.2701, -7.1145, -4.3531,
    -7.1145, -4.3531, -6.9551, -4.4401, -6.9655, -4.5868,
    -6.9655, -4.5868, -6.9938, -4.9877, -9.8075, -7.3346,
    -9.8075, -7.3346, -13.5659, -10.4694, -15.6191, -11.3041,
    -15.6191, -11.3041, -16.7771, -11.7748, -16.7006, -12.3216,
    -16.7006, -12.3216, -16.6241, -12.8683, -15.2684, -13.8117,
    -15.2684, -13.8117, -14.5195, -14.3327, -14.2754, -14.6893,
    -14.2754, -14.6893, -14.0134, -15.0721, -14.2475, -15.3790,
    -14.2475, -15.3790, -14.6746, -15.9388, -17.4163, -16.6270,
    -17.4163, -16.6270, -20.4849, -17.3971, -21.2071, -19.6020,
    -21.2071, -19.6020, -21.5026, -20.5042, -20.9491, -20.9641,
    -20.9491, -20.9641, -20.3358, -21.4736, -18.9057, -21.1743,
    -18.9057, -21.1743, -18.2157, -21.0299, -17.7889, -21.7606,
    -17.7889, -21.7606, -17.3621, -22.4913, -17.4528, -23.6617,
    -17.4528, -23.6617, -17.5781, -25.2795, -16.2840, -25.9644,
    -16.2840, -25.9644, -14.9899, -26.6492, -11.4315, -26.8483,
    -11.4315, -26.8483, -7.0311, -27.0944, -6.2625, -26.5413,
    -6.2625, -26.5413, -5.4940, -25.9880, -6.2197, -23.0967,
    -6.2197, -23.0967, -6.8550, -20.5656, -6.5137, -19.9873,
    -6.5137, -19.9873, -6.3235, -19.6650, -5.8107, -19.6981,
    -5.8107, -19.6981, -5.3404, -19.7284, -4.4364, -20.0753,
    -4.4364, -20.0753, -3.5146, -20.4290, -3.0272, -20.4124,
    -3.0272, -20.4124, -2.4901, -20.3941, -2.2523, -19.9329,
    -2.2523, -19.9329, -1.8302, -19.1144, -2.1761, -15.6924,
    -2.1761, -15.6924, -2.7282, -10.2301, -0.6526, -9.5121,
    -0.6526, -9.5121, -0.1235, -9.3290, 0.2656, -9.5565,
    0.2656, -9.5565, 0.6565, -9.7850, 0.9131, -10.4319,
    0.9131, -10.4319, 1.4230, -11.7170, 1.4230, -14.7440,
    1.4230, -14.7440, 1.4230, -19.1388, 2.7236, -20.4008,
    2.7236, -20.4008, 3.3172, -20.9767, 4.0093, -20.5495,
    4.0093, -20.5495, 4.7393, -20.0988, 5.4162, -18.6185,
    5.4162, -18.6185, 5.5129, -18.4072, 5.5876, -18.3117,
    5.5876, -18.3117, 5.6605, -18.2187, 5.7104, -18.2384,
    5.7104, -18.2384, 5.8087, -18.2773, 5.8096, -18.7378,
    5.8096, -18.7378, 5.8115, -19.7142, 5.4227, -21.9394,
    5.4227, -21.9394, 4.7390, -25.8532, 5.3881, -26.5946,
    5.3881, -26.5946, 6.0371, -27.3360, 10.1469, -27.3360,
    10.1469, -27.3360, 15.8137, -27.3360, 16.8063, -26.3434
].


demo ← #StrokeDemo{ numberOfShapes: 100, shapeCoords: coords, shapeClass: class:Snowflake  }.
view ← #NSImageView{ frame: (400@400) }.
window ← view openInWindow:'Gezira'.
demo run:view.
shell runInteractiveLoop.