/// Choosing how to code one macroblock.
///
/// For every candidate mode the encoder reconstructs the block exactly as the
/// decoder would, measures how far the result is from the source, prices the
/// bits it would take, and keeps the mode with the lowest rate-distortion
/// score. The lambda that converts bits into distortion comes from the
/// quantizer, so a coarsely quantized picture is willing to spend fewer bits
/// on the same amount of error.
library;

import 'dart:typed_data';

import '../../util/_internal.dart';
import 'vp8_config.dart';
import 'vp8_cost_tables.dart';
import 'vp8_dsp.dart';
import 'vp8_iterator.dart';
import 'vp8_proba.dart';
import 'vp8_quant.dart';
import 'vp8_residual.dart';
import 'vp8_sar.dart';
import 'vp8_state.dart';
import 'vp8_tables.dart';

/// Larger than any real score, but small enough that scores can be added to it
/// without leaving the range an int is exact to on the web, where an int is a
/// double.
///
/// Written out rather than as `1 << 50`: on the web `<<` is a 32-bit shift, so
/// that expression is zero there, and a zero ceiling makes every mode lose its
/// comparison and the search return no mode at all.
const maxCost = 1125899906842624; // 2^50

/// How much a unit of distortion weighs against a bit.
const _rdDistoMult = 256;

/// The four 16x16 luma modes, and the four chroma modes.
const _numPredModes = 4;

// A block with few non-zero coefficients is "flat"; complex predictions that
// happen to fit such a block tend to look worse than the simple ones, so they
// are penalised.
const _flatnessLimitI16 = 0;
const _flatnessLimitI4 = 3;
const _flatnessLimitUV = 2;
const _flatnessPenalty = 140;

/// Weights of the spectral distortion, matching [distoFrom].
const _weightTrellis = [
  30, 27, 19, 11, //
  27, 24, 17, 10,
  19, 17, 12, 8,
  11, 10, 8, 6
];

/// The decisions and coefficients of one candidate coding of a macroblock.
@internal
class VP8ModeScore {
  /// Squared error, and spectral distortion.
  int d = 0;
  int sd = 0;

  /// Cost of the header bits (the mode itself) and of the coefficients.
  int h = 0;
  int r = 0;

  /// `(r + h) * lambda + distortion`.
  int score = 0;

  /// Quantized levels: the luma DC block, the sixteen luma blocks, and the
  /// four U then four V blocks.
  final yDcLevels = Int16List(16);
  final yAcLevels = Int16List(16 * 16);
  final uvLevels = Int16List(8 * 16);

  int modeI16 = 0;
  final modesI4 = Uint8List(16);
  int modeUv = 0;

  /// The three chroma DC errors this coding passes to its neighbours, U then
  /// V. Only kept when error diffusion is on.
  final derr = Int8List(6);

  /// One bit per block that has a non-zero coefficient, in the layout
  /// [VP8EncIterator.nzToBytes] describes.
  int nz = 0;

  void init() {
    d = 0;
    sd = 0;
    r = 0;
    h = 0;
    nz = 0;
    score = maxCost;
  }

  /// Copies the score fields only, leaving the levels alone.
  void copyScore(VP8ModeScore src) {
    d = src.d;
    sd = src.sd;
    r = src.r;
    h = src.h;
    nz = src.nz;
    score = src.score;
  }

  void addScore(VP8ModeScore src) {
    d += src.d;
    sd += src.sd;
    r += src.r;
    h += src.h;
    nz |= src.nz;
    score += src.score;
  }

  void copyFrom(VP8ModeScore src) {
    copyScore(src);
    yDcLevels.setAll(0, src.yDcLevels);
    yAcLevels.setAll(0, src.yAcLevels);
    uvLevels.setAll(0, src.uvLevels);
    modeI16 = src.modeI16;
    modesI4.setAll(0, src.modesI4);
    modeUv = src.modeUv;
  }
}

@pragma('vm:prefer-inline')
int _mult8b(int a, int b) => (a * b + 128) >> 8;

@pragma('vm:prefer-inline')
void _setRDScore(int lambda, VP8ModeScore rd) {
  rd.score = (rd.r + rd.h) * lambda + _rdDistoMult * (rd.d + rd.sd);
}

@pragma('vm:prefer-inline')
int _rdScoreTrellis(int lambda, int rate, int distortion) =>
    rate * lambda + _rdDistoMult * distortion;

/// The mode search, and the reconstruction it needs to judge a mode.
///
/// One instance is reused for the whole picture: every buffer a search step
/// needs is a field here, so that coding a macroblock allocates nothing.
@internal
class VP8Decimate {
  VP8Decimate(this.enc, this.it);

  final VP8EncState enc;
  final VP8EncIterator it;

  // Scratch coefficients: the sixteen luma blocks, their DC block, and one
  // spare block for the 4x4 search.
  final _tmp = Int16List(16 * 16);
  final _dcTmp = Int16List(16);
  final _tmpLevels = Int16List(16);

