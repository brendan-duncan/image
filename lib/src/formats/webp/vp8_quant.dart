/// Quantization: turning a quality setting into the step sizes and the
/// rate-distortion weights every later decision is measured against.
library;

import 'dart:math' as math;
import 'dart:typed_data';

import '../../util/_internal.dart';
import 'vp8_config.dart';
import 'vp8_sar.dart';
import 'vp8_tables.dart';

/// Fixed-point precision of the reciprocal quantizer.
const _qFix = 17;

/// Largest codable coefficient level.
const maxLevel = 2047;

/// Diffusion errors are stored descaled by this, so that they fit in a byte.
const errorDescale = 1;

/// The AC step sizes of the luma DC block, which is coded through a second
/// transform and so needs a coarser ladder than [kAcTable].
const _acTable2 = [
  8, 8, 9, 10, 12, 13, 15, 17, //
  18, 20, 21, 23, 24, 26, 27, 29,
  31, 32, 34, 35, 37, 38, 40, 41,
  43, 44, 46, 48, 49, 51, 52, 54,
  55, 57, 58, 60, 62, 63, 65, 66,
  68, 69, 71, 72, 74, 75, 77, 79,
  80, 82, 83, 85, 86, 88, 89, 93,
  96, 99, 102, 105, 108, 111, 114, 117,
  120, 124, 127, 130, 133, 136, 139, 142,
  145, 148, 151, 155, 158, 161, 164, 167,
  170, 173, 176, 179, 184, 189, 193, 198,
  203, 207, 212, 217, 221, 226, 230, 235,
  240, 244, 249, 254, 258, 263, 268, 274,
  280, 286, 292, 299, 305, 311, 317, 323,
  330, 336, 342, 348, 354, 362, 370, 379,
  385, 393, 401, 409, 416, 424, 432, 440
];

/// Rounding bias per matrix kind, as [dc, ac] in 1/256ths.
///
/// A bias below 128 rounds towards zero, which spends fewer bits at a small
/// cost in accuracy; luma AC is biased hardest because that is where most of
/// the coefficients are.
const _biasMatrices = [
  [96, 110], // luma AC
  [96, 108], // luma DC (second transform)
  [110, 115], // chroma
];

/// Number of bits the sharpening bias is descaled by.
const _sharpenBits = 11;

/// A small boost of the high-frequency coefficients, which keeps detail that
/// the quantizer would otherwise round away in the mid-quality range.
const _freqSharpening = [
  0, 30, 60, 90, //
  30, 60, 90, 90,
  60, 90, 90, 90,
  90, 90, 90, 90
];

