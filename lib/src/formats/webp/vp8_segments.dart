/// The analysis pass: deciding how many quantizer segments the picture wants
/// and which macroblock belongs to which.
///
/// Each macroblock is scored by how much of its energy survives the transform.
/// A block whose coefficients spread out is detailed and hides quantization
/// error well; a block whose energy sits in a few coefficients is smooth and
/// shows it. Clustering those scores lets the busy parts of a picture take a
/// coarser quantizer than the flat parts, at the same visual quality.
library;

import 'dart:typed_data';

import '../../util/_internal.dart';
import 'vp8_dsp.dart';
import 'vp8_iterator.dart';
import 'vp8_state.dart';
import 'vp8_tables.dart';

/// Coefficients above this bin are lumped together; they are mostly noise.
const _maxCoeffThresh = 31;

/// Susceptibilities use the whole 8-bit range.
const _maxAlpha = 255;
const _alphaScale = 2 * _maxAlpha;

/// How many modes to weigh during analysis.
///
/// Testing every mode here risks settling into a local optimum that the real
/// search would have avoided, so only the first two of each are tried.
const _maxIntra16Mode = 2;
const _maxUVMode = 2;

const _maxItersKMeans = 6;

/// Offsets of the sixteen luma blocks followed by the eight chroma blocks.
final _dspScan = Uint16List(24)
  ..setRange(0, 16, kScan)
  ..setRange(16, 24, kScanUV);

@pragma('vm:prefer-inline')
int _clip(int v, int m, int M) => v < m
    ? m
    : v > M
        ? M
        : v;

/// Chooses segments for every macroblock of [enc].
@internal
void analyzeSegments(VP8EncState enc) {
  final needsSegments = enc.config.emulateJpegSize ||
      enc.numSegments > 1 ||
      enc.config.method <= 1;
  if (!needsSegments) {
    _resetAllMBInfo(enc);
    return;
  }

  final alphas = Int32List(_maxAlpha + 1);
  final it = VP8EncIterator(enc);
  final analyzer = _MBAnalyzer(enc, it);
  var alphaSum = 0;
  var uvAlphaSum = 0;
  final totalMb = enc.mbW * enc.mbH;

  do {
    // The analysis pretends the reconstruction is perfect, so the neighbours
    // it predicts from are the source samples.
    it.import(sourceBoundary: true);
    analyzer.analyze(alphas);
    alphaSum += analyzer.bestAlpha;
    uvAlphaSum += analyzer.bestUvAlpha;
  } while (it.next());

  enc
    ..alpha = alphaSum ~/ totalMb
    ..uvAlpha = uvAlphaSum ~/ totalMb;
  _assignSegments(enc, alphas);
}

void _resetAllMBInfo(VP8EncState enc) {
  final n = enc.mbW * enc.mbH;
  enc.mbType.fillRange(0, n, 1); // intra 16x16
  enc.mbUvMode.fillRange(0, n, 0);
  enc.mbSkip.fillRange(0, n, 0);
  enc.mbSegment.fillRange(0, n, 0);
  enc.mbAlpha.fillRange(0, n, 0);
  enc.quant.dqm[0]
    ..alpha = 0
    ..beta = 0;
  enc
    ..alpha = 0
    ..uvAlpha = 0;
}

/// Measures one macroblock and picks a first guess at its modes.
class _MBAnalyzer {
  _MBAnalyzer(this.enc, this.it);

  final VP8EncState enc;
  final VP8EncIterator it;

  final _coeffs = Int16List(16);
  final _distribution = Int32List(_maxCoeffThresh + 1);

  /// Susceptibility of the macroblock just analyzed, and of its chroma.
  int bestAlpha = 0;
  int bestUvAlpha = 0;

  void analyze(Int32List alphas) {
    it
      ..setIntra16Mode(0) // default: intra 16x16, DC
      ..setSkip(false)
      ..setSegment(0);

    final luma = enc.config.method <= 1 ? _fastAnalyze() : _bestIntra16Mode();
    bestUvAlpha = _bestUVMode();

    // Luma dominates the impression, but chroma is not free either.
    var alpha = (3 * luma + bestUvAlpha + 2) >> 2;
    alpha = _clip(_maxAlpha - alpha, 0, _maxAlpha);
    alphas[alpha]++;
    enc.mbAlpha[it.mbPos] = alpha;
    bestAlpha = alpha;
  }

  /// Collects the coefficient histogram of blocks `[start, end)` and returns
  /// the susceptibility it implies.
  @pragma('vm:unsafe:no-bounds-checks')
  @pragma('vm:unsafe:no-interrupts')
  int _alphaOf(int predOffset, int start, int end) {
    _distribution.fillRange(0, _distribution.length, 0);
    for (var j = start; j < end; j++) {
      final off = _dspScan[j];
      final srcBase = j < 16 ? yOffEnc : uOffEnc;
      fTransform(
          it.yuvIn, srcBase + off, it.yuvP, predOffset + off, _coeffs, 0);
      for (var k = 0; k < 16; k++) {
        // Written out rather than calling abs(), which stays a call and shows
        // up as its own entry in the profile.
        final c = _coeffs[k];
        final v = (c < 0 ? -c : c) >> 3;
        _distribution[v > _maxCoeffThresh ? _maxCoeffThresh : v]++;
      }
    }
    var maxValue = 0;
    var lastNonZero = 1;
    for (var k = 0; k <= _maxCoeffThresh; k++) {
      final value = _distribution[k];
      if (value > 0) {
        if (value > maxValue) {
          maxValue = value;
        }
        lastNonZero = k;
      }
    }
    // Energy spread over many bins means the block is busy and can take more
    // quantization; energy in one bin means it is flat and cannot.
    return maxValue > 1 ? _alphaScale * lastNonZero ~/ maxValue : 0;
  }