  final _rdTmp = VP8ModeScore();
  final _rdI4 = VP8ModeScore();
  final _rdBestI4 = VP8ModeScore();
  final _rdUv = VP8ModeScore();
  final _rdBestUv = VP8ModeScore();
  final _rdCandidate = VP8ModeScore();
  final _res = VP8Residual();

  /// The spectrum of each 4x4 block of the source macroblock. The mode search
  /// compares every candidate against these, and the source does not change
  /// while it does, so they are measured once per macroblock.
  final _srcSpectrum = Int32List(16);
  bool _srcSpectrumValid = false;

  // Trellis state: two candidate levels per coefficient, and one node per
  // (coefficient, candidate).
  final _nodePrev = Int8List(32);
  final _nodeSign = Int8List(32);
  final _nodeLevel = Int16List(32);
  // A plain list, not an Int64List: the web has no 64-bit integer array, and
  // these four values are read and written constantly anyway.
  final _stateScore = List<int>.filled(4, 0);
  final _stateCost = Int32List(4);

  /// Picks modes and levels for the current macroblock. Returns true if the
  /// macroblock ended up with no coefficients at all.
  bool run(VP8ModeScore rd, int rdOpt) {
    rd.init();

    // The 16x16 and chroma predictions do not depend on the coding of this
    // macroblock, so they can all be made once; the 4x4 ones cannot, since
    // each block predicts from the reconstruction of the last.
    _makeLuma16Preds();
    _makeChroma8Preds();
    _srcSpectrumValid = false;

    if (rdOpt > VP8Config.rdOptNone) {
      it.doTrellis = rdOpt >= VP8Config.rdOptTrellisAll;
      _pickBestIntra16(rd);
      if (enc.config.method >= 2) {
        _pickBestIntra4(rd);
      }
      _pickBestUV(rd);
      if (rdOpt == VP8Config.rdOptTrellis) {
        // Redo the winner with the trellis on.
        it.doTrellis = true;
        _simpleQuantize(rd);
      }
    } else {
      _refineUsingDistortion(rd,
          tryBothModes: enc.config.method >= 2,
          refineUvMode: enc.config.method >= 1);
    }
    final isSkipped = rd.nz == 0;
    it.setSkip(isSkipped);
    return isSkipped;
  }

  /// Measures the source spectra, once per macroblock.
  @pragma('vm:unsafe:no-bounds-checks')
  void _measureSourceSpectrum() {
    if (_srcSpectrumValid) {
      return;
    }
    for (var n = 0; n < 16; n++) {
      _srcSpectrum[n] = spectrum4x4(it.yuvIn, yOffEnc + kScan[n]);
    }
    _srcSpectrumValid = true;
  }

  void _makeLuma16Preds() {
    predLuma16(it.yuvP, it.x != 0 ? it.yLeft : null, VP8EncIterator.yLeftOff,
        it.y != 0 ? it.yTop : null, it.yTopPos);
  }

  void _makeChroma8Preds() {
    predChroma8(it.yuvP, it.x != 0 ? it.uvLeft : null, VP8EncIterator.uLeftOff,
        it.y != 0 ? it.uvTop : null, it.uvTopPos);
  }

  void _makeIntra4Preds() {
    predLuma4(it.yuvP, it.i4Boundary, it.i4Top);
  }

  //----------------------------------------------------------------------------
  // Reconstruction.

  /// Transforms, quantizes and reconstructs a whole macroblock as intra 16x16.
  ///
  /// The DC of each of the sixteen blocks is collected into a seventeenth
  /// block and transformed again, which is what makes flat areas cheap.
  @pragma('vm:unsafe:no-bounds-checks')
  int _reconstructIntra16(VP8ModeScore rd, Uint8List yuvOut, int mode) {
    final ref = kI16ModeOffsets[mode];
    const src = yOffEnc;
    final dqm = enc.quant.dqm[it.segment];
    var nz = 0;

    for (var n = 0; n < 16; n += 2) {
      fTransform2(
          it.yuvIn, src + kScan[n], it.yuvP, ref + kScan[n], _tmp, n * 16);
    }
    fTransformWHT(_tmp, 0, _dcTmp, 0);
    nz |=
        (quantizeBlock(_dcTmp, 0, rd.yDcLevels, 0, dqm.y2) >= 0 ? 1 : 0) << 24;

    if (it.doTrellis) {
      it.nzToBytes();
      var n = 0;
      for (var y = 0; y < 4; y++) {
        for (var x = 0; x < 4; x++, n++) {
          final ctx = it.topNz[x] + it.leftNz[y];
          final nonZero = _trellisQuantizeBlock(_tmp, n * 16, rd.yAcLevels,
              n * 16, ctx, typeI16AC, dqm.y1, dqm.lambdaTrellisI16);
          it.topNz[x] = it.leftNz[y] = nonZero;
          rd.yAcLevels[n * 16] = 0;
          nz |= nonZero << n;
        }
      }
    } else {
      for (var n = 0; n < 16; n += 2) {
        // The DC is carried by the second transform, so zero it here: it keeps
        // the non-zero flag honest and shortens the search for the last
        // coefficient.
        _tmp[n * 16] = 0;
        _tmp[(n + 1) * 16] = 0;
        nz |= quantize2Blocks(_tmp, n * 16, rd.yAcLevels, n * 16, dqm.y1) << n;
      }
    }

    transformWHT(_dcTmp, 0, _tmp, 0);
    for (var n = 0; n < 16; n += 2) {
      iTransform2(
          it.yuvP, ref + kScan[n], _tmp, n * 16, yuvOut, yOffEnc + kScan[n]);
    }
    return nz;
  }