/// Filtering strength needed to smooth an edge step of a given size, indexed
/// by sharpness then by the step.
///
/// Found by brute force in libwebp: for each step, the lowest level at which
/// the loop filter would act.
const _levelsFromDelta = [
  [
    0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, //
    16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31,
    32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47,
    48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63
  ],
  [
    0, 1, 2, 3, 5, 6, 7, 8, 9, 11, 12, 13, 14, 15, 17, 18, //
    20, 21, 23, 24, 26, 27, 29, 30, 32, 33, 35, 36, 38, 39, 41, 42,
    44, 45, 47, 48, 50, 51, 53, 54, 56, 57, 59, 60, 62, 63, 63, 63,
    63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63
  ],
  [
    0, 1, 2, 3, 5, 6, 7, 8, 9, 11, 12, 13, 14, 16, 17, 19, //
    20, 22, 23, 25, 26, 28, 29, 31, 32, 34, 35, 37, 38, 40, 41, 43,
    44, 46, 47, 49, 50, 52, 53, 55, 56, 58, 59, 61, 62, 63, 63, 63,
    63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63
  ],
  [
    0, 1, 2, 3, 5, 6, 7, 8, 9, 11, 12, 13, 15, 16, 18, 19, //
    21, 22, 24, 25, 27, 28, 30, 31, 33, 34, 36, 37, 39, 40, 42, 43,
    45, 46, 48, 49, 51, 52, 54, 55, 57, 58, 60, 61, 63, 63, 63, 63,
    63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63
  ],
  [
    0, 1, 2, 3, 5, 6, 7, 8, 9, 11, 12, 14, 15, 17, 18, 20, //
    21, 23, 24, 26, 27, 29, 30, 32, 33, 35, 36, 38, 39, 41, 42, 44,
    45, 47, 48, 50, 51, 53, 54, 56, 57, 59, 60, 62, 63, 63, 63, 63,
    63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63
  ],
  [
    0, 1, 2, 4, 5, 7, 8, 9, 11, 12, 13, 15, 16, 17, 19, 20, //
    22, 23, 25, 26, 28, 29, 31, 32, 34, 35, 37, 38, 40, 41, 43, 44,
    46, 47, 49, 50, 52, 53, 55, 56, 58, 59, 61, 62, 63, 63, 63, 63,
    63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63
  ],
  [
    0, 1, 2, 4, 5, 7, 8, 9, 11, 12, 13, 15, 16, 18, 19, 21, //
    22, 24, 25, 27, 28, 30, 31, 33, 34, 36, 37, 39, 40, 42, 43, 45,
    46, 48, 49, 51, 52, 54, 55, 57, 58, 60, 61, 63, 63, 63, 63, 63,
    63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63
  ],
  [
    0, 1, 2, 4, 5, 7, 8, 9, 11, 12, 14, 15, 17, 18, 20, 21, //
    23, 24, 26, 27, 29, 30, 32, 33, 35, 36, 38, 39, 41, 42, 44, 45,
    47, 48, 50, 51, 53, 54, 56, 57, 59, 60, 62, 63, 63, 63, 63, 63,
    63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63
  ]
];

/// The filtering strength that would smooth an edge step of [delta].
@internal
int filterStrengthFromDelta(int sharpness, int delta) =>
    _levelsFromDelta[sharpness][delta < 64 ? delta : 63];

@pragma('vm:prefer-inline')
int _clip(int v, int m, int M) => v < m
    ? m
    : v > M
        ? M
        : v;

/// One quantization matrix: a step size per coefficient position, plus the
/// derived values that make quantizing a multiply and a shift.
@internal
class VP8Matrix {
  /// Step sizes.
  final q = Int32List(16);

  /// Reciprocals of [q] in fixed point.
  final iq = Int32List(16);

  /// Rounding bias.
  final bias = Int32List(16);

  /// Value at or below which a coefficient quantizes to zero.
  final zthresh = Int32List(16);

  /// High-frequency boost added before quantizing.
  final sharpen = Int32List(16);

  /// Fills in every position from the DC and first AC step already in [q],
  /// and returns the average step size.
  ///
  /// [type] is 0 for luma AC, 1 for the luma DC block and 2 for chroma.
  int expand(int type) {
    for (var i = 0; i < 2; i++) {
      final b = _biasMatrices[type][i > 0 ? 1 : 0];
      iq[i] = (1 << _qFix) ~/ q[i];
      bias[i] = b << (_qFix - 8);
      // The exact value at which the quantized level turns non-zero.
      zthresh[i] = ((1 << _qFix) - 1 - bias[i]) ~/ iq[i];
    }
    for (var i = 2; i < 16; i++) {
      q[i] = q[1];
      iq[i] = iq[1];
      bias[i] = bias[1];
      zthresh[i] = zthresh[1];
    }
    var sum = 0;
    for (var i = 0; i < 16; i++) {
      // Sharpening applies to luma AC only.
      sharpen[i] = type == 0 ? (_freqSharpening[i] * q[i]) >> _sharpenBits : 0;
      sum += q[i];
    }
    return (sum + 8) >> 4;
  }
}

