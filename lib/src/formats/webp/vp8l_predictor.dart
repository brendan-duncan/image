/// The VP8L predictor transform: the formulas, choosing one per block, and
/// writing the result out.
///
/// The formulas mirror predictors 0..13 in VP8LTransform, on the same packed
/// ARGB word the decoder works in, so the two can be read side by side. They
/// are normative: every conformant decoder computes exactly these values, so
/// diverging here would corrupt the image for every reader, not only this
/// package's decoder. Which of them each block uses is entirely the encoder's
/// choice, and is decided further down.
library;

import 'dart:typed_data';

import '../../util/_internal.dart';
import 'vp8l_bit_writer.dart';
import 'vp8l_huffman_encoder.dart' as huffman;

/// Every predictor VP8L defines. The decoder implements all of them, so
/// restricting the search to a handful only costs compression.
@internal
const numPredictors = 14;

/// The prediction on the top-left pixel, where no neighbour exists.
@internal
const argbBlack = 0xff000000;

/// Per-byte `(a0 + a1) >> 1`, computed on all four channels at once.
///
/// Masking off the low bit of each byte before shifting keeps a channel's
/// carry out of the one below it.
@pragma('vm:prefer-inline')
int _avg2(int a0, int a1) => (((a0 ^ a1) & 0xfefefefe) >> 1) + (a0 & a1);

@pragma('vm:prefer-inline')
int _avg3(int a0, int a1, int a2) => _avg2(_avg2(a0, a2), a1);

@pragma('vm:prefer-inline')
int _avg4(int a0, int a1, int a2, int a3) =>
    _avg2(_avg2(a0, a1), _avg2(a2, a3));

@pragma('vm:prefer-inline')
int _clip255(int v) => v < 0
    ? 0
    : v > 255
        ? 255
        : v;

int _addSubFull(int c0, int c1, int c2) {
  final a = _clip255((c0 >> 24) + (c1 >> 24) - (c2 >> 24));
  final r =
      _clip255(((c0 >> 16) & 0xff) + ((c1 >> 16) & 0xff) - ((c2 >> 16) & 0xff));
  final g =
      _clip255(((c0 >> 8) & 0xff) + ((c1 >> 8) & 0xff) - ((c2 >> 8) & 0xff));
  final b = _clip255((c0 & 0xff) + (c1 & 0xff) - (c2 & 0xff));
  return (a << 24) | (r << 16) | (g << 8) | b;
}

@pragma('vm:prefer-inline')
int _addSubHalfComponent(int a, int b) => _clip255(a + (a - b) ~/ 2);

int _addSubHalf(int c0, int c1, int c2) {
  final avg = _avg2(c0, c1);
  final a = _addSubHalfComponent(avg >> 24, c2 >> 24);
  final r = _addSubHalfComponent((avg >> 16) & 0xff, (c2 >> 16) & 0xff);
  final g = _addSubHalfComponent((avg >> 8) & 0xff, (c2 >> 8) & 0xff);
  final b = _addSubHalfComponent(avg & 0xff, c2 & 0xff);
  return (a << 24) | (r << 16) | (g << 8) | b;
}

@pragma('vm:prefer-inline')
int _sub3(int a, int b, int c) => (b - c).abs() - (a - c).abs();

int _select(int a, int b, int c) {
  final paMinusPb = _sub3(a >> 24, b >> 24, c >> 24) +
      _sub3((a >> 16) & 0xff, (b >> 16) & 0xff, (c >> 16) & 0xff) +
      _sub3((a >> 8) & 0xff, (b >> 8) & 0xff, (c >> 8) & 0xff) +
      _sub3(a & 0xff, b & 0xff, c & 0xff);
  return paMinusPb <= 0 ? a : b;
}