  /// The same for one 4x4 block, whose prediction is made as we go.
  @pragma('vm:unsafe:no-bounds-checks')
  int _reconstructIntra4(Int16List levels, int levelsOff, int srcOff,
      Uint8List yuvOut, int outOff, int mode) {
    final ref = kI4ModeOffsets[mode];
    final dqm = enc.quant.dqm[it.segment];
    fTransform(it.yuvIn, srcOff, it.yuvP, ref, _tmpLevels, 0);
    // Reusing _tmp as the coefficient scratch would clash with the 16x16
    // search, so the 4x4 path keeps its own block.
    final coeffs = _tmpLevels;
    int nz;
    if (it.doTrellis) {
      final x = it.i4 & 3;
      final y = it.i4 >> 2;
      final ctx = it.topNz[x] + it.leftNz[y];
      nz = _trellisQuantizeBlock(coeffs, 0, levels, levelsOff, ctx, typeI4AC,
          dqm.y1, dqm.lambdaTrellisI4);
    } else {
      nz = quantizeBlock(coeffs, 0, levels, levelsOff, dqm.y1) >= 0 ? 1 : 0;
    }
    iTransform(it.yuvP, ref, coeffs, 0, yuvOut, outOff);
    return nz;
  }

  /// And for the eight chroma blocks of a macroblock.
  @pragma('vm:unsafe:no-bounds-checks')
  int _reconstructUV(VP8ModeScore rd, Uint8List yuvOut, int mode) {
    final ref = kUVModeOffsets[mode];
    const src = uOffEnc;
    final dqm = enc.quant.dqm[it.segment];
    var nz = 0;

    for (var n = 0; n < 8; n += 2) {
      fTransform2(
          it.yuvIn, src + kScanUV[n], it.yuvP, ref + kScanUV[n], _tmp, n * 16);
    }
    if (enc.topDerr != null) {
      _correctDCValues(rd, dqm.uv);
    }
    for (var n = 0; n < 8; n += 2) {
      nz |= quantize2Blocks(_tmp, n * 16, rd.uvLevels, n * 16, dqm.uv) << n;
    }
    for (var n = 0; n < 8; n += 2) {
      iTransform2(it.yuvP, ref + kScanUV[n], _tmp, n * 16, yuvOut,
          uOffEnc + kScanUV[n]);
    }
    return nz << 16;
  }

  //----------------------------------------------------------------------------
  // Chroma DC error diffusion.
  //
  // The four chroma blocks of one channel sit in a 2x2 square. Each takes the
  // error left over from its neighbours above and to the left before being
  // quantized, and passes its own on:
  //
  //           | top[0] | top[1]
  //   --------+--------+--------
  //   left[0] |  err0     err1
  //   left[1] |  err2     err3
  //
  // Only 15/16ths of the error is passed on. libwebp under-corrects on purpose:
  // diffusing all of it makes a chessboard of blocks appear at the very bottom
  // of the quality range.

  /// Fraction of the error sent to the block below, out of 1 << [_dShift].
  static const _c1 = 7;

  /// And to the block on the right.
  static const _c2 = 8;
  static const _dShift = 4;

  /// Nudges the four DC coefficients of each chroma channel by the error its
  /// neighbours left, and records what this macroblock passes on.
  @pragma('vm:unsafe:no-bounds-checks')
  void _correctDCValues(VP8ModeScore rd, VP8Matrix mtx) {
    final top = enc.topDerr!;
    final left = it.leftDerr;
    for (var ch = 0; ch <= 1; ch++) {
      final t = it.x * 4 + ch * 2;
      final l = ch * 2;
      // The four DC coefficients are at the head of blocks 0..3 of this
      // channel, and the two channels are four blocks apart.
      final b = ch * 4 * 16;
      const s = _dShift - errorDescale;

      _tmp[b] += sar(_c1 * top[t] + _c2 * left[l], s);
      final err0 = quantizeSingleDC(_tmp, b, mtx);
      _tmp[b + 16] += sar(_c1 * top[t + 1] + _c2 * err0, s);
      final err1 = quantizeSingleDC(_tmp, b + 16, mtx);
      _tmp[b + 32] += sar(_c1 * err0 + _c2 * left[l + 1], s);
      final err2 = quantizeSingleDC(_tmp, b + 32, mtx);
      _tmp[b + 48] += sar(_c1 * err1 + _c2 * err2, s);
      final err3 = quantizeSingleDC(_tmp, b + 48, mtx);

      // The error cannot exceed the DC step size, at most 132, so descaling by
      // one keeps it inside a signed byte.
      assert(err1.abs() <= 127 && err2.abs() <= 127 && err3.abs() <= 127);
      rd.derr[ch * 3] = err1;
      rd.derr[ch * 3 + 1] = err2;
      rd.derr[ch * 3 + 2] = err3;
    }
  }

