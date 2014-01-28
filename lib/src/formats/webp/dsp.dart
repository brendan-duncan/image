part of image;

class DSP {
  DSP() {
    _initTables();
  }

  void transformOne(MemPtr src, MemPtr dst) {
    Data.Int16List C = new Data.Int16List(4 * 4);
    int si = 0;
    int di = 0;
    int tmp = 0;
    for (int i = 0; i < 4; ++i) { // vertical pass
      final int a = src[si] + src[si + 8]; // [-4096, 4094]
      final int b = src[si] - src[si + 8]; // [-4095, 4095]
      final int c = _mul(src[si + 4], kC2) - _mul(src[si + 12], kC1); // [-3783, 3783]
      final int d = _mul(src[si + 4], kC1) + _mul(src[si + 12], kC2); // [-3785, 3781]
      C[tmp++] = a + d;   // [-7881, 7875]
      C[tmp++] = b + c;   // [-7878, 7878]
      C[tmp++] = b - c;   // [-7878, 7878]
      C[tmp++] = a - d;   // [-7877, 7879]
      si++;
    }

    // Each pass is expanding the dynamic range by ~3.85 (upper bound).
    // The exact value is (2. + (kC1 + kC2) / 65536).
    // After the second pass, maximum interval is [-3794, 3794], assuming
    // an input in [-2048, 2047] interval. We then need to add a dst value
    // in the [0, 255] range.
    // In the worst case scenario, the input to clip_8b() can be as large as
    // [-60713, 60968].
    tmp = 0;
    for (int i = 0; i < 4; ++i) { // horizontal pass
      final int dc = C[tmp] + 4;
      final int a =  dc +  C[tmp + 8];
      final int b =  dc -  C[tmp + 8];
      final int c = _mul(C[tmp + 4], kC2) - _mul(C[tmp + 12], kC1);
      final int d = _mul(C[tmp + 4], kC1) + _mul(C[tmp + 12], kC2);
      _store(dst, di, 0, 0, a + d);
      _store(dst, di, 1, 0, b + c);
      _store(dst, di, 2, 0, b - c);
      _store(dst, di, 3, 0, a - d);
      tmp++;
      di += VP8.BPS;
    }
  }


  void transform(MemPtr src, MemPtr dst, bool doTwo) {
    transformOne(src, dst);
    if (doTwo) {
      transformOne(new MemPtr(src, 16), new MemPtr(dst, 4));
    }
  }

  void transformUV(MemPtr src, MemPtr dst) {
    transform(src, dst, true);
    transform(new MemPtr(src, 2 * 16), new MemPtr(dst, 4 * VP8.BPS), true);
  }

  void transformDC(MemPtr src, MemPtr dst) {
    final int DC = src[0] + 4;
    for (int j = 0; j < 4; ++j) {
      for (int i = 0; i < 4; ++i) {
        _store(dst, 0, i, j, DC);
      }
    }
  }

  void transformDCUV(MemPtr src, MemPtr dst) {
    if (src[0 * 16] != 0) {
      transformDC(src, dst);
    }
    if (src[1 * 16] != 0) {
      transformDC(new MemPtr(src, 1 * 16), new MemPtr(dst, 4));
    }
    if (src[2 * 16] != 0) {
      transformDC(new MemPtr(src, 2 * 16), new MemPtr(dst, 4 * VP8.BPS));
    }
    if (src[3 * 16] != 0) {
      transformDC(new MemPtr(src, 3 * 16), new MemPtr(dst, 4 * VP8.BPS + 4));
    }
  }

  /**
   * Simplified transform when only in[0], in[1] and in[4] are non-zero
   */
  void transformAC3(MemPtr src, MemPtr dst) {
    final int a = src[0] + 4;
    final int c4 = _mul(src[4], kC2);
    final int d4 = _mul(src[4], kC1);
    final int c1 = _mul(src[1], kC2);
    final int d1 = _mul(src[1], kC1);
    _store2(dst, 0, a + d4, d1, c1);
    _store2(dst, 1, a + c4, d1, c1);
    _store2(dst, 2, a - c4, d1, c1);
    _store2(dst, 3, a - d4, d1, c1);
  }