  int _bestIntra16Mode() {
    predLuma16(it.yuvP, it.x != 0 ? it.yLeft : null, VP8EncIterator.yLeftOff,
        it.y != 0 ? it.yTop : null, it.yTopPos);
    var best = -1;
    var bestMode = 0;
    for (var mode = 0; mode < _maxIntra16Mode; mode++) {
      final alpha = _alphaOf(kI16ModeOffsets[mode], 0, 16);
      if (alpha > best) {
        best = alpha;
        bestMode = mode;
      }
    }
    it.setIntra16Mode(bestMode);
    return best;
  }

  int _bestUVMode() {
    predChroma8(it.yuvP, it.x != 0 ? it.uvLeft : null, VP8EncIterator.uLeftOff,
        it.y != 0 ? it.uvTop : null, it.uvTopPos);
    var best = -1;
    var smallest = 0;
    var bestMode = 0;
    for (var mode = 0; mode < _maxUVMode; mode++) {
      final alpha = _alphaOf(kUVModeOffsets[mode], 16, 16 + 4 + 4);
      if (alpha > best) {
        best = alpha;
      }
      // The mode that leaves the least energy behind is the one to predict
      // with, even though the susceptibility we report is the largest.
      if (mode == 0 || alpha < smallest) {
        smallest = alpha;
        bestMode = mode;
      }
    }
    it.setIntraUVMode(bestMode);
    return best;
  }

  /// The cheap analysis used at method 0 and 1: compare the variance of the
  /// sixteen block means against a threshold.
  int _fastAnalyze() {
    final q = enc.config.quality.toInt();
    // Around the block size, favouring 4x4 at high quality.
    final threshold = 8 + (17 - 8) * q ~/ 100;
    final dc = Uint32List(16);
    for (var k = 0; k < 16; k += 4) {
      mean16x4(it.yuvIn, yOffEnc + k * kBps, dc, k);
    }
    var m = 0;
    var m2 = 0;
    for (var k = 0; k < 16; k++) {
      m += dc[k];
      m2 += dc[k] * dc[k];
    }
    if (threshold * m2 < m * m) {
      it.setIntra16Mode(0); // flat: DC over the whole macroblock
    } else {
      it.setIntra4Mode(Uint8List(16));
    }
    return 0;
  }
}

/// Groups the macroblocks into segments by clustering their susceptibilities.
void _assignSegments(VP8EncState enc, Int32List alphas) {
  final nb = enc.numSegments;
  final centers = Int32List(4);
  final map = Int32List(_maxAlpha + 1);
  final accum = Int32List(4);
  final distAccum = Int32List(4);
  var weightedAverage = 0;

  var minA = 0;
  var maxA = _maxAlpha;
  var n = 0;
  for (; n <= _maxAlpha && alphas[n] == 0; n++) {}
  minA = n;
  for (n = _maxAlpha; n > minA && alphas[n] == 0; n--) {}
  maxA = n;
  final rangeA = maxA - minA;

  // Start with the centres spread evenly over the range that is in use.
  for (var k = 0, i = 1; k < nb; k++, i += 2) {
    centers[k] = minA + (i * rangeA) ~/ (2 * nb);
  }

  for (var k = 0; k < _maxItersKMeans; k++) {
    accum.fillRange(0, nb, 0);
    distAccum.fillRange(0, nb, 0);
    // The centres stay sorted, so the nearest one can be tracked by walking
    // forward with 'a'.
    var c = 0;
    for (var a = minA; a <= maxA; a++) {
      if (alphas[a] != 0) {
        while (
            c + 1 < nb && (a - centers[c + 1]).abs() < (a - centers[c]).abs()) {
          c++;
        }
        map[a] = c;
        distAccum[c] += a * alphas[a];
        accum[c] += alphas[a];
      }
    }
    var displaced = 0;
    var totalWeight = 0;
    weightedAverage = 0;
    for (var i = 0; i < nb; i++) {
      if (accum[i] != 0) {
        final newCenter = (distAccum[i] + accum[i] ~/ 2) ~/ accum[i];
        displaced += (centers[i] - newCenter).abs();
        centers[i] = newCenter;
        weightedAverage += newCenter * accum[i];
        totalWeight += accum[i];
      }
    }
    weightedAverage = (weightedAverage + totalWeight ~/ 2) ~/ totalWeight;
    if (displaced < 5) {
      break;
    }
  }

  for (var i = 0; i < enc.mbW * enc.mbH; i++) {
    final alpha = enc.mbAlpha[i];
    enc.mbSegment[i] = map[alpha];
    enc.mbAlpha[i] = centers[map[alpha]]; // for the record
  }

  _setSegmentAlphas(enc, centers, weightedAverage);
}

/// Turns the cluster centres into the per-segment susceptibilities that drive
/// the quantizer and the filter strength.
void _setSegmentAlphas(VP8EncState enc, Int32List centers, int mid) {
  final nb = enc.numSegments;
  var min = centers[0];
  var max = centers[0];
  if (nb > 1) {
    for (var n = 0; n < nb; n++) {
      if (min > centers[n]) {
        min = centers[n];
      }
      if (max < centers[n]) {
        max = centers[n];
      }
    }
  }
  if (max == min) {
    max = min + 1;
  }
  for (var n = 0; n < nb; n++) {
    final alpha = 255 * (centers[n] - mid) ~/ (max - min);
    final beta = 255 * (centers[n] - min) ~/ (max - min);
    enc.quant.dqm[n]
      ..alpha = _clip(alpha, -127, 127)
      ..beta = _clip(beta, 0, 255);
  }
}