  /// Hands the winning mode's errors to the neighbours still to be coded.
  @pragma('vm:unsafe:no-bounds-checks')
  void _storeDiffusionErrors(VP8ModeScore rd) {
    final top = enc.topDerr!;
    final left = it.leftDerr;
    for (var ch = 0; ch <= 1; ch++) {
      final t = it.x * 4 + ch * 2;
      final l = ch * 2;
      left[l] = rd.derr[ch * 3]; // err1, to the block on the right
      // Three quarters of err3, which is signed.
      left[l + 1] = sar(3 * rd.derr[ch * 3 + 2], 2);
      top[t] = rd.derr[ch * 3 + 1]; // err2, to the block below
      top[t + 1] = rd.derr[ch * 3 + 2] - left[l + 1]; // the last quarter
    }
  }

  //----------------------------------------------------------------------------
  // Trellis quantization.

  /// Chooses the levels of one block by dynamic programming rather than by
  /// rounding each coefficient on its own.
  ///
  /// Rounding is greedy: it cannot see that dropping one coefficient to zero
  /// shortens the block and pays for itself. This walks the coefficients in
  /// order, keeping for each the best path that ends there, and takes the best
  /// ending position at the end.
  @pragma('vm:unsafe:no-bounds-checks')
  int _trellisQuantizeBlock(Int16List inp, int inOff, Int16List out, int outOff,
      int ctx0, int coeffType, VP8Matrix mtx, int lambda) {
    final proba = enc.proba;
    final probas = proba.coeffs;
    final costBase = proba.costBase;
    final first = coeffType == typeI16AC ? 1 : 0;
    var bestPathLast = -1;
    var bestPathNode = -1;
    var bestPathPrev = -1;
    int bestScore;

    // Only two candidates per coefficient: the rounded level and one above it.
    // Levels below never win, since they cost as much and distort more.
    const minDelta = 0;
    const maxDelta = 1;
    var ssCur = 0; // index into _stateScore/_stateCost of the current pair
    var ssPrev = 2;

    var last = first - 1;
    {
      final thresh = mtx.q[1] * mtx.q[1] ~/ 4;
      final lastProba = probas[_probaIndex(coeffType, kBands[first], ctx0)];
      for (var n = 15; n >= first; n--) {
        final j = kZigzag[n];
        final err = inp[inOff + j] * inp[inOff + j];
        if (err > thresh) {
          last = n;
          break;
        }
      }
      if (last < 15) {
        last++;
      }
      // Coding nothing at all is the score to beat.
      bestScore = _rdScoreTrellis(lambda, bitCost(0, lastProba), 0);
      final rate = ctx0 == 0 ? bitCost(1, lastProba) : 0;
      for (var m = 0; m <= maxDelta; m++) {
        _stateScore[ssCur + m] = _rdScoreTrellis(lambda, rate, 0);
        _stateCost[ssCur + m] =
            costBase[(coeffType * 16 + first) * numCtx + ctx0];
      }
    }

    for (var n = first; n <= last; n++) {
      final j = kZigzag[n];
      final q = mtx.q[j];
      final iq = mtx.iq[j];
      final v = inp[inOff + j];
      final sign = v < 0 ? 1 : 0;
      final coeff0 = (v < 0 ? -v : v) + mtx.sharpen[j];
      // A neutral bias, so the two candidates bracket the true value.
      var level0 = (coeff0 * iq) >> 17;
      var threshLevel = (coeff0 * iq + (0x80 << 9)) >> 17;
      if (threshLevel > maxLevel) {
        threshLevel = maxLevel;
      }
      if (level0 > maxLevel) {
        level0 = maxLevel;
      }

      final tmp = ssCur;
      ssCur = ssPrev;
      ssPrev = tmp;

      for (var m = 0; m <= maxDelta; m++) {
        final node = n * 2 + m;
        final level = level0 + m;
        final ctx = level > 2 ? 2 : level;
        final band = kBands[n + 1];

        // The cost table of the following position, which the next round
        // prices its level against. There is no round after the sixteenth
        // coefficient, so nothing reads it there.
        _stateCost[ssCur + m] =
            n < 15 ? costBase[(coeffType * 16 + n + 1) * numCtx + ctx] : 0;
        if (level < 0 || level > threshLevel) {
          _stateScore[ssCur + m] = maxCost;
          continue;
        }

        // How much coding this level takes off the error of dropping it.
        final newError = coeff0 - level * q;
        final deltaError =
            _weightTrellis[j] * (newError * newError - coeff0 * coeff0);
        final baseScore = _rdScoreTrellis(lambda, 0, deltaError);

        var cost = proba.levelCostAt(_stateCost[ssPrev + minDelta], level);
        var bestCurScore =
            _stateScore[ssPrev + minDelta] + _rdScoreTrellis(lambda, cost, 0);
        var bestPrev = minDelta;
        for (var p = minDelta + 1; p <= maxDelta; p++) {
          cost = proba.levelCostAt(_stateCost[ssPrev + p], level);
          final score =
              _stateScore[ssPrev + p] + _rdScoreTrellis(lambda, cost, 0);
          if (score < bestCurScore) {
            bestCurScore = score;
            bestPrev = p;
          }
        }
        bestCurScore += baseScore;

        _nodeSign[node] = sign;
        _nodeLevel[node] = level;
        _nodePrev[node] = bestPrev;
        _stateScore[ssCur + m] = bestCurScore;

        // Could the block end here?
        if (level != 0 && bestCurScore < bestScore) {
          final lastPosCost = n < 15
              ? bitCost(0, probas[_probaIndex(coeffType, band, ctx)])
              : 0;
          final score = bestCurScore + _rdScoreTrellis(lambda, lastPosCost, 0);
          if (score < bestScore) {
            bestScore = score;
            bestPathLast = n;
            bestPathNode = m;
            bestPathPrev = bestPrev;
          }
        }
      }
    }

    // The DC of an intra 16x16 block is not ours to touch.
    if (coeffType == typeI16AC) {
      inp.fillRange(inOff + 1, inOff + 16, 0);
      out.fillRange(outOff + 1, outOff + 16, 0);
    } else {
      inp.fillRange(inOff, inOff + 16, 0);
      out.fillRange(outOff, outOff + 16, 0);
    }
    if (bestPathLast == -1) {
      return 0; // the whole block is dropped
    }

    var nz = 0;
    var node = bestPathNode;
    var n = bestPathLast;
    // The predecessor of the terminal node is not always the one stored.
    _nodePrev[n * 2 + node] = bestPathPrev;
    for (; n >= first; n--) {
      final at = n * 2 + node;
      final level = _nodeLevel[at];
      final j = kZigzag[n];
      out[outOff + n] = _nodeSign[at] != 0 ? -level : level;
      nz |= level;
      inp[inOff + j] = out[outOff + n] * mtx.q[j];
      node = _nodePrev[at];
    }
    return nz != 0 ? 1 : 0;
  }