/// The A,R,G,B predicted by [mode] from the four neighbours, packed.
///
/// This is the readable statement of the transform. [predictAll] computes the
/// same values in a form the mode search can afford; a test holds the two to
/// each other.
@internal
int predict(int mode, int left, int top, int topLeft, int topRight) {
  switch (mode) {
    case 0:
      return argbBlack;
    case 1:
      return left;
    case 2:
      return top;
    case 3:
      return topRight;
    case 4:
      return topLeft;
    case 5:
      return _avg3(left, top, topRight);
    case 6:
      return _avg2(left, topLeft);
    case 7:
      return _avg2(left, top);
    case 8:
      return _avg2(topLeft, top);
    case 9:
      return _avg2(top, topRight);
    case 10:
      return _avg4(left, topLeft, top, topRight);
    case 11:
      return _select(top, left, topLeft);
    case 12:
      return _addSubFull(left, top, topLeft);
    default:
      return _addSubHalf(left, top, topLeft);
  }
}

/// Every predictor's output for one pixel, written into [out].
///
/// The mode search needs all fourteen at each pixel. Asking [predict] for them
/// one at a time re-derives the shared averages fourteen times over; here each
/// is computed once.
@internal
@pragma('vm:unsafe:no-bounds-checks')
@pragma('vm:unsafe:no-interrupts')
void predictAll(int left, int top, int topLeft, int topRight, Uint32List out) {
  final avgLeftTopLeft = _avg2(left, topLeft);
  final avgTopTopRight = _avg2(top, topRight);
  out[0] = argbBlack;
  out[1] = left;
  out[2] = top;
  out[3] = topRight;
  out[4] = topLeft;
  out[5] = _avg2(_avg2(left, topRight), top);
  out[6] = avgLeftTopLeft;
  out[7] = _avg2(left, top);
  out[8] = _avg2(topLeft, top);
  out[9] = avgTopTopRight;
  out[10] = _avg2(avgLeftTopLeft, avgTopTopRight);
  out[11] = _select(top, left, topLeft);
  out[12] = _addSubFull(left, top, topLeft);
  out[13] = _addSubHalf(left, top, topLeft);
}

/// Summed signed magnitude of the residual [v] - [p], over all four
/// channels.
///
/// A residual wraps, so a channel differing by 200 is really off by 56 and
/// costs what 56 costs.
@pragma('vm:unsafe:no-bounds-checks')
@pragma('vm:unsafe:no-interrupts')
int _residualMagnitude(int v, int p) {
  var d = ((v >> 24) - (p >> 24)) & 0xff;
  var cost = d < 128 ? d : 256 - d;
  d = ((v >> 16) - (p >> 16)) & 0xff;
  cost += d < 128 ? d : 256 - d;
  d = ((v >> 8) - (p >> 8)) & 0xff;
  cost += d < 128 ? d : 256 - d;
  d = (v - p) & 0xff;
  return cost + (d < 128 ? d : 256 - d);
}

/// Picks a predictor for each block, minimising the summed magnitude of the
/// residuals it leaves behind.
@internal
@pragma('vm:unsafe:no-bounds-checks')
List<int> selectPredictorModes(
  Uint32List argb,
  int width,
  int height,
  int blockW,
  int blockH,
  int blockSize,
) {
  final modes = List<int>.filled(blockW * blockH, 11);
  // A block spans at most 32 pixels either way, so four channels of at most
  // 128 each keep the running cost well inside 32 bits.
  final cost = Int32List(numPredictors);
  final preds = Uint32List(numPredictors);
  for (var by = 0; by < blockH; by++) {
    for (var bx = 0; bx < blockW; bx++) {
      final x0 = bx * blockSize;
      final y0 = by * blockSize;
      final x1 = (x0 + blockSize).clamp(0, width);
      final y1 = (y0 + blockSize).clamp(0, height);
      cost.fillRange(0, numPredictors, 0);
      // The top row and left column are predicted the same way whatever mode
      // the block carries, so they add one constant to every candidate and
      // cannot change which comes out cheapest. Leaving them out also keeps
      // the inner loop free of a per-pixel edge test.
      final yStart = y0 == 0 ? 1 : y0;
      final xStart = x0 == 0 ? 1 : x0;
      for (var y = yStart; y < y1; y++) {
        final row = y * width;
        for (var x = xStart; x < x1; x++) {
          final i = row + x;
          final v = argb[i];
          predictAll(argb[i - 1], argb[i - width], argb[i - width - 1],
              argb[i - width + 1], preds);
          for (var m = 0; m < numPredictors; m++) {
            cost[m] += _residualMagnitude(v, preds[m]);
          }
        }
      }
      var bestMode = 0;
      var bestCost = cost[0];
      for (var m = 1; m < numPredictors; m++) {
        if (cost[m] < bestCost) {
          bestCost = cost[m];
          bestMode = m;
        }
      }
      modes[by * blockW + bx] = bestMode;
    }
  }
  return modes;
}