  static int AVG3(a, b, c) => (((a) + 2 * (b) + (c) + 2) >> 2);
  static int AVG2(a, b) => (((a) + (b) + 1) >> 1);

  static void VE4(MemPtr dst) { // vertical
    int top = -VP8.BPS; // dst +
    final List<int> vals = [
       AVG3(dst[top - 1], dst[top],     dst[top + 1]),
       AVG3(dst[top],     dst[top + 1], dst[top + 2]),
       AVG3(dst[top + 1], dst[top + 2], dst[top + 3]),
       AVG3(dst[top + 2], dst[top + 3], dst[top + 4])];

    for (int i = 0; i < 4; ++i) {
      dst.memcpy(i * VP8.BPS, 4, vals);
    }
  }

  static void HE4(MemPtr dst) { // horizontal
    final int A = dst[-1 - VP8.BPS];
    final int B = dst[-1];
    final int C = dst[-1 + VP8.BPS];
    final int D = dst[-1 + 2 * VP8.BPS];
    final int E = dst[-1 + 3 * VP8.BPS];

    Data.Uint32List d32 = dst.toUint32List();
    d32[0] = 0x01010101 * AVG3(A, B, C);
    d32[1 * VP8.BPS] = 0x01010101 * AVG3(B, C, D);
    d32[2 * VP8.BPS] = 0x01010101 * AVG3(C, D, E);
    d32[3 * VP8.BPS] = 0x01010101 * AVG3(D, E, E);
  }

  static void DC4(MemPtr dst) {   // DC
    int dc = 4;
    for (int i = 0; i < 4; ++i) {
      dc += dst[i - VP8.BPS] + dst[-1 + i * VP8.BPS];
    }
    dc >>= 3;
    for (int i = 0; i < 4; ++i) {
      dst.memset(i * VP8.BPS, 4, dc);
    }
  }

  static void trueMotion(MemPtr dst, int size) {
    int di = 0;
    int top = -VP8.BPS; // dst +
    int clip0 = 255 - dst[top - 1]; // clip1 +

    for (int y = 0; y < size; ++y) {
      int clip = clip0 + dst[-1];
      for (int x = 0; x < size; ++x) {
        dst[di + x] = clip1[clip + dst[top + x]];
      }

      di += VP8.BPS;
    }
  }

  static void TM4(MemPtr dst) {
    trueMotion(dst, 4);
  }

  static void TM8uv(MemPtr dst) {
    trueMotion(dst, 8);
  }

  static void TM16(MemPtr dst) {
    trueMotion(dst, 16);
  }

  static int DST(x, y) => x + y * VP8.BPS;

  static void RD4(MemPtr dst) {   // Down-right
    final int I = dst[-1 + 0 * VP8.BPS];
    final int J = dst[-1 + 1 * VP8.BPS];
    final int K = dst[-1 + 2 * VP8.BPS];
    final int L = dst[-1 + 3 * VP8.BPS];
    final int X = dst[-1 - VP8.BPS];
    final int A = dst[0 - VP8.BPS];
    final int B = dst[1 - VP8.BPS];
    final int C = dst[2 - VP8.BPS];
    final int D = dst[3 - VP8.BPS];

    dst[DST(0, 3)] = AVG3(J, K, L);
    dst[DST(0, 2)] = dst[DST(1, 3)] = AVG3(I, J, K);
    dst[DST(0, 1)] = dst[DST(1, 2)] = dst[DST(2, 3)] = AVG3(X, I, J);
    dst[DST(0, 0)] = dst[DST(1, 1)] = dst[DST(2, 2)] = dst[DST(3, 3)] = AVG3(A, X, I);
    dst[DST(1, 0)] = dst[DST(2, 1)] = dst[DST(3, 2)] = AVG3(B, A, X);
    dst[DST(2, 0)] = dst[DST(3, 1)] = AVG3(C, B, A);
    dst[DST(3, 0)] = AVG3(D, C, B);
  }