/// Quantizes one 4x4 block in place.
///
/// [inp] holds the transform coefficients in raster order and is overwritten
/// with the dequantized values, so the caller can reconstruct straight from it.
/// [out] receives the levels in zigzag order.
///
/// Returns the position of the last non-zero level, or -1 if there is none.
/// The pricing and the writing of a block both need that position, and finding
/// it again would mean scanning the levels backwards.
@internal
int quantizeBlock(
    Int16List inp, int inOff, Int16List out, int outOff, VP8Matrix mtx) {
  final sharpen = mtx.sharpen;
  // Only the DC has step sizes of its own: `expand` fills positions 2 to 15
  // from position 1, so every AC coefficient shares one set. Keeping those in
  // locals turns five array reads per coefficient into none.
  final q = mtx.q[1];
  final iq = mtx.iq[1];
  final bias = mtx.bias[1];
  final zthresh = mtx.zthresh[1];
  var last = -1;

  // Unrolled over the zigzag, so the scan order is in the offsets rather than
  // in a table lookup. This is the most-executed loop of the encoder, run once
  // per candidate block of every mode.
  if (_step(inp, inOff, out, outOff, sharpen[0], mtx.q[0], mtx.iq[0],
      mtx.bias[0], mtx.zthresh[0])) {
    last = 0;
  }
  if (_step(
      inp, inOff + 1, out, outOff + 1, sharpen[1], q, iq, bias, zthresh)) {
    last = 1;
  }
  if (_step(
      inp, inOff + 4, out, outOff + 2, sharpen[4], q, iq, bias, zthresh)) {
    last = 2;
  }
  if (_step(
      inp, inOff + 8, out, outOff + 3, sharpen[8], q, iq, bias, zthresh)) {
    last = 3;
  }
  if (_step(
      inp, inOff + 5, out, outOff + 4, sharpen[5], q, iq, bias, zthresh)) {
    last = 4;
  }
  if (_step(
      inp, inOff + 2, out, outOff + 5, sharpen[2], q, iq, bias, zthresh)) {
    last = 5;
  }
  if (_step(
      inp, inOff + 3, out, outOff + 6, sharpen[3], q, iq, bias, zthresh)) {
    last = 6;
  }
  if (_step(
      inp, inOff + 6, out, outOff + 7, sharpen[6], q, iq, bias, zthresh)) {
    last = 7;
  }
  if (_step(
      inp, inOff + 9, out, outOff + 8, sharpen[9], q, iq, bias, zthresh)) {
    last = 8;
  }
  if (_step(
      inp, inOff + 12, out, outOff + 9, sharpen[12], q, iq, bias, zthresh)) {
    last = 9;
  }
  if (_step(
      inp, inOff + 13, out, outOff + 10, sharpen[13], q, iq, bias, zthresh)) {
    last = 10;
  }
  if (_step(
      inp, inOff + 10, out, outOff + 11, sharpen[10], q, iq, bias, zthresh)) {
    last = 11;
  }
  if (_step(
      inp, inOff + 7, out, outOff + 12, sharpen[7], q, iq, bias, zthresh)) {
    last = 12;
  }
  if (_step(
      inp, inOff + 11, out, outOff + 13, sharpen[11], q, iq, bias, zthresh)) {
    last = 13;
  }
  if (_step(
      inp, inOff + 14, out, outOff + 14, sharpen[14], q, iq, bias, zthresh)) {
    last = 14;
  }
  if (_step(
      inp, inOff + 15, out, outOff + 15, sharpen[15], q, iq, bias, zthresh)) {
    last = 15;
  }
  return last;
}

/// Quantizes one coefficient in place, writing its level, and says whether the
/// level came out non-zero.
@pragma('vm:prefer-inline')
@pragma('vm:unsafe:no-bounds-checks')
@pragma('vm:unsafe:no-interrupts')
bool _step(Int16List inp, int at, Int16List out, int to, int sharpen, int q,
    int iq, int bias, int zthresh) {
  assert(at >= 0 && at < inp.length && to >= 0 && to < out.length);
  final v = inp[at];
  final sign = v < 0;
  final coeff = (sign ? -v : v) + sharpen;
  if (coeff > zthresh) {
    var level = (coeff * iq + bias) >> _qFix;
    if (level > maxLevel) {
      level = maxLevel;
    }
    if (sign) {
      level = -level;
    }
    inp[at] = level * q;
    out[to] = level;
    return level != 0;
  }
  out[to] = 0;
  inp[at] = 0;
  return false;
}

