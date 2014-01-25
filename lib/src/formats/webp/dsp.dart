part of image;

class DSP {
  DSP() {
    _initTables();

    /*
    VP8VFilter16 = VFilter16;
    VP8HFilter16 = HFilter16;
    VP8VFilter8 = VFilter8;
    VP8HFilter8 = HFilter8;
    VP8VFilter16i = VFilter16i;
    VP8HFilter16i = HFilter16i;
    VP8VFilter8i = VFilter8i;
    VP8HFilter8i = HFilter8i;
    VP8SimpleVFilter16 = SimpleVFilter16;
    VP8SimpleHFilter16 = SimpleHFilter16;
    VP8SimpleVFilter16i = SimpleVFilter16i;
    VP8SimpleHFilter16i = SimpleHFilter16i;*/
  }

  void transformOne(Data.Int16List src, Data.Uint8List dst) {
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


  void transform(Data.Int16List src, Data.Uint8List dst, bool doTwo) {
    transformOne(src, dst);
    if (doTwo) {
      transformOne(new Data.Int16List.view(src.buffer, 16),
                   new Data.Uint8List.view(dst.buffer, 4));
    }
  }

  void TransformUV(Data.Int16List src, Data.Uint8List dst) {
    transform(src, dst, true);
    transform(new Data.Int16List.view(src.buffer, 2 * 16),
              new Data.Uint8List.view(dst.buffer, 4 * VP8.BPS), true);
  }

  void transformDC(Data.Int16List src, Data.Uint8List dst) {
    final int DC = src[0] + 4;
    for (int j = 0; j < 4; ++j) {
      for (int i = 0; i < 4; ++i) {
        _store(dst, 0, i, j, DC);
      }
    }
  }

  void transformDCUV(Data.Int16List src, Data.Uint8List dst) {
    if (src[0 * 16] != 0) {
      transformDC(src, dst);
    }
    if (src[1 * 16] != 0) {
      transformDC(new Data.Int16List.view(src.buffer, 1 * 16),
                  new Data.Uint8List.view(dst.buffer, 4));
    }
    if (src[2 * 16] != 0) {
      transformDC(new Data.Int16List.view(src.buffer, 2 * 16),
                  new Data.Uint8List.view(dst.buffer, 4 * VP8.BPS));
    }
    if (src[3 * 16] != 0) {
      transformDC(new Data.Int16List.view(src.buffer, 3 * 16),
                  new Data.Uint8List.view(dst.buffer, 4 * VP8.BPS + 4));
    }
  }

  /**
   * Simplified transform when only in[0], in[1] and in[4] are non-zero
   */
  void transformAC3(Data.Int16List src, Data.Uint8List dst) {
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

  // on macroblock edges
  /*void vfilter16(Data.Uint8List p, int stride, int thresh, int ithresh,
                 int hev_thresh) {
    filterLoop26(p, stride, 1, 16, thresh, ithresh, hev_thresh);
  }

  void hfilter16(Data.Uint8List p, int stride, int thresh, int ithresh,
                 int hev_thresh) {
    filterLoop26(p, 1, stride, 16, thresh, ithresh, hev_thresh);
  }

  // on three inner edges
  void vfilter16i(Data.Uint8List p, int stride,
                  int thresh, int ithresh, int hev_thresh) {
    for (int k = 3; k > 0; --k) {
      p += 4 * stride;
      filterLoop24(p, stride, 1, 16, thresh, ithresh, hev_thresh);
    }
  }

  void hfilter16i(Data.Uint8List p, int stride,
                  int thresh, int ithresh, int hev_thresh) {
    for (int k = 3; k > 0; --k) {
      p += 4;
      filterLoop24(p, 1, stride, 16, thresh, ithresh, hev_thresh);
    }
  }

  // 8-pixels wide variant, for chroma filtering
  void vfilter8(Data.Uint8List u, Data.Uint8List v, int stride,
                int thresh, int ithresh, int hev_thresh) {
    filterLoop26(u, stride, 1, 8, thresh, ithresh, hev_thresh);
    filterLoop26(v, stride, 1, 8, thresh, ithresh, hev_thresh);
  }

  void hfilter8(Data.Uint8List u, Data.Uint8List v, int stride,
                int thresh, int ithresh, int hev_thresh) {
    filterLoop26(u, 1, stride, 8, thresh, ithresh, hev_thresh);
    filterLoop26(v, 1, stride, 8, thresh, ithresh, hev_thresh);
  }

  void vfilter8i(Data.Uint8List u, Data.Uint8List v, int stride,
                 int thresh, int ithresh, int hev_thresh) {
    filterLoop24(u + 4 * stride, stride, 1, 8, thresh, ithresh, hev_thresh);
    filterLoop24(v + 4 * stride, stride, 1, 8, thresh, ithresh, hev_thresh);
  }

  void hfilter8i(Data.Uint8List u, Data.Uint8List v, int stride,
                 int thresh, int ithresh, int hev_thresh) {
    filterLoop24(u + 4, 1, stride, 8, thresh, ithresh, hev_thresh);
    filterLoop24(v + 4, 1, stride, 8, thresh, ithresh, hev_thresh);
  }

  void filterLoop26(Data.Uint8List p,
                    int hstride, int vstride, int size,
                    int thresh, int ithresh, int hev_thresh) {
    while (size-- > 0) {
      if (needs_filter2(p, hstride, thresh, ithresh)) {
        if (hev(p, hstride, hev_thresh)) {
          do_filter2(p, hstride);
        } else {
          doFilter6(p, hstride);
        }
      }
      p += vstride;
    }
  }

  void filterLoop24(Data.Uint8List p,
                    int hstride, int vstride, int size,
                    int thresh, int ithresh, int hev_thresh) {
    while (size-- > 0) {
      if (needs_filter2(p, hstride, thresh, ithresh)) {
        if (hev(p, hstride, hev_thresh)) {
          doFilter2(p, hstride);
        } else {
          doFilter4(p, hstride);
        }
      }
      p += vstride;
    }
  }*/


  static const int kC1 = 20091 + (1 << 16);
  static const int kC2 = 35468;

  static int _mul(int a, int b) => ((a * b) >> 16);

  static void _store(Data.Uint8List dst, int di, int x, int y, int v) {
    dst[di + x + y * VP8.BPS] = _clip8b(dst[di + x + y * VP8.BPS] + (v >> 3));
  }

  static void _store2(Data.Uint8List dst, int y, int dc, int d, int c) {
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