/// Replaces each pixel with its residual against the prediction the block's
/// mode makes, writing the result into the planes.
///
/// [argb] holds the original pixels, which is what the decoder has
/// reconstructed by the time it reaches each one. Edge rules match the
/// decoder: (0,0) predicts black, the top row predicts left, the left column
/// predicts top.
@internal
void applyPredictorTransform(
  Uint32List argb,
  Uint8List r,
  Uint8List g,
  Uint8List b,
  Uint8List a,
  int width,
  int height,
  int blockW,
  int blockSize,
  List<int> modes,
) {
  final shift = blockSize.bitLength - 1;
  for (var y = 0; y < height; y++) {
    final row = y * width;
    final modeRow = (y >> shift) * blockW;
    for (var x = 0; x < width; x++) {
      final i = row + x;
      final int p;
      if (y == 0) {
        p = x == 0 ? argbBlack : argb[i - 1];
      } else if (x == 0) {
        p = argb[i - width];
      } else {
        p = predict(modes[modeRow + (x >> shift)], argb[i - 1], argb[i - width],
            argb[i - width - 1], argb[i - width + 1]);
      }
      final v = argb[i];
      a[i] = ((v >> 24) - (p >> 24)) & 0xff;
      r[i] = ((v >> 16) - (p >> 16)) & 0xff;
      g[i] = ((v >> 8) - (p >> 8)) & 0xff;
      b[i] = (v - p) & 0xff;
    }
  }
}

/// Write a VP8L predictor sub-image inline (no RIFF, no signature, no
/// transform loop) using per-block predictor [modes].
@internal
void writePredictorSubImage(
    VP8LBitWriter bw, int blockW, int blockH, List<int> modes) {
  final n = blockW * blockH;
  // Build green-channel frequency table for the sub-image pixels.
  final greenFreq = List<int>.filled(280, 0);
  for (final m in modes) {
    greenFreq[m]++;
  }
  final greenCl = huffman.buildHuffmanCodeLengths(greenFreq, 280);
  final greenCodes = huffman.canonicalCodes(Int32List.fromList(greenCl), 280);

  // Sub-image format (decoded with isLevel0=false, allowRecursion=false):
  // no color cache, then 5 Huffman groups, then pixel data.
  bw.writeBits(0, 1); // no color cache
  // Green (280): normal Huffman for the mode values.
  huffman.writeHuffmanCode(bw, 280, greenCl);
  // Red/Blue (256): all 0 → simple, 1-bit symbol = 0.
  // Alpha (256): all 255 → simple, 8-bit symbol = 255.
  // Dist (40): unused → simple, 1-bit symbol = 0.
  bw
    ..writeBits(1, 1) // red: is_simple=1
    ..writeBits(0, 1) // 1 symbol
    ..writeBits(0, 1) // 1-bit symbol
    ..writeBits(0, 1) // symbol = 0
    ..writeBits(1, 1) // blue: is_simple=1
    ..writeBits(0, 1)
    ..writeBits(0, 1)
    ..writeBits(0, 1)
    ..writeBits(1, 1) // alpha: is_simple=1
    ..writeBits(0, 1)
    ..writeBits(1, 1) // 8-bit symbol
    ..writeBits(255, 8)
    ..writeBits(1, 1) // dist: is_simple=1
    ..writeBits(0, 1)
    ..writeBits(0, 1)
    ..writeBits(0, 1);
  // Pixel data: blockW*blockH pixels with G=modes[i], R=0, B=0, A=255.
  // Red/blue/alpha each have a 1-symbol code → 1 bit each.
  for (var i = 0; i < n; i++) {
    final m = modes[i];
    bw.writeBits(greenCodes[m], greenCl[m]); // green = predictor mode
  }
}