  @pragma('vm:prefer-inline')
  static int _probaIndex(int type, int band, int ctx) =>
      ((type * numBands + band) * numCtx + ctx) * numProbas;

  //----------------------------------------------------------------------------
  // Rate.

  @pragma('vm:unsafe:no-bounds-checks')
  int _getCostLuma16(VP8ModeScore rd) {
    final proba = enc.proba;
    var r = 0;
    it.nzToBytes();

    _res
      ..init(0, typeI16DC)
      ..setCoeffs(rd.yDcLevels, 0);
    r += getResidualCost(proba, _res, it.topNz[8] + it.leftNz[8]);

    _res.init(1, typeI16AC);
    for (var y = 0; y < 4; y++) {
      for (var x = 0; x < 4; x++) {
        final ctx = it.topNz[x] + it.leftNz[y];
        _res.setCoeffs(rd.yAcLevels, (x + y * 4) * 16);
        r += getResidualCost(proba, _res, ctx);
        it.topNz[x] = it.leftNz[y] = _res.last >= 0 ? 1 : 0;
      }
    }
    return r;
  }

  @pragma('vm:unsafe:no-bounds-checks')
  int _getCostLuma4(Int16List levels) {
    final x = it.i4 & 3;
    final y = it.i4 >> 2;
    _res
      ..init(0, typeI4AC)
      ..setCoeffs(levels, 0);
    return getResidualCost(enc.proba, _res, it.topNz[x] + it.leftNz[y]);
  }

  @pragma('vm:unsafe:no-bounds-checks')
  int _getCostUV(VP8ModeScore rd) {
    final proba = enc.proba;
    var r = 0;
    it.nzToBytes();

    _res.init(0, typeChroma);
    for (var ch = 0; ch <= 2; ch += 2) {
      for (var y = 0; y < 2; y++) {
        for (var x = 0; x < 2; x++) {
          final ctx = it.topNz[4 + ch + x] + it.leftNz[4 + ch + y];
          _res.setCoeffs(rd.uvLevels, (ch * 2 + x + y * 2) * 16);
          r += getResidualCost(proba, _res, ctx);
          it.topNz[4 + ch + x] = it.leftNz[4 + ch + y] = _res.last >= 0 ? 1 : 0;
        }
      }
    }
    return r;
  }

  //----------------------------------------------------------------------------
  // Mode search.

