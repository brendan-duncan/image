part of image;

/**
 * Ported from Jeremy Lim's PRTC encoder/decoder,
 * https://bitbucket.org/jthlim/pvrtccompressor
 */
class PvrtcPacket {
  Uint32List rawData;
  int index;

  PvrtcPacket(TypedData data)
      : rawData = new Uint32List.view(data.buffer);

  void setBlock(int x, int y) => setIndex(_getMortonNumber(x, y));

  void setIndex(int i) {
    // A PvrtcPacket uses 2 uint32 values, so get the physical index
    // from the logical index by multiplying by 2.
    index = i << 1;
    // Pull in the values from the raw data.
    _update();
  }

  int get modulationData => rawData[index];

  set modulationData(int x) => rawData[index] = x;

  int get colorData => rawData[index + 1];

  set colorData(int x) => rawData[index + 1] = x;

  int get usePunchthroughAlpha => _usePunchthroughAlpha;

  set usePunchthroughAlpha(int x) {
    _usePunchthroughAlpha = x;
    colorData = _getColorData();
  }

  int get colorA => _colorA;

  set colorA(int x) {
    _colorA = x;
    colorData = _getColorData();
  }

  int get colorAIsOpaque => _colorAIsOpaque;

  set colorAIsOpaque(int x) {
    _colorAIsOpaque = x;
    colorData = _getColorData();
  }

  int get colorB => _colorB;

  set colorB(int x) {
    _colorB = x;
    colorData = _getColorData();
  }

  int get colorBIsOpaque => _colorBIsOpaque;

  set colorBIsOpaque(int x) {
    _colorBIsOpaque = x;
    colorData = _getColorData();
  }

  static BITSCALE_5_TO_8(x) => x << 3;

  static BITSCALE_4_TO_8(x) => x << 4;

  static BITSCALE_3_TO_8(x) => x << 5;

  static BITSCALE_8_TO_4_FLOOR(x) => x >> 4;

  static BITSCALE_8_TO_5_FLOOR(x) => x >> 3;

  static BITSCALE_8_TO_5_CEIL(x) => (x / 8.0).ceil();

  void setColorA(PvrtcColor c) {
    int r = BITSCALE_8_TO_5_FLOOR(c.r);
    int g = BITSCALE_8_TO_5_FLOOR(c.g);
    int b = BITSCALE_8_TO_4_FLOOR(c.b);
    colorA = r << 9 | g << 4 | b;
    colorAIsOpaque = 1;
  }

  void setColorB(PvrtcColor c) {
    int r = BITSCALE_8_TO_5_CEIL(c.r);
    int g = BITSCALE_8_TO_5_CEIL(c.g);
    int b = BITSCALE_8_TO_5_CEIL(c.b);
    colorB = r << 10 | g << 5 | b;
    colorBIsOpaque = 1;
  }

  PvrtcColor getColorA() {
    if(colorAIsOpaque != 0) {
      var r = colorA >> 9;
      var g = colorA >> 4 & 0x1f;
      var b = colorA & 0xf;
      return new PvrtcColor(BITSCALE_5_TO_8(r),
                            BITSCALE_5_TO_8(g),
                            BITSCALE_4_TO_8(b));
    } else {
      var r = (colorA >> 7) & 0xf;
      var g = (colorA >> 3) & 0xf;
      var b = colorA & 7;
      return new PvrtcColor(BITSCALE_4_TO_8(r),
                            BITSCALE_4_TO_8(g),
                            BITSCALE_3_TO_8(b));
    }
  }

  PvrtcColor getColorB() {
    if (colorBIsOpaque != 0) {
      var r = colorB >> 10;
      var g = colorB >> 5 & 0x1f;
      var b = colorB & 0x1f;
      return new PvrtcColor(BITSCALE_5_TO_8(r),
                 BITSCALE_5_TO_8(g),
                 BITSCALE_5_TO_8(b));
    } else {
      var r = colorB >> 8 & 0xf;
      var g = colorB >> 4 & 0xf;
      var b = colorB & 0xf;
      return new PvrtcColor(BITSCALE_4_TO_8(r),
                 BITSCALE_4_TO_8(g),
                 BITSCALE_4_TO_8(b));
    }
  }

  int _usePunchthroughAlpha = 0;
  int _colorA = 0;
  int _colorAIsOpaque = 0;
  int _colorB = 0;
  int _colorBIsOpaque = 0;

  int _getColorData() =>
      ((usePunchthroughAlpha & 1)) |
      ((colorA & BITS_14) << 1) |
      ((colorAIsOpaque & 1) << 15) |
      ((colorB & BITS_15) << 16) |
      ((colorBIsOpaque & 1) << 31);

  void _update() {
    int x = colorData;
    usePunchthroughAlpha = x & 1;
    colorA = (x >> 1) & BITS_14;
    colorAIsOpaque = (x >> 15) & 1;
    colorB = (x >> 16) & BITS_15;
    colorBIsOpaque = (x >> 31) & 1;
  }

  // Pack 2 16-bit indices into a 32-bit Morton code.
  // From: http://and-what-happened.blogspot.com/2011/08/fast-2d-and-3d-hilbert-curves-and.html
  static int _getMortonNumber(int index1, int index2) {
    index1 &= 0x0000ffff;
    index2 &= 0x0000ffff;
    index1 |= (index1 << 8);
    index2 |= (index2 << 8);
    index1 &= 0x00ff00ff;
    index2 &= 0x00ff00ff;
    index1 |= (index1 << 4);
    index2 |= (index2 << 4);
    index1 &= 0x0f0f0f0f;
    index2 &= 0x0f0f0f0f;
    index1 |= (index1 << 2);
    index2 |= (index2 << 2);
    index1 &= 0x33333333;
    index2 &= 0x33333333;
    index1 |= (index1 << 1);
    index2 |= (index2 << 1);
    index1 &= 0x55555555;
    index2 &= 0x55555555;
    return index1 | (index2 << 1);
  }

  static const BITS_14 = (1 << 14) - 1;
  static const BITS_15 = (1 << 15) - 1;

  static const BILINEAR_FACTORS = const [
    const [ 4, 4, 4, 4 ],
    const [ 2, 6, 2, 6 ],
    const [ 8, 0, 8, 0 ],
    const [ 6, 2, 6, 2 ],

    const [ 2, 2, 6, 6 ],
    const [ 1, 3, 3, 9 ],
    const [ 4, 0, 12, 0 ],
    const [ 3, 1, 9, 3 ],

    const [ 8, 8, 0, 0 ],
    const [ 4, 12, 0, 0 ],
    const [ 16, 0, 0, 0 ],
    const [ 12, 4, 0, 0 ],

    const [ 6, 6, 2, 2 ],
    const [ 3, 9, 1, 3 ],
    const [ 12, 0, 4, 0 ],
    const [ 9, 3, 3, 1 ],
  ];

  // Weights are { colorA, colorB, alphaA, alphaB }
  static const WEIGHTS = const [
    // Weights for Mode=0
    const [ 8, 0, 8, 0 ],
    const [ 5, 3, 5, 3 ],
    const [ 3, 5, 3, 5 ],
    const [ 0, 8, 0, 8 ],

    // Weights for Mode=1
    const [ 8, 0, 8, 0 ],
    const [ 4, 4, 4, 4 ],
    const [ 4, 4, 0, 0 ],
    const [ 0, 8, 0, 8 ],
  ];
}
