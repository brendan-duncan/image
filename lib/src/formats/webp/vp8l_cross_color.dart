/// The VP8L cross-color transform, from the encoder's side.
///
/// Subtracting green removes the bulk of the correlation between channels, but
/// what is left still moves together: an edge leaves a residual in red, green
/// and blue at once. This transform fits a small linear model per block, so red
/// is predicted from green and blue from both, and codes only what is left.
library;

import 'dart:math' as math;
import 'dart:typed_data';

import '../../util/_internal.dart';

/// The three multipliers a block of the cross-color transform carries.
@internal
class VP8LColorMultipliers {
  VP8LColorMultipliers(this.greenToRed, this.greenToBlue, this.redToBlue);

  final int greenToRed;
  final int greenToBlue;
  final int redToBlue;

  /// The multipliers as the sub-image pixel that stores them: green to red in
  /// blue, green to blue in green, red to blue in red.
  int get blue => greenToRed & 0xff;
  int get green => greenToBlue & 0xff;
  int get red => redToBlue & 0xff;
}

int _int8(int v) => v < 128 ? v : v - 256;

/// The delta a multiplier applies, matching the decoder's
/// VP8LMultipliers.colorTransformDelta.
///
/// The decoder computes this on unsigned 32 bit values and keeps the low eight
/// bits; an arithmetic shift agrees with that everywhere the result is masked,
/// which is everywhere it is used.
@internal
int colorTransformDelta(int multiplier, int color) =>
    (_int8(multiplier) * _int8(color)) >> 5;

/// Fits the multiplier that best predicts the first [n] of [target] from
/// [source].
///
/// The least squares estimate lands close, and the handful of neighbours around
/// it are then scored on what they actually cost to code, which the closed form
/// cannot see because of the shift and the wrap to eight bits.
@pragma('vm:unsafe:no-bounds-checks')
int _fitMultiplier(Uint8List source, Uint8List target, int n,
    Int32List candidates, Int32List signed, Int32List costs) {
  var sumXY = 0;
  var sumXX = 0;
  for (var k = 0; k < n; k++) {
    final x = _int8(source[k]);
    final y = _int8(target[k]);
    sumXY += x * y;
    sumXX += x * x;
  }
  if (sumXX == 0) {
    return 0;
  }

  final estimate = (32 * sumXY / sumXX).round().clamp(-128, 127);

  // Zero always competes, since declining the correlation is a real option.
  // Each candidate is kept twice: as the byte it will be stored as, and as the
  // signed value the delta is computed from, so the conversion stays out of
  // the pixel loop.
  candidates[0] = 0;
  signed[0] = 0;
  var numCandidates = 1;
  for (var t = estimate - 2; t <= estimate + 2; t++) {
    if (t >= -128 && t <= 127) {
      signed[numCandidates] = _int8(t & 0xff);
      candidates[numCandidates++] = t;
    }
  }

  // All the candidates are scored in one sweep of the block. Scoring them one
  // at a time reads the block six times over, and this runs three times per
  // block for every block of the image.
  costs.fillRange(0, numCandidates, 0);
  for (var k = 0; k < n; k++) {
    final s = _int8(source[k]);
    final t = target[k];
    for (var c = 0; c < numCandidates; c++) {
      final d = (t - ((signed[c] * s) >> 5)) & 0xff;
      costs[c] += d < 128 ? d : 256 - d;
    }
  }

  var best = 0;
  var bestCost = costs[0];
  for (var c = 1; c < numCandidates; c++) {
    if (costs[c] < bestCost) {
      bestCost = costs[c];
      best = candidates[c];
    }
  }
  return best & 0xff;
}