  @pragma('vm:unsafe:no-bounds-checks')
  void _pickBestIntra16(VP8ModeScore rd) {
    final dqm = enc.quant.dqm[it.segment];
    final lambda = dqm.lambdaI16;
    final tlambda = dqm.tlambda;
    const src = yOffEnc;
    var rdCur = _rdTmp;
    var rdBest = rd;
    var isFlatBlock = isFlatSource16(it.yuvIn, src);
    if (tlambda != 0) {
      _measureSourceSpectrum();
    }

    rd.modeI16 = -1;
    for (var mode = 0; mode < _numPredModes; mode++) {
      final tmpDst = it.yuvOut2;
      rdCur.modeI16 = mode;
      rdCur.nz = _reconstructIntra16(rdCur, tmpDst, mode);

      rdCur
        ..d = getSSE(it.yuvIn, src, tmpDst, src, 16, 16)
        ..sd = tlambda != 0 ? _mult8b(tlambda, _disto16(tmpDst)) : 0
        ..h = kFixedCostsI16[mode];
      rdCur.r = _getCostLuma16(rdCur);
      if (isFlatBlock) {
        // The first impression was made on the pixels; now that the levels are
        // known, confirm it.
        isFlatBlock = isFlat(rdCur.yAcLevels, 0, 16, _flatnessLimitI16);
        if (isFlatBlock) {
          // Any error at all is conspicuous on a flat block.
          rdCur
            ..d *= 2
            ..sd *= 2;
        }
      }

      _setRDScore(lambda, rdCur);
      if (mode == 0 || rdCur.score < rdBest.score) {
        final tmp = rdCur;
        rdCur = rdBest;
        rdBest = tmp;
        it.swapOut();
      }
    }
    if (!identical(rdBest, rd)) {
      rd.copyFrom(rdBest);
    }
    // Re-score with the mode-decision lambda, which is what intra4 compares
    // itself against.
    _setRDScore(dqm.lambdaMode, rd);
    it.setIntra16Mode(rd.modeI16);

    // A macroblock where only the DC survived, yet which is still far from the
    // source, is a candidate for blocking artefacts; remember how large its
    // steps were so the filter strength can be raised later.
    if ((rd.nz & 0x100ffff) == 0x1000000 && rd.d > dqm.minDisto) {
      _storeMaxDelta(dqm, rd.yDcLevels);
    }
  }

  /// The spectral distance of a whole macroblock from the source.
  @pragma('vm:unsafe:no-bounds-checks')
  int _disto16(Uint8List candidate) {
    var d = 0;
    for (var n = 0; n < 16; n++) {
      d += distoFrom(_srcSpectrum[n], candidate, yOffEnc + kScan[n]);
    }
    return d;
  }

  static void _storeMaxDelta(VP8SegmentInfo dqm, Int16List dcs) {
    final d0 = dcs[1];
    final d1 = dcs[2];
    final d2 = dcs[4];
    final v0 = d0 < 0 ? -d0 : d0;
    final v1 = d1 < 0 ? -d1 : d1;
    final v2 = d2 < 0 ? -d2 : d2;
    var maxV = v1 > v0 ? v1 : v0;
    maxV = v2 > maxV ? v2 : maxV;
    if (maxV > dqm.maxEdge) {
      dqm.maxEdge = maxV;
    }
  }

  /// The cost table for the current 4x4 block, given its neighbours' modes.
  @pragma('vm:unsafe:no-bounds-checks')
  List<int> _getCostModeI4(Uint8List modes) {
    final predsW = enc.predsW;
    final x = it.i4 & 3;
    final y = it.i4 >> 2;
    final left =
        x == 0 ? enc.preds[it.predsPos + y * predsW - 1] : modes[it.i4 - 1];
    final top = y == 0 ? enc.preds[it.predsPos - predsW + x] : modes[it.i4 - 4];
    return kFixedCostsI4[top][left];
  }