  static void LD4(MemPtr dst) {   // Down-Left
    final int A = dst[0 - VP8.BPS];
    final int B = dst[1 - VP8.BPS];
    final int C = dst[2 - VP8.BPS];
    final int D = dst[3 - VP8.BPS];
    final int E = dst[4 - VP8.BPS];
    final int F = dst[5 - VP8.BPS];
    final int G = dst[6 - VP8.BPS];
    final int H = dst[7 - VP8.BPS];
    dst[DST(0, 0)] = AVG3(A, B, C);
    dst[DST(1, 0)] = dst[DST(0, 1)] = AVG3(B, C, D);
    dst[DST(2, 0)] = dst[DST(1, 1)] = dst[DST(0, 2)] = AVG3(C, D, E);
    dst[DST(3, 0)] = dst[DST(2, 1)] = dst[DST(1, 2)] = dst[DST(0, 3)] = AVG3(D, E, F);
    dst[DST(3, 1)] = dst[DST(2, 2)] = dst[DST(1, 3)] = AVG3(E, F, G);
    dst[DST(3, 2)] = dst[DST(2, 3)] = AVG3(F, G, H);
    dst[DST(3, 3)] = AVG3(G, H, H);
  }

  static void VR4(MemPtr dst) {   // Vertical-Right
    final int I = dst[-1 + 0 * VP8.BPS];
    final int J = dst[-1 + 1 * VP8.BPS];
    final int K = dst[-1 + 2 * VP8.BPS];
    final int X = dst[-1 - VP8.BPS];
    final int A = dst[0 - VP8.BPS];
    final int B = dst[1 - VP8.BPS];
    final int C = dst[2 - VP8.BPS];
    final int D = dst[3 - VP8.BPS];
    dst[DST(0, 0)] = dst[DST(1, 2)] = AVG2(X, A);
    dst[DST(1, 0)] = dst[DST(2, 2)] = AVG2(A, B);
    dst[DST(2, 0)] = dst[DST(3, 2)] = AVG2(B, C);
    dst[DST(3, 0)] = AVG2(C, D);

    dst[DST(0, 3)] = AVG3(K, J, I);
    dst[DST(0, 2)] = AVG3(J, I, X);
    dst[DST(0, 1)] = dst[DST(1, 3)] = AVG3(I, X, A);
    dst[DST(1, 1)] = dst[DST(2, 3)] = AVG3(X, A, B);
    dst[DST(2, 1)] = dst[DST(3, 3)] = AVG3(A, B, C);
    dst[DST(3, 1)] = AVG3(B, C, D);
  }

  static void VL4(MemPtr dst) {   // Vertical-Left
    final int A = dst[0 - VP8.BPS];
    final int B = dst[1 - VP8.BPS];
    final int C = dst[2 - VP8.BPS];
    final int D = dst[3 - VP8.BPS];
    final int E = dst[4 - VP8.BPS];
    final int F = dst[5 - VP8.BPS];
    final int G = dst[6 - VP8.BPS];
    final int H = dst[7 - VP8.BPS];
    dst[DST(0, 0)] = AVG2(A, B);
    dst[DST(1, 0)] = dst[DST(0, 2)] = AVG2(B, C);
    dst[DST(2, 0)] = dst[DST(1, 2)] = AVG2(C, D);
    dst[DST(3, 0)] = dst[DST(2, 2)] = AVG2(D, E);

    dst[DST(0, 1)] = AVG3(A, B, C);
    dst[DST(1, 1)] = dst[DST(0, 3)] = AVG3(B, C, D);
    dst[DST(2, 1)] = dst[DST(1, 3)] = AVG3(C, D, E);
    dst[DST(3, 1)] = dst[DST(2, 3)] = AVG3(D, E, F);
    dst[DST(3, 2)] = AVG3(E, F, G);
    dst[DST(3, 3)] = AVG3(F, G, H);
  }

