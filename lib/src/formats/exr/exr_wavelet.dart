part of image;

class ExrWavelet {
  static void decode(Uint8List input, int si, int nx, int ox, int ny, int oy,
                     int mx) {
    bool w14 = (mx < (1 << 14));
    int n = (nx > ny) ? ny : nx;
    int p = 1;
    int p2;

    // Search max level
    while (p <= n) {
      p <<= 1;
    }

    p >>= 1;
    p2 = p;
    p >>= 1;

    List<int> a_b = [0, 0];

    // Hierarchical loop on smaller dimension n
    while (p >= 1) {
      int py = si;
      int ey = si + oy * (ny - p2);
      int oy1 = oy * p;
      int oy2 = oy * p2;
      int ox1 = ox * p;
      int ox2 = ox * p2;
      int i00, i01, i10, i11;

      // Y loop
      for (; py <= ey; py += oy2) {
        int px = py;
        int ex = py + ox * (nx - p2);

        // X loop
        for (; px <= ex; px += ox2) {
          int p01 = px  + ox1;
          int p10 = px  + oy1;
          int p11 = p10 + ox1;

          // 2D wavelet decoding
          if (w14) {
            wdec14(input[px], input[p10], a_b);
            i00 = a_b[0];
            i10 = a_b[1];

            wdec14(input[p01], input[p11], a_b);
            i01 = a_b[0];
            i11 = a_b[1];

            wdec14(i00, i01, a_b);
            input[px] = a_b[0];
            input[p01] = a_b[1];

            wdec14(i10, i11, a_b);
            input[p10] = a_b[0];
            input[p11] = a_b[1];
          } else {
            wdec16(input[px],  input[p10], a_b);
            i00 = a_b[0];
            i10 = a_b[1];

            wdec16(input[p01], input[p11], a_b);
            i01 = a_b[0];
            i11 = a_b[1];

            wdec16(i00, i01, a_b);
            input[px] = a_b[0];
            input[p01] = a_b[1];

            wdec16(i10, i11, a_b);
            input[p10] = a_b[0];
            input[p11] = a_b[1];
          }
        }

        // Decode (1D) odd column (still in Y loop)
        if (nx & p != 0) {
          int p10 = px + oy1;

          if (w14 != null) {
            wdec14(input[px], input[p10], a_b);
            i00 = a_b[0];
            input[p10] = a_b[1];
          } else {
            wdec16(input[px], input[p10], a_b);
            i00 = a_b[0];
            input[p10] = a_b[1];
          }

          input[px] = i00;
        }
      }

      // Decode (1D) odd line (must loop in X)
      if (ny & p != 0) {
        int px = py;
        int ex = py + ox * (nx - p2);

        for (; px <= ex; px += ox2) {
          int p01 = px + ox1;

          if (w14 != 0) {
            wdec14(input[px], input[p01], a_b);
            i00 = a_b[0];
            input[p01] = a_b[1];
          } else {
            wdec16(input[px], input[p01], a_b);
            i00 = a_b[0];
            input[p01] = a_b[1];
          }

          input[px] = i00;
        }
      }

      // Next level
      p2 = p;
      p >>= 1;
    }
  }

  static const int NBITS = 16;
  static const int A_OFFSET =  1 << (NBITS  - 1);
  static const int M_OFFSET =  1 << (NBITS  - 1);
  static const int MOD_MASK = (1 <<  NBITS) - 1;

  static void wdec14(int l, int h, List<int> a_b) {
    int ls = l;
    int hs = h;

    int hi = hs;
    int ai = ls + (hi & 1) + (hi >> 1);

    int as = ai;
    int bs = ai - hi;

    a_b[0] = as;
    a_b[1] = bs;
  }

  static void wdec16(int l, int h, List<int> a_b) {
    int m = l;
    int d = h;
    int bb = (m - (d >> 1)) & MOD_MASK;
    int aa = (d + bb - A_OFFSET) & MOD_MASK;
    a_b[1] = bb;
    a_b[0] = aa;
  }
}