/// Quantizes one DC coefficient in place, returning the error left behind,
/// descaled by [errorDescale] so that it fits in a signed byte.
///
/// Error diffusion needs the remainder that ordinary quantization throws away,
/// and only for the DC, so this is a separate routine rather than a flag on
/// [quantizeBlock].
@internal
@pragma('vm:unsafe:no-bounds-checks')
int quantizeSingleDC(Int16List v, int at, VP8Matrix mtx) {
  var value = v[at];
  final sign = value < 0;
  if (sign) {
    value = -value;
  }
  if (value > mtx.zthresh[0]) {
    var level = (value * mtx.iq[0] + mtx.bias[0]) >> _qFix;
    if (level > maxLevel) {
      level = maxLevel;
    }
    final qv = level * mtx.q[0];
    final err = value - qv;
    v[at] = sign ? -qv : qv;
    return sar(sign ? -err : err, errorDescale);
  }
  v[at] = 0;
  return sar(sign ? -value : value, errorDescale);
}

/// Quantizes the two blocks at [inOff], returning a two-bit non-zero mask.
@internal
int quantize2Blocks(
    Int16List inp, int inOff, Int16List out, int outOff, VP8Matrix mtx) {
  final low = quantizeBlock(inp, inOff, out, outOff, mtx) >= 0 ? 1 : 0;
  final high =
      quantizeBlock(inp, inOff + 16, out, outOff + 16, mtx) >= 0 ? 2 : 0;
  return low | high;
}

/// Everything one quantizer segment decides: its step sizes, the weights that
/// balance rate against distortion at those steps, and its filter strength.
@internal
class VP8SegmentInfo {
  final y1 = VP8Matrix();
  final y2 = VP8Matrix();
  final uv = VP8Matrix();

  /// Quantization susceptibility, -127 to 127. Lower means less risk of
  /// visible blurring, so the segment can take a coarser quantizer.
  int alpha = 0;

  /// Filter susceptibility, 0 to 255.
  int beta = 0;

  /// The segment's quantizer index.
  int quant = 0;

  /// In-loop filtering strength signalled for this segment.
  int fstrength = 0;

  /// Largest edge step seen, used to pick the filter strength.
  int maxEdge = 0;

  /// Distortion below which filtering statistics are not recorded.
  int minDisto = 0;

  // How many units of distortion one bit is worth, per decision.
  int lambdaI16 = 0;
  int lambdaI4 = 0;
  int lambdaUv = 0;
  int lambdaMode = 0;
  int lambdaTrellis = 0;
  int tlambda = 0;
  int lambdaTrellisI16 = 0;
  int lambdaTrellisI4 = 0;
  int lambdaTrellisUv = 0;

  /// What choosing intra 4x4 has to beat, in score units.
  int i4Penalty = 0;

  bool equivalentTo(VP8SegmentInfo other) =>
      quant == other.quant && fstrength == other.fstrength;

  void copyFrom(VP8SegmentInfo other) {
    alpha = other.alpha;
    beta = other.beta;
    quant = other.quant;
    fstrength = other.fstrength;
    maxEdge = other.maxEdge;
    minDisto = other.minDisto;
  }
}

/// Neutral, lowest and highest useful values of the susceptibility scale.
const midAlpha = 64;
const minAlpha = 30;
const maxAlpha = 100;

// Scaling between the noise-shaping setting and the quantizer modulation.
const _snsToDq = 0.9;

// The chroma quantizer may be moved this far from the luma one.
const _maxDqUv = 6;
const _minDqUv = -4;