  static void HU4(MemPtr dst) {   // Horizontal-Up
    final int I = dst[-1 + 0 * VP8.BPS];
    final int J = dst[-1 + 1 * VP8.BPS];
    final int K = dst[-1 + 2 * VP8.BPS];
    final int L = dst[-1 + 3 * VP8.BPS];
    dst[DST(0, 0)] = AVG2(I, J);
    dst[DST(2, 0)] = dst[DST(0, 1)] = AVG2(J, K);
    dst[DST(2, 1)] = dst[DST(0, 2)] = AVG2(K, L);
    dst[DST(1, 0)] = AVG3(I, J, K);
    dst[DST(3, 0)] = dst[DST(1, 1)] = AVG3(J, K, L);
    dst[DST(3, 1)] = dst[DST(1, 2)] = AVG3(K, L, L);
    dst[DST(3, 2)] = dst[DST(2, 2)] = dst[DST(0, 3)] = dst[DST(1, 3)] =
                     dst[DST(2, 3)] = dst[DST(3, 3)] = L;
  }

  static void HD4(MemPtr dst) {  // Horizontal-Down
    final int I = dst[-1 + 0 * VP8.BPS];
    final int J = dst[-1 + 1 * VP8.BPS];
    final int K = dst[-1 + 2 * VP8.BPS];
    final int L = dst[-1 + 3 * VP8.BPS];
    final int X = dst[-1 - VP8.BPS];
    final int A = dst[0 - VP8.BPS];
    final int B = dst[1 - VP8.BPS];
    final int C = dst[2 - VP8.BPS];

    dst[DST(0, 0)] = dst[DST(2, 1)] = AVG2(I, X);
    dst[DST(0, 1)] = dst[DST(2, 2)] = AVG2(J, I);
    dst[DST(0, 2)] = dst[DST(2, 3)] = AVG2(K, J);
    dst[DST(0, 3)] = AVG2(L, K);

    dst[DST(3, 0)] = AVG3(A, B, C);
    dst[DST(2, 0)] = AVG3(X, A, B);
    dst[DST(1, 0)] = dst[DST(3, 1)] = AVG3(I, X, A);
    dst[DST(1, 1)] = dst[DST(3, 2)] = AVG3(J, I, X);
    dst[DST(1, 2)] = dst[DST(3, 3)] = AVG3(K, J, I);
    dst[DST(1, 3)] = AVG3(L, K, J);
  }

  static void VE16(MemPtr dst) { // vertical
    for (int j = 0; j < 16; ++j) {
      dst.memcpy(j * VP8.BPS, 16, dst, -VP8.BPS);
    }
  }

  static void HE16(MemPtr dst) { // horizontal
    int di = 0;
    for (int j = 16; j > 0; --j) {
      dst.memset(di, 16, dst[di - 1]);
      di += VP8.BPS;
    }
  }

  static void Put16(int v, MemPtr dst) {
    for (int j = 0; j < 16; ++j) {
      dst.memset(j * VP8.BPS, 16, v);
    }
  }

  static void DC16(MemPtr dst) { // DC
    int DC = 16;
    for (int j = 0; j < 16; ++j) {
      DC += dst[-1 + j * VP8.BPS] + dst[j - VP8.BPS];
    }
    Put16(DC >> 5, dst);
  }

  // DC with top samples not available
  static void DC16NoTop(MemPtr dst) {
    int DC = 8;
    for (int j = 0; j < 16; ++j) {
      DC += dst[-1 + j * VP8.BPS];
    }
    Put16(DC >> 4, dst);
  }

  // DC with left samples not available
  static void DC16NoLeft(MemPtr dst) {
    int DC = 8;
    for (int i = 0; i < 16; ++i) {
      DC += dst[i - VP8.BPS];
    }
    Put16(DC >> 4, dst);
  }

  // DC with no top and left samples
  static void DC16NoTopLeft(MemPtr dst) {
    Put16(0x80, dst);
  }

  static void VE8uv(MemPtr dst) {    // vertical
    for (int j = 0; j < 8; ++j) {
      dst.memcpy(j * VP8.BPS, 8, dst, -VP8.BPS);
    }
  }

