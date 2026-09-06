/// Choosing which transforms a VP8L stream should carry.
///
/// The alternative is to build the stream once per combination and keep the
/// smallest, which is exact but pays for every combination in full. libwebp
/// instead makes one pass over the pixels, accumulating what each hypothesis
/// would have to code, and picks by entropy. This mirrors its `AnalyzeEntropy`.
library;

import 'dart:math' as math;
import 'dart:typed_data';

import '../../util/_internal.dart';

/// Which of the transforms the analysis found worth applying.
@internal
class VP8LAnalysis {
  const VP8LAnalysis({
    required this.useSubtractGreen,
    required this.usePredictor,
    required this.useCrossColor,
  });

  final bool useSubtractGreen;
  final bool usePredictor;

  /// Cross-color only ever helps once the predictor has run, and never when
  /// red and blue are already zero everywhere.
  final bool useCrossColor;
}

/// The thirteen distributions one pass collects, in the order they are indexed.
const _alpha = 0;
const _red = 1;
const _green = 2;
const _blue = 3;
const _alphaPred = 4;
const _redPred = 5;
const _greenPred = 6;
const _bluePred = 7;
const _redSubGreen = 8;
const _blueSubGreen = 9;
const _redPredSubGreen = 10;
const _bluePredSubGreen = 11;
const _numHistograms = 12;

/// Per-channel `a - b`, each channel wrapping on its own.
@pragma('vm:prefer-inline')
int _subPixels(int a, int b) {
  final alphaAndGreen = 0x00ff00ff + (a & 0xff00ff00) - (b & 0xff00ff00);
  final redAndBlue = 0xff00ff00 + (a & 0x00ff00ff) - (b & 0x00ff00ff);
  return (alphaAndGreen & 0xff00ff00) | (redAndBlue & 0x00ff00ff);
}