  /// Tries coding the luma as sixteen 4x4 blocks. Returns true if that beats
  /// the 16x16 coding already in [rd].
  @pragma('vm:unsafe:no-bounds-checks')
  bool _pickBestIntra4(VP8ModeScore rd) {
    final dqm = enc.quant.dqm[it.segment];
    final lambda = dqm.lambdaI4;
    final tlambda = dqm.tlambda;
    const src0 = yOffEnc;
    var totalHeaderBits = 0;
    final rdBest = _rdBestI4;

    if (enc.maxI4HeaderBits == 0) {
      return false;
    }

    rdBest
      ..init()
      // The cost of the bit that says "not 16x16".
      ..h = 211;
    _setRDScore(dqm.lambdaMode, rdBest);
    it.startI4();
    do {
      final src = src0 + kScan[it.i4];
      final modeCosts = _getCostModeI4(rd.modesI4);
      var bestMode = -1;
      // The winner of each block is kept in yuv_out2, the candidate in a
      // scratch corner of the prediction area.
      var bestBlockBuf = it.yuvOut2;
      var bestBlock = yOffEnc + kScan[it.i4];
      var tmpBuf = it.yuvP;
      var tmpDst = i4TMP;

      _rdI4.init();
      _makeIntra4Preds();
      final srcSpectrum = tlambda != 0 ? spectrum4x4(it.yuvIn, src) : 0;
      for (var mode = 0; mode < numBModes; mode++) {
        _rdCandidate
          ..nz =
              _reconstructIntra4(_tmpLevelsOut, 0, src, tmpBuf, tmpDst, mode) <<
                  it.i4
          ..d = getSSE4x4(it.yuvIn, src, tmpBuf, tmpDst)
          ..sd = tlambda != 0
              ? _mult8b(tlambda, distoFrom(srcSpectrum, tmpBuf, tmpDst))
              : 0
          ..h = modeCosts[mode]
          // A complex mode that lands on a flat block is usually a
          // mis-prediction; make it pay for the privilege.
          ..r = mode > 0 && isFlat(_tmpLevelsOut, 0, 1, _flatnessLimitI4)
              ? _flatnessPenalty
              : 0;

        _setRDScore(lambda, _rdCandidate);
        if (bestMode >= 0 && _rdCandidate.score >= _rdI4.score) {
          continue;
        }

        _rdCandidate.r += _getCostLuma4(_tmpLevelsOut);
        _setRDScore(lambda, _rdCandidate);

        if (bestMode < 0 || _rdCandidate.score < _rdI4.score) {
          _rdI4.copyScore(_rdCandidate);
          bestMode = mode;
          final swapBuf = tmpBuf;
          final swapOff = tmpDst;
          tmpBuf = bestBlockBuf;
          tmpDst = bestBlock;
          bestBlockBuf = swapBuf;
          bestBlock = swapOff;
          rdBest.yAcLevels.setRange(it.i4 * 16, it.i4 * 16 + 16, _tmpLevelsOut);
        }
      }
      _setRDScore(dqm.lambdaMode, _rdI4);
      rdBest.addScore(_rdI4);
      if (rdBest.score >= rd.score) {
        return false;
      }
      totalHeaderBits += _rdI4.h;
      if (totalHeaderBits > enc.maxI4HeaderBits) {
        return false;
      }
      // Move the winning block where the next one expects to predict from.
      if (!identical(bestBlockBuf, it.yuvOut2) ||
          bestBlock != yOffEnc + kScan[it.i4]) {
        copy4x4(bestBlockBuf, bestBlock, it.yuvOut2, yOffEnc + kScan[it.i4]);
      }
      rd.modesI4[it.i4] = bestMode;
      it.topNz[it.i4 & 3] = it.leftNz[it.i4 >> 2] = _rdI4.nz != 0 ? 1 : 0;
    } while (it.rotateI4(it.yuvOut2, yOffEnc));

    rd.copyScore(rdBest);
    it
      ..setIntra4Mode(rd.modesI4)
      ..swapOut();
    rd.yAcLevels.setAll(0, rdBest.yAcLevels);
    return true;
  }

  /// Levels of the 4x4 block being tried.
  final _tmpLevelsOut = Int16List(16);

  @pragma('vm:unsafe:no-bounds-checks')
  void _pickBestUV(VP8ModeScore rd) {
    final dqm = enc.quant.dqm[it.segment];
    final lambda = dqm.lambdaUv;
    const src = uOffEnc;
    final rdBest = _rdBestUv;
    var dstBuf = it.yuvOut;
    var tmpBuf = it.yuvOut2;

    rd.modeUv = -1;
    rdBest.init();
    for (var mode = 0; mode < _numPredModes; mode++) {
      _rdUv.nz = _reconstructUV(_rdUv, tmpBuf, mode);

      _rdUv.d = getSSE(it.yuvIn, src, tmpBuf, src, 16, 8);
      // No spectral term here: on chroma it tends to flatten areas out.
      _rdUv.sd = 0;
      _rdUv.h = kFixedCostsUV[mode];
      _rdUv.r = _getCostUV(_rdUv);
      if (mode > 0 && isFlat(_rdUv.uvLevels, 0, 8, _flatnessLimitUV)) {
        _rdUv.r += _flatnessPenalty * 8;
      }

      _setRDScore(lambda, _rdUv);
      if (mode == 0 || _rdUv.score < rdBest.score) {
        rdBest.copyScore(_rdUv);
        rd.modeUv = mode;
        rd.uvLevels.setAll(0, _rdUv.uvLevels);
        if (enc.topDerr != null) {
          rd.derr.setAll(0, _rdUv.derr);
        }
        final tmp = dstBuf;
        dstBuf = tmpBuf;
        tmpBuf = tmp;
      }
    }
    it.setIntraUVMode(rd.modeUv);
    rd.addScore(rdBest);
    if (!identical(dstBuf, it.yuvOut)) {
      copy16x8(dstBuf, uOffEnc, it.yuvOut, uOffEnc);
    }
    if (enc.topDerr != null) {
      _storeDiffusionErrors(rd);
    }
  }