/// Chooses multipliers for every block, or null when the transform would not
/// pay for the sub-image that has to carry it.
@internal
List<VP8LColorMultipliers>? selectCrossColor(Uint8List r, Uint8List g,
    Uint8List b, int width, int height, int blockBits) {
  final blockSize = 1 << blockBits;
  final blockW = (width + blockSize - 1) >> blockBits;
  final blockH = (height + blockSize - 1) >> blockBits;
  final result = <VP8LColorMultipliers>[];

  // Red residuals in the first half, blue in the second.
  final before = Uint32List(512);
  final after = Uint32List(512);

  // Each block's channels gathered into contiguous buffers, reused across
  // blocks. The fits then walk plain arrays instead of chasing a list of pixel
  // indices, and nothing is allocated per block.
  final maxBlock = blockSize * blockSize;
  final blockG = Uint8List(maxBlock);
  final blockR = Uint8List(maxBlock);
  final blockB = Uint8List(maxBlock);
  final blueAfterGreen = Uint8List(maxBlock);
  final candidates = Int32List(6);
  final signed = Int32List(6);
  final costs = Int32List(6);

  for (var by = 0; by < blockH; by++) {
    for (var bx = 0; bx < blockW; bx++) {
      final x0 = bx * blockSize;
      final y0 = by * blockSize;
      final x1 = (x0 + blockSize) < width ? x0 + blockSize : width;
      final y1 = (y0 + blockSize) < height ? y0 + blockSize : height;

      var n = 0;
      for (var y = y0; y < y1; y++) {
        final base = y * width;
        for (var x = x0; x < x1; x++) {
          final i = base + x;
          blockG[n] = g[i];
          blockR[n] = r[i];
          blockB[n] = b[i];
          n++;
        }
      }

      final greenToRed =
          _fitMultiplier(blockG, blockR, n, candidates, signed, costs);

      // Blue is predicted from green first, then from red, matching the order
      // the decoder undoes them in.
      final greenToBlue =
          _fitMultiplier(blockG, blockB, n, candidates, signed, costs);
      for (var k = 0; k < n; k++) {
        blueAfterGreen[k] =
            (blockB[k] - colorTransformDelta(greenToBlue, blockG[k])) & 0xff;
      }
      final redToBlue =
          _fitMultiplier(blockR, blueAfterGreen, n, candidates, signed, costs);

      result.add(VP8LColorMultipliers(greenToRed, greenToBlue, redToBlue));

      // What actually gets coded is the entropy of the residuals, not their
      // magnitude, so accumulate the distributions over the whole image and
      // compare those.
      for (var k = 0; k < n; k++) {
        before[blockR[k]]++;
        before[256 + blockB[k]]++;
        after[
            (blockR[k] - colorTransformDelta(greenToRed, blockG[k])) & 0xff]++;
        after[256 +
            ((blueAfterGreen[k] - colorTransformDelta(redToBlue, blockR[k])) &
                0xff)]++;
      }
    }
  }

  // Storing the sub-image costs something too; charge three bytes a block.
  final gain = _entropy(before, 256) +
      _entropy(before, 256, offset: 256) -
      _entropy(after, 256) -
      _entropy(after, 256, offset: 256);
  return gain > blockW * blockH * 24 ? result : null;
}

/// Shannon entropy in bits of a slice of [freq].
double _entropy(Uint32List freq, int size, {int offset = 0}) {
  var total = 0;
  for (var i = 0; i < size; i++) {
    total += freq[offset + i];
  }
  if (total == 0) {
    return 0;
  }
  var bits = 0.0;
  for (var i = 0; i < size; i++) {
    final f = freq[offset + i];
    if (f > 0) {
      bits -= f * (math.log(f / total) / math.ln2);
    }
  }
  return bits;
}

/// Applies the transform in place, exactly inverting what the decoder's
/// colorSpaceInverseTransform will do.
@internal
void applyCrossColor(Uint8List r, Uint8List g, Uint8List b, int width,
    int height, int blockBits, List<VP8LColorMultipliers> multipliers) {
  final blockW = (width + (1 << blockBits) - 1) >> blockBits;
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final i = y * width + x;
      final m = multipliers[(y >> blockBits) * blockW + (x >> blockBits)];
      final red = r[i];
      r[i] = (red - colorTransformDelta(m.greenToRed, g[i])) & 0xff;
      // The decoder adds the red term back using the red it has just restored,
      // which is this original value, so subtract with it here.
      b[i] = (b[i] -
              colorTransformDelta(m.greenToBlue, g[i]) -
              colorTransformDelta(m.redToBlue, red)) &
          0xff;
    }
  }
}