/// Decides which transforms to apply, from one pass over [argb].
///
/// [transformBits] is the block size the predictor and cross-color sub-images
/// would use, which is what their overhead is charged against.
@internal
VP8LAnalysis analyzeEntropy(
    Uint32List argb, int width, int height, int transformBits) {
  final histo =
      List.generate(_numHistograms, (_) => Uint32List(256), growable: false);
  final alpha = histo[_alpha];
  final red = histo[_red];
  final green = histo[_green];
  final blue = histo[_blue];
  final alphaPred = histo[_alphaPred];
  final redPred = histo[_redPred];
  final greenPred = histo[_greenPred];
  final bluePred = histo[_bluePred];
  final redSubGreen = histo[_redSubGreen];
  final blueSubGreen = histo[_blueSubGreen];
  final redPredSubGreen = histo[_redPredSubGreen];
  final bluePredSubGreen = histo[_bluePredSubGreen];

  var pixPrev = argb[0]; // Skips the first pixel, which has no predecessor.
  for (var y = 0; y < height; y++) {
    final row = y * width;
    for (var x = 0; x < width; x++) {
      final pix = argb[row + x];
      final pixDiff = _subPixels(pix, pixPrev);
      pixPrev = pix;
      // A pixel equal to its left or top neighbour codes as part of a run
      // whichever transform is chosen, so counting it would let flat areas
      // decide a question they have no stake in.
      if (pixDiff == 0 || (y > 0 && pix == argb[row - width + x])) {
        continue;
      }

      alpha[(pix >> 24) & 0xff]++;
      red[(pix >> 16) & 0xff]++;
      green[(pix >> 8) & 0xff]++;
      blue[pix & 0xff]++;

      alphaPred[(pixDiff >> 24) & 0xff]++;
      redPred[(pixDiff >> 16) & 0xff]++;
      greenPred[(pixDiff >> 8) & 0xff]++;
      bluePred[pixDiff & 0xff]++;

      final g = (pix >> 8) & 0xff;
      redSubGreen[((pix >> 16) - g) & 0xff]++;
      blueSubGreen[(pix - g) & 0xff]++;

      final gd = (pixDiff >> 8) & 0xff;
      redPredSubGreen[((pixDiff >> 16) - gd) & 0xff]++;
      bluePredSubGreen[(pixDiff - gd) & 0xff]++;
    }
  }

  // The skip above removes zeros from the predicted distributions rather too
  // well; at least one is almost certainly there in reality.
  redPredSubGreen[0]++;
  bluePredSubGreen[0]++;
  redPred[0]++;
  greenPred[0]++;
  bluePred[0]++;
  alphaPred[0]++;

  final bits = Float64List(_numHistograms);
  for (var i = 0; i < _numHistograms; i++) {
    bits[i] = _bitsEntropy(histo[i]);
  }

  final direct = bits[_alpha] + bits[_red] + bits[_green] + bits[_blue];
  var spatial =
      bits[_alphaPred] + bits[_redPred] + bits[_greenPred] + bits[_bluePred];
  final subGreen =
      bits[_alpha] + bits[_redSubGreen] + bits[_green] + bits[_blueSubGreen];
  var spatialSubGreen = bits[_alphaPred] +
      bits[_redPredSubGreen] +
      bits[_greenPred] +
      bits[_bluePredSubGreen];

  // Carrying a transform costs its sub-image, which is small but decides the
  // question outright on small images. Fourteen predictors to name per block,
  // and three multipliers of a byte each for cross-color.
  final subImagePixels = _subSampleSize(width, transformBits) *
      _subSampleSize(height, transformBits);
  spatial += subImagePixels * (math.log(14) / math.ln2);
  spatialSubGreen += subImagePixels * (math.log(24) / math.ln2);

  var best = direct;
  var usePredictor = false;
  var useSubtractGreen = false;
  if (spatial < best) {
    best = spatial;
    usePredictor = true;
    useSubtractGreen = false;
  }
  if (subGreen < best) {
    best = subGreen;
    usePredictor = false;
    useSubtractGreen = true;
  }
  if (spatialSubGreen < best) {
    usePredictor = true;
    useSubtractGreen = true;
  }

  // Cross-color has nothing to remove if the winning hypothesis already leaves
  // red and blue at zero everywhere.
  final Uint32List chosenRed;
  final Uint32List chosenBlue;
  if (usePredictor && useSubtractGreen) {
    chosenRed = redPredSubGreen;
    chosenBlue = bluePredSubGreen;
  } else if (usePredictor) {
    chosenRed = redPred;
    chosenBlue = bluePred;
  } else if (useSubtractGreen) {
    chosenRed = redSubGreen;
    chosenBlue = blueSubGreen;
  } else {
    chosenRed = red;
    chosenBlue = blue;
  }
  var redAndBlueAlwaysZero = true;
  for (var i = 1; i < 256; i++) {
    if (chosenRed[i] != 0 || chosenBlue[i] != 0) {
      redAndBlueAlwaysZero = false;
      break;
    }
  }

  return VP8LAnalysis(
    useSubtractGreen: useSubtractGreen,
    usePredictor: usePredictor,
    useCrossColor: usePredictor && !redAndBlueAlwaysZero,
  );
}

int _subSampleSize(int size, int samplingBits) =>
    (size + (1 << samplingBits) - 1) >> samplingBits;

/// Bits a distribution would take, with the floor a prefix code cannot go
/// below.
///
/// Plain entropy is optimistic: a Huffman code spends whole bits, so a
/// distribution of two symbols costs about one bit each however skewed it is.
/// The correction mirrors libwebp's `BitsEntropyRefine`, whose constants are
/// empirical.
double _bitsEntropy(Uint32List counts) {
  var sum = 0;
  var nonzeros = 0;
  var maxVal = 0;
  var entropy = 0.0;
  for (var i = 0; i < 256; i++) {
    final v = counts[i];
    if (v != 0) {
      sum += v;
      nonzeros++;
      entropy += v * (math.log(v.toDouble()) / math.ln2);
      if (v > maxVal) {
        maxVal = v;
      }
    }
  }
  if (sum == 0) {
    return 0;
  }
  entropy = sum * (math.log(sum.toDouble()) / math.ln2) - entropy;

  if (nonzeros < 5) {
    if (nonzeros <= 1) {
      return 0;
    }
    if (nonzeros == 2) {
      // Two symbols code as 0 and 1; a little entropy is mixed back in so that
      // clustering can still tell such distributions apart.
      return (99 * sum + entropy) / 100;
    }
  }
  final mix = nonzeros < 5 ? (nonzeros == 3 ? 0.950 : 0.700) : 0.627;
  final floor = 2.0 * sum - maxVal;
  final minLimit = mix * floor + (1 - mix) * entropy;
  return entropy < minLimit ? minLimit : entropy;
}
