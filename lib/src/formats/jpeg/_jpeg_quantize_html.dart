import 'dart:typed_data';

import '../../util/bit_utils.dart';

Uint8List? _dctClip;

// These functions contain bit-shift operations that fail with HTML builds.
// A conditional import is used to use a modified version for HTML builds
// to work around this javascript bug, while keeping the native version fast.

// Quantize the coefficients and apply IDCT.
//
// A port of poppler's IDCT method which in turn is taken from:
// Christoph Loeffler, Adriaan Ligtenberg, George S. Moschytz,
// "Practical Fast 1-D DCT Algorithms with 11 Multiplications",
// IEEE Intl. Conf. on Acoustics, Speech & Signal Processing, 1989, 988-991.
void quantizeAndInverse(Int16List quantizationTable, Int16List coefficients,
    int offset, Uint8List dataOut, Int32List dataIn) {
  final p = dataIn;

  const dctClipOffset = 256;
  const dctClipLength = 768;
  if (_dctClip == null) {
    final clip = Uint8List(dctClipLength);
    for (var i = 0; i < 256; ++i) {
      clip[dctClipOffset + i] = i;
    }
    for (var i = 256; i < 512; ++i) {
      clip[dctClipOffset + i] = 255;
    }
    _dctClip = clip;
  }

  // IDCT constants (20.12 fixed point format)
  const cos1 = 4017; // cos(pi/16)*4096
  const sin1 = 799; // sin(pi/16)*4096
  const cos3 = 3406; // cos(3*pi/16)*4096
  const sin3 = 2276; // sin(3*pi/16)*4096
  const cos6 = 1567; // cos(6*pi/16)*4096
  const sin6 = 3784; // sin(6*pi/16)*4096
  const sqrt2 = 5793; // sqrt(2)*4096
  const sqrt102 = 2896; // sqrt(2) / 2

  // de-quantize
  for (var i = 0; i < 64; i++) {
    p[i] = coefficients[offset + i] * quantizationTable[i];
  }

  // inverse DCT on rows
  var row = 0;
  for (var i = 0; i < 8; ++i, row += 8) {
    // check for all-zero AC coefficients
    if (p[1 + row] == 0 &&
        p[2 + row] == 0 &&
        p[3 + row] == 0 &&
        p[4 + row] == 0 &&
        p[5 + row] == 0 &&
        p[6 + row] == 0 &&
        p[7 + row] == 0) {
      final t = shiftR(sqrt2 * p[0 + row] + 512, 10);
      p[row + 0] = t;
      p[row + 1] = t;
      p[row + 2] = t;
      p[row + 3] = t;
      p[row + 4] = t;
      p[row + 5] = t;
      p[row + 6] = t;
      p[row + 7] = t;
      continue;
    }

    // stage 4
    var v0 = shiftR(sqrt2 * p[0 + row] + 128, 8);
    var v1 = shiftR(sqrt2 * p[4 + row] + 128, 8);
    var v2 = p[2 + row];
    var v3 = p[6 + row];
    var v4 = shiftR(sqrt102 * (p[1 + row] - p[7 + row]) + 128, 8);
    var v7 = shiftR(sqrt102 * (p[1 + row] + p[7 + row]) + 128, 8);
    var v5 = shiftL(p[3 + row], 4);
    var v6 = shiftL(p[5 + row], 4);

    // stage 3
    var t = shiftR(v0 - v1 + 1, 1);
    v0 = shiftR(v0 + v1 + 1, 1);
    v1 = t;
    t = shiftR(v2 * sin6 + v3 * cos6 + 128, 8);
    v2 = shiftR(v2 * cos6 - v3 * sin6 + 128, 8);
    v3 = t;
    t = shiftR(v4 - v6 + 1, 1);
    v4 = shiftR(v4 + v6 + 1, 1);
    v6 = t;
    t = shiftR(v7 + v5 + 1, 1);
    v5 = shiftR(v7 - v5 + 1, 1);
    v7 = t;

    // stage 2
    t = shiftR(v0 - v3 + 1, 1);
    v0 = shiftR(v0 + v3 + 1, 1);
    v3 = t;
    t = shiftR(v1 - v2 + 1, 1);
    v1 = shiftR(v1 + v2 + 1, 1);
    v2 = t;
    t = shiftR(v4 * sin3 + v7 * cos3 + 2048, 12);
    v4 = shiftR(v4 * cos3 - v7 * sin3 + 2048, 12);
    v7 = t;
    t = shiftR(v5 * sin1 + v6 * cos1 + 2048, 12);
    v5 = shiftR(v5 * cos1 - v6 * sin1 + 2048, 12);
    v6 = t;

    // stage 1
    p[0 + row] = v0 + v7;
    p[7 + row] = v0 - v7;
    p[1 + row] = v1 + v6;
    p[6 + row] = v1 - v6;
    p[2 + row] = v2 + v5;
    p[5 + row] = v2 - v5;
    p[3 + row] = v3 + v4;
    p[4 + row] = v3 - v4;
  }

  // inverse DCT on columns
  for (var i = 0; i < 8; ++i) {
    final col = i;
    final p0 = col;
    final p1 = 8 + col;
    final p2 = 16 + col;
    final p3 = 24 + col;
    final p4 = 32 + col;
    final p5 = 40 + col;
    final p6 = 48 + col;
    final p7 = 56 + col;

    // check for all-zero AC coefficients
    if (p[p1] == 0 &&
        p[p2] == 0 &&
        p[p3] == 0 &&
        p[p4] == 0 &&
        p[p5] == 0 &&
        p[p6] == 0 &&
        p[p7] == 0) {
      final t = shiftR(sqrt2 * dataIn[i] + 8192, 14);
      p[p0] = t;
      p[p1] = t;
      p[p2] = t;
      p[p3] = t;
      p[p4] = t;
      p[p5] = t;
      p[p6] = t;
      p[p7] = t;
      continue;
    }

    // stage 4
    var v0 = shiftR(sqrt2 * p[p0] + 2048, 12);
    var v1 = shiftR(sqrt2 * p[p4] + 2048, 12);
    var v2 = p[p2];
    var v3 = p[p6];
    var v4 = shiftR(sqrt102 * (p[p1] - p[p7]) + 2048, 12);
    var v7 = shiftR(sqrt102 * (p[p1] + p[p7]) + 2048, 12);
    var v5 = p[p3];
    var v6 = p[p5];

    // stage 3
    var t = shiftR(v0 - v1 + 1, 1);
    v0 = shiftR(v0 + v1 + 1, 1);
    v1 = t;
    t = shiftR(v2 * sin6 + v3 * cos6 + 2048, 12);
    v2 = shiftR(v2 * cos6 - v3 * sin6 + 2048, 12);
    v3 = t;
    t = shiftR(v4 - v6 + 1, 1);
    v4 = shiftR(v4 + v6 + 1, 1);
    v6 = t;
    t = shiftR(v7 + v5 + 1, 1);
    v5 = shiftR(v7 - v5 + 1, 1);
    v7 = t;

    // stage 2
    t = shiftR(v0 - v3 + 1, 1);
    v0 = shiftR(v0 + v3 + 1, 1);
    v3 = t;
    t = shiftR(v1 - v2 + 1, 1);
    v1 = shiftR(v1 + v2 + 1, 1);
    v2 = t;
    t = shiftR(v4 * sin3 + v7 * cos3 + 2048, 12);
    v4 = shiftR(v4 * cos3 - v7 * sin3 + 2048, 12);
    v7 = t;
    t = shiftR(v5 * sin1 + v6 * cos1 + 2048, 12);
    v5 = shiftR(v5 * cos1 - v6 * sin1 + 2048, 12);
    v6 = t;

    // stage 1
    p[p0] = v0 + v7;
    p[p7] = v0 - v7;
    p[p1] = v1 + v6;
    p[p6] = v1 - v6;
    p[p2] = v2 + v5;
    p[p5] = v2 - v5;
    p[p3] = v3 + v4;
    p[p4] = v3 - v4;
  }

  // convert to 8-bit integers
  for (var i = 0; i < 64; ++i) {
    dataOut[i] = _dctClip![(dctClipOffset + 128 + shiftR(p[i] + 8, 4))];
  }
}