// Below this, filtering has no visible effect and only costs decode time.
const _fStrengthCutoff = 2;

/// The quantizer state of a frame: one segment set plus the channel offsets.
@internal
class VP8Quantizers {
  VP8Quantizers(this.numSegments);

  int numSegments;
  final dqm = List.generate(4, (_) => VP8SegmentInfo(), growable: false);

  /// The quantizer other segments are coded relative to.
  int baseQuant = 0;

  // Global offsets applied to each channel's quantizer.
  int dqY1Dc = 0;
  int dqY2Dc = 0;
  int dqY2Ac = 0;
  int dqUvDc = 0;
  int dqUvAc = 0;

  // Filter header values, derived from the quantizers rather than measured.
  int filterLevel = 0;
  int filterSharpness = 0;
  bool filterSimple = false;

  /// Chooses each segment's quantizer for [quality], then everything that
  /// follows from it.
  ///
  /// [uvAlpha] and each segment's `alpha` come from the analysis pass;
  /// [segmentOfMb] is remapped in place if two segments collapse into one.
  void setSegmentParams(VP8Config config, double quality, int alpha,
      int uvAlpha, Uint8List segmentOfMb) {
    final amp = _snsToDq * config.snsStrength / 100 / 128;
    final q = quality / 100;
    final cBase = config.emulateJpegSize
        ? _qualityToJpegCompression(q, alpha / 255)
        : _qualityToCompression(q);
    for (var i = 0; i < numSegments; i++) {
      // A segment that can take more quantization without showing it gets a
      // larger exponent, hence a coarser quantizer.
      final expn = 1.0 - amp * dqm[i].alpha;
      final c = math.pow(cBase, expn);
      dqm[i].quant = _clip((127 * (1 - c)).toInt(), 0, 127);
    }

    baseQuant = dqm[0].quant;
    // The syntax requires a value for every segment, used or not.
    for (var i = numSegments; i < 4; i++) {
      dqm[i].quant = baseQuant;
    }

    // uvAlpha sits around 60 on typical pictures, with a useful range of about
    // 30 (chroma detail worth keeping) to 100 (safe to decimate further).
    var dqUvAcValue =
        (uvAlpha - midAlpha) * (_maxDqUv - _minDqUv) ~/ (maxAlpha - minAlpha);
    dqUvAcValue = dqUvAcValue * config.snsStrength ~/ 100;
    dqUvAc = _clip(dqUvAcValue, _minDqUv, _maxDqUv);
    // Chroma reacts badly to a coarse DC step - flat blocks of colour appear -
    // so its DC is pushed the other way.
    dqUvDc = _clip(-4 * config.snsStrength ~/ 100, -15, 15);

    dqY1Dc = 0;
    dqY2Dc = 0;
    dqY2Ac = 0;

    _setupFilterStrength(config);
    if (numSegments > 1) {
      _simplifySegments(segmentOfMb);
    }
    setupMatrices(config);
  }

  void _setupFilterStrength(VP8Config config) {
    // level0 spans 0..500; a filter strength of 50 is mid-filtering.
    final level0 = 5 * config.filterStrength;
    for (var i = 0; i < 4; i++) {
      final m = dqm[i];
      // What matters is how coarsely AC is quantized.
      final qstep = kAcTable[_clip(m.quant, 0, 127)] >> 2;
      final baseStrength =
          filterStrengthFromDelta(config.filterSharpness, qstep);
      // Segments with less texture are filtered less.
      final f = baseStrength * level0 ~/ (256 + m.beta);
      m.fstrength = f < _fStrengthCutoff
          ? 0
          : f > 63
              ? 63
              : f;
    }
    filterLevel = dqm[0].fstrength;
    filterSimple = config.filterType == 0;
    filterSharpness = config.filterSharpness;
  }