  /// Recodes the macroblock with the modes already chosen, this time with the
  /// trellis switched on.
  @pragma('vm:unsafe:no-bounds-checks')
  void _simpleQuantize(VP8ModeScore rd) {
    final isI16 = it.mbType == 1;
    var nz = 0;

    if (isI16) {
      nz = _reconstructIntra16(rd, it.yuvOut, enc.preds[it.predsPos]);
    } else {
      it.startI4();
      do {
        final mode =
            enc.preds[it.predsPos + (it.i4 & 3) + (it.i4 >> 2) * enc.predsW];
        final src = yOffEnc + kScan[it.i4];
        final dst = yOffEnc + kScan[it.i4];
        _makeIntra4Preds();
        nz |= _reconstructIntra4(
                rd.yAcLevels, it.i4 * 16, src, it.yuvOut, dst, mode) <<
            it.i4;
      } while (it.rotateI4(it.yuvOut, yOffEnc));
    }

    nz |= _reconstructUV(rd, it.yuvOut, it.uvMode);
    rd.nz = nz;
  }

  /// The cheap path: pick modes by distortion alone, with a fixed penalty
  /// standing in for the rate.
  @pragma('vm:unsafe:no-bounds-checks')
  void _refineUsingDistortion(VP8ModeScore rd,
      {required bool tryBothModes, required bool refineUvMode}) {
    var bestScore = maxCost;
    var nz = 0;
    var tryBoth = tryBothModes;
    var isI16 = tryBoth || it.mbType == 1;
    final dqm = enc.quant.dqm[it.segment];

    // Empirical exchange rates, of about the right order of magnitude.
    const lambdaDI16 = 106;
    const lambdaDI4 = 11;
    const lambdaDUv = 120;
    var scoreI4 = dqm.i4Penalty;
    var i4BitSum = 0;
    final bitLimit = tryBoth ? enc.mbHeaderLimit : maxCost;

    if (isI16) {
      var bestMode = -1;
      const src = yOffEnc;
      for (var mode = 0; mode < _numPredModes; mode++) {
        final ref = kI16ModeOffsets[mode];
        final score =
            getSSE(it.yuvIn, src, it.yuvP, ref, 16, 16) * _rdDistoMult +
                kFixedCostsI16[mode] * lambdaDI16;
        if (mode > 0 && kFixedCostsI16[mode] > bitLimit) {
          continue;
        }
        if (score < bestScore) {
          bestMode = mode;
          bestScore = score;
        }
      }
      if (it.x == 0 || it.y == 0) {
        // On the border a flat block can start a checkerboard that then
        // resonates across the picture; force the mode that cannot.
        if (isFlatSource16(it.yuvIn, src)) {
          bestMode = it.x == 0 ? 0 : 2;
          tryBoth = false;
        }
      }
      it.setIntra16Mode(bestMode);
    }

    if (tryBoth || !isI16) {
      isI16 = false;
      it.startI4();
      do {
        var bestI4Mode = -1;
        var bestI4Score = maxCost;
        final src = yOffEnc + kScan[it.i4];
        final modeCosts = _getCostModeI4(rd.modesI4);

        _makeIntra4Preds();
        for (var mode = 0; mode < numBModes; mode++) {
          final ref = kI4ModeOffsets[mode];
          final score =
              getSSE(it.yuvIn, src, it.yuvP, ref, 4, 4) * _rdDistoMult +
                  modeCosts[mode] * lambdaDI4;
          if (score < bestI4Score) {
            bestI4Mode = mode;
            bestI4Score = score;
          }
        }
        i4BitSum += modeCosts[bestI4Mode];
        rd.modesI4[it.i4] = bestI4Mode;
        scoreI4 += bestI4Score;
        if (scoreI4 >= bestScore || i4BitSum > bitLimit) {
          // Intra4 cannot win any more; stop and keep intra16.
          isI16 = true;
          break;
        }
        final tmpDst = yOffEnc + kScan[it.i4];
        nz |= _reconstructIntra4(rd.yAcLevels, it.i4 * 16, src, it.yuvOut2,
                tmpDst, bestI4Mode) <<
            it.i4;
      } while (it.rotateI4(it.yuvOut2, yOffEnc));
    }

    if (!isI16) {
      it
        ..setIntra4Mode(rd.modesI4)
        ..swapOut();
      bestScore = scoreI4;
    } else {
      nz = _reconstructIntra16(rd, it.yuvOut, enc.preds[it.predsPos]);
    }

    if (refineUvMode) {
      var bestMode = -1;
      var bestUvScore = maxCost;
      const src = uOffEnc;
      for (var mode = 0; mode < _numPredModes; mode++) {
        final ref = kUVModeOffsets[mode];
        final score =
            getSSE(it.yuvIn, src, it.yuvP, ref, 16, 8) * _rdDistoMult +
                kFixedCostsUV[mode] * lambdaDUv;
        if (score < bestUvScore) {
          bestMode = mode;
          bestUvScore = score;
        }
      }
      it.setIntraUVMode(bestMode);
    }
    nz |= _reconstructUV(rd, it.yuvOut, it.uvMode);

    rd
      ..nz = nz
      ..score = bestScore;
  }
}