  static void HE8uv(MemPtr dst) {    // horizontal
    int di = 0;
    for (int j = 0; j < 8; ++j) {
      dst.memset(di, 8, dst[di - 1]);
      di += VP8.BPS;
    }
  }

// helper for chroma-DC predictions
  static void Put8x8uv(int value, MemPtr dst) {
    for (int j = 0; j < 8; ++j) {
      dst.memset(j * VP8.BPS, 8, value);
    }
  }

  static void DC8uv(MemPtr dst) {     // DC
    int dc0 = 8;
    for (int i = 0; i < 8; ++i) {
      dc0 += dst[i - VP8.BPS] + dst[-1 + i * VP8.BPS];
    }
    Put8x8uv(dc0 >> 4, dst);
  }

  static void DC8uvNoLeft(MemPtr dst) {   // DC with no left samples
    int dc0 = 4;
    for (int i = 0; i < 8; ++i) {
      dc0 += dst[i - VP8.BPS];
    }
    Put8x8uv(dc0 >> 3, dst);
  }

  static void DC8uvNoTop(MemPtr dst) {  // DC with no top samples
    int dc0 = 4;
    for (int i = 0; i < 8; ++i) {
      dc0 += dst[-1 + i * VP8.BPS];
    }
    Put8x8uv(dc0 >> 3, dst);
  }

  static void DC8uvNoTopLeft(MemPtr dst) {    // DC with nothing
    Put8x8uv(0x80, dst);
  }

  static const List PredLuma4 = const [
      DC4, TM4, VE4, HE4, RD4, VR4, LD4, VL4, HD4, HU4 ];

  static const List PredLuma16 = const [
      DC16, TM16, VE16, HE16, DC16NoTop, DC16NoLeft, DC16NoTopLeft ];

  static const List PredChroma8 = const [
      DC8uv, TM8uv, VE8uv, HE8uv, DC8uvNoTop, DC8uvNoLeft, DC8uvNoTopLeft ];


  static const int kC1 = 20091 + (1 << 16);
  static const int kC2 = 35468;

  static int _mul(int a, int b) => ((a * b) >> 16);

  static void _store(MemPtr dst, int di, int x, int y, int v) {
    dst[di + x + y * VP8.BPS] = _clip8b(dst[di + x + y * VP8.BPS] + (v >> 3));
  }

  static void _store2(MemPtr dst, int y, int dc, int d, int c) {
    _store(dst, 0, 0, y, dc + (d));
    _store(dst, 0, 1, y, dc + (c));
    _store(dst, 0, 2, y, dc - (c));
    _store(dst, 0, 3, y, dc - (d));
  }

  /// abs(i)
  static Data.Uint8List abs0 = new Data.Uint8List(255 + 255 + 1);
  /// abs(i)>>1
  static Data.Uint8List abs1 = new Data.Uint8List(255 + 255 + 1);
  /// clips [-1020, 1020] to [-128, 127]
  static Data.Int8List sclip1 = new Data.Int8List(1020 + 1020 + 1);
  /// clips [-112, 112] to [-16, 15]
  static Data.Int8List sclip2 = new Data.Int8List(112 + 112 + 1);
  /// clips [-255,510] to [0,255]
  static Data.Uint8List clip1 = new Data.Uint8List(255 + 510 + 1);

  static void _initTables() {
    if (!_tablesInitialized) {
      for (int i = -255; i <= 255; ++i) {
        abs0[255 + i] = (i < 0) ? -i : i;
        abs1[255 + i] = abs0[255 + i] >> 1;
      }
      for (int i = -1020; i <= 1020; ++i) {
        sclip1[1020 + i] = (i < -128) ? -128 : (i > 127) ? 127 : i;
      }
      for (int i = -112; i <= 112; ++i) {
        sclip2[112 + i] = (i < -16) ? -16 : (i > 15) ? 15 : i;
      }
      for (int i = -255; i <= 255 + 255; ++i) {
        clip1[255 + i] = (i < 0) ? 0 : (i > 255) ? 255 : i;
      }
      _tablesInitialized = true;
    }
  }

  static int _clip8b(int v) {
    return ((v & ~0xff) == 0) ? v : (v < 0) ? 0 : 255;
  }

  static bool _tablesInitialized = false;
}