  /// Collapses segments that ended up with identical parameters.
  void _simplifySegments(Uint8List segmentOfMb) {
    final map = Int32List(4);
    var numFinal = 1;
    for (var s1 = 1; s1 < numSegments; s1++) {
      var found = false;
      var s2 = 0;
      for (; s2 < numFinal; s2++) {
        if (dqm[s1].equivalentTo(dqm[s2])) {
          found = true;
          break;
        }
      }
      map[s1] = s2;
      if (!found) {
        if (numFinal != s1) {
          dqm[numFinal].copyFrom(dqm[s1]);
        }
        numFinal++;
      }
    }
    if (numFinal < numSegments) {
      for (var i = 0; i < segmentOfMb.length; i++) {
        segmentOfMb[i] = map[segmentOfMb[i]];
      }
      for (var i = numFinal; i < numSegments; i++) {
        dqm[i].copyFrom(dqm[numFinal - 1]);
      }
      numSegments = numFinal;
    }
  }

  /// Builds the three matrices of each segment and the weights that go with
  /// them.
  void setupMatrices(VP8Config config) {
    final tlambdaScale = config.method >= 4 ? config.snsStrength : 0;
    for (var i = 0; i < numSegments; i++) {
      final m = dqm[i];
      final q = m.quant;
      m.y1.q[0] = kDcTable[_clip(q + dqY1Dc, 0, 127)];
      m.y1.q[1] = kAcTable[_clip(q, 0, 127)];

      m.y2.q[0] = kDcTable[_clip(q + dqY2Dc, 0, 127)] * 2;
      m.y2.q[1] = _acTable2[_clip(q + dqY2Ac, 0, 127)];

      m.uv.q[0] = kDcTable[_clip(q + dqUvDc, 0, 117)];
      m.uv.q[1] = kAcTable[_clip(q + dqUvAc, 0, 127)];

      final qI4 = m.y1.expand(0);
      final qI16 = m.y2.expand(1);
      final qUv = m.uv.expand(2);

      // Distortion is measured in squared error, rate in bits; these are the
      // exchange rates, all growing with the square of the step size.
      m
        ..lambdaI4 = _atLeast1((3 * qI4 * qI4) >> 7)
        ..lambdaI16 = _atLeast1(3 * qI16 * qI16)
        ..lambdaUv = _atLeast1((3 * qUv * qUv) >> 6)
        ..lambdaMode = _atLeast1((qI4 * qI4) >> 7)
        ..lambdaTrellisI4 = _atLeast1((7 * qI4 * qI4) >> 3)
        ..lambdaTrellisI16 = _atLeast1((qI16 * qI16) >> 2)
        ..lambdaTrellisUv = _atLeast1((qUv * qUv) << 1)
        ..tlambda = _atLeast1((tlambdaScale * qI4) >> 5)
        ..minDisto = 20 * m.y1.q[0]
        ..maxEdge = 0
        ..i4Penalty = 1000 * qI4 * qI4;
    }
  }
}

@pragma('vm:prefer-inline')
int _atLeast1(int v) => v < 1 ? 1 : v;

/// Maps the quality setting onto a compression factor.
///
/// The mapping is piecewise linear so that quality 75 lands where the
/// encoder's own middle is, then follows the cube-root law that relates file
/// size to quantizer step.
double _qualityToCompression(double c) {
  final linearC = c < 0.75 ? c * (2 / 3) : 2 * c - 1;
  return math.pow(linearC, 1 / 3).toDouble();
}

/// The same mapping fitted to libjpeg's size curve, so that a given quality
/// produces a file of roughly the size JPEG would.
double _qualityToJpegCompression(double c, double alpha) {
  const aMin = 0.30;
  const aMax = 0.85;
  const expMin = 0.4;
  const expMax = 0.9;
  const slope = (expMin - expMax) / (aMax - aMin);
  final expn = alpha > aMax
      ? expMin
      : alpha < aMin
          ? expMax
          : expMax + slope * (alpha - aMin);
  return math.pow(c, expn).toDouble();
}
