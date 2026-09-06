/// The lossy WebP encoder: turns a picture into a VP8 keyframe.
library;

import 'dart:typed_data';

import '../../image/image.dart';
import '../../util/_internal.dart';
import '../../util/image_exception.dart';
import 'vp8_alpha.dart';
import 'vp8_bool_encoder.dart';
import 'vp8_config.dart';
import 'vp8_iterator.dart';
import 'vp8_proba.dart';
import 'vp8_rd.dart';
import 'vp8_residual.dart';
import 'vp8_segments.dart';
import 'vp8_state.dart';
import 'vp8_tables.dart';
import 'vp8_tokens.dart';
import 'vp8_yuv.dart';
import 'vp8l_encoder.dart' show maxDimension;

/// Partition #0 carries the header and every macroblock's modes, and the
/// format gives its length nineteen bits.
const _maxPartition0Size = 1 << 19;

/// A rough number of bytes each macroblock takes, indexed by the quantizer
/// divided by sixteen. Only used to size the output buffer up front.
const _averageBytesPerMb = [50, 24, 16, 9, 7, 5, 3, 2];

/// How many macroblocks may pass before the probabilities are refreshed.
///
/// The rate-distortion decisions are only as good as the cost tables they are
/// made against, so the tables are recomputed from the statistics collected so
/// far, roughly eight times per picture.
const _minRefreshCount = 96;

/// A coded lossy frame: the VP8 bitstream, and the alpha plane that VP8 itself
/// cannot carry.
@internal
class VP8Lossy {
  VP8Lossy(this.bitstream, this.alpha);

  final Uint8List bitstream;

  /// The payload of an `ALPH` chunk, or null if the picture is opaque.
  final Uint8List? alpha;
}

/// Encodes [image] as a VP8 keyframe.
@internal
VP8Lossy encodeVP8(Image image, VP8Config config) {
  if (image.width <= 0 ||
      image.height <= 0 ||
      image.width > maxDimension ||
      image.height > maxDimension) {
    // The frame header has fourteen bits for each dimension; letting one
    // overflow into the next field would produce a stream no decoder can read.
    throw ImageException('WebP images must be between 1x1 and '
        '${maxDimension}x$maxDimension, got ${image.width}x${image.height}');
  }
  final yuv = importYuv(image);
  if (!config.exact) {
    cleanupTransparentArea(yuv);
  }
  final alphaPlane = yuv.a;
  final alpha = alphaPlane == null
      ? null
      : encodeAlphaChunk(alphaPlane, yuv.width, yuv.height,
          filtering: config.alphaFiltering,
          compress: config.alphaCompression,
          quality: config.alphaQuality);
  return VP8Lossy(VP8Encoder(config, yuv).encode(), alpha);
}

@internal
class VP8Encoder {
  VP8Encoder(this.config, VP8Yuv pic) : enc = VP8EncState(config, pic);

  final VP8Config config;
  final VP8EncState enc;

  final _tokens = VP8TokenBuffer();
  final _res = VP8Residual();

  /// Codes the picture and returns the VP8 bitstream.
  Uint8List encode() {
    analyzeSegments(enc);
    final tokenPartition = _codeMacroblocks();
    return _assemble(tokenPartition);
  }

  /// Runs the mode search over every macroblock, recording the coding of each
  /// as tokens rather than writing it out.
  ///
  /// Nothing can be written until the whole picture has been seen, because the
  /// probabilities the coefficients are written with are derived from what the
  /// picture turned out to contain.
  Uint8List _codeMacroblocks() {
    _setLoopParams(config.quality);

    final it = VP8EncIterator(enc);
    final decimate = VP8Decimate(enc, it);
    final rd = VP8ModeScore();
    final rdOpt = config.rdOptLevel;

    var maxCount = (enc.mbW * enc.mbH) >> 3;
    if (maxCount < _minRefreshCount) {
      maxCount = _minRefreshCount;
    }
    var count = maxCount;

    enc.proba.resetTokenStats();
    _tokens.clear();

    do {
      it.import();
      if (--count < 0) {
        enc.proba
          ..finalizeTokenProbas()
          ..calculateLevelCosts();
        count = maxCount;
      }
      decimate.run(rd, rdOpt);
      _recordTokens(it, rd);
      it.saveBoundary();
    } while (it.next());

    enc.proba.finalizeTokenProbas();

    final bytesPerMb = _averageBytesPerMb[enc.quant.baseQuant >> 4];
    final bw = VP8BoolEncoder(enc.mbW * enc.mbH * bytesPerMb);
    _tokens.emit(bw, enc.proba.coeffs);
    return bw.finish();
  }

  void _setLoopParams(double quality) {
    final q = quality < 0
        ? 0.0
        : quality > 100
            ? 100.0
            : quality;
    enc.quant
        .setSegmentParams(config, q, enc.alpha, enc.uvAlpha, enc.mbSegment);
    _setSegmentProbas();
    enc.proba
      ..calculateLevelCosts()
      ..nbSkip = 0;
  }

  /// Derives the probabilities of the segment tree from how many macroblocks
  /// ended up in each segment.
  void _setSegmentProbas() {
    final p = Int32List(4);
    final mbs = enc.mbW * enc.mbH;
    for (var n = 0; n < mbs; n++) {
      p[enc.mbSegment[n]]++;
    }
    if (enc.numSegments > 1) {
      final probas = enc.proba.segments;
      probas[0] = _getProba(p[0] + p[1], p[2] + p[3]);
      probas[1] = _getProba(p[0], p[1]);
      probas[2] = _getProba(p[2], p[3]);
      enc.updateMap = probas[0] != 255 || probas[1] != 255 || probas[2] != 255;
      if (!enc.updateMap) {
        // Every macroblock would be coded as segment 0 anyway.
        enc.mbSegment.fillRange(0, mbs, 0);
      }
      enc.segmentSize = p[0] * (bitCost(0, probas[0]) + bitCost(0, probas[1])) +
          p[1] * (bitCost(0, probas[0]) + bitCost(1, probas[1])) +
          p[2] * (bitCost(1, probas[0]) + bitCost(0, probas[2])) +
          p[3] * (bitCost(1, probas[0]) + bitCost(1, probas[2]));
    } else {
      enc.updateMap = false;
      enc.segmentSize = 0;
    }
  }

  static int _getProba(int a, int b) {
    final total = a + b;
    return total == 0 ? 255 : (255 * a + total ~/ 2) ~/ total;
  }

  /// Records the coefficients of one macroblock into the token buffer.
  void _recordTokens(VP8EncIterator it, VP8ModeScore rd) {
    final proba = enc.proba;
    it.nzToBytes();

    if (it.mbType == 1) {
      // The DC of an intra 16x16 macroblock is coded through its own block.
      final ctx = it.topNz[8] + it.leftNz[8];
      _res
        ..init(0, typeI16DC)
        ..setCoeffs(rd.yDcLevels, 0);
      it.topNz[8] = it.leftNz[8] = recordCoeffTokens(proba, _res, ctx, _tokens);
      _res.init(1, typeI16AC);
    } else {
      _res.init(0, typeI4AC);
    }

    for (var y = 0; y < 4; y++) {
      for (var x = 0; x < 4; x++) {
        final ctx = it.topNz[x] + it.leftNz[y];
        _res.setCoeffs(rd.yAcLevels, (x + y * 4) * 16);
        it.topNz[x] =
            it.leftNz[y] = recordCoeffTokens(proba, _res, ctx, _tokens);
      }
    }

    _res.init(0, typeChroma);
    for (var ch = 0; ch <= 2; ch += 2) {
      for (var y = 0; y < 2; y++) {
        for (var x = 0; x < 2; x++) {
          final ctx = it.topNz[4 + ch + x] + it.leftNz[4 + ch + y];
          _res.setCoeffs(rd.uvLevels, (ch * 2 + x + y * 2) * 16);
          it.topNz[4 + ch + x] = it.leftNz[4 + ch + y] =
              recordCoeffTokens(proba, _res, ctx, _tokens);
        }
      }
    }
    it.bytesToNz();
  }

  //----------------------------------------------------------------------------
  // Bitstream assembly.

  Uint8List _assemble(Uint8List tokenPartition) {
    final part0 = _generatePartition0();
    if (part0.length >= _maxPartition0Size) {
      throw StateError('VP8 partition #0 overflow');
    }

    final out = Uint8List(10 + part0.length + tokenPartition.length);
    // Paragraph 9.1: a keyframe, its profile, that it is shown, and how long
    // partition #0 is.
    final bits = 0 | // key frame
        (enc.profile << 1) |
        (1 << 4) | // visible
        (part0.length << 5);
    out[0] = bits & 0xff;
    out[1] = (bits >> 8) & 0xff;
    out[2] = (bits >> 16) & 0xff;
    // The start code, then the dimensions with a scale of 1:1.
    out[3] = 0x9d;
    out[4] = 0x01;
    out[5] = 0x2a;
    out[6] = enc.pic.width & 0xff;
    out[7] = (enc.pic.width >> 8) & 0x3f;
    out[8] = enc.pic.height & 0xff;
    out[9] = (enc.pic.height >> 8) & 0x3f;
    out
      ..setRange(10, 10 + part0.length, part0)
      ..setRange(10 + part0.length, out.length, tokenPartition);
    return out;
  }

  Uint8List _generatePartition0() {
    final bw = VP8BoolEncoder(enc.mbW * enc.mbH * 7 ~/ 8)
      ..putBitUniform(0) // colour space
      ..putBitUniform(0); // clamping type
    _putSegmentHeader(bw);
    _putFilterHeader(bw);
    bw.putBits(0, 2); // one token partition
    _putQuant(bw);
    bw.putBitUniform(0); // the probabilities are not carried to a next frame
    enc.proba.write(bw);
    _codeIntraModes(bw);
    return bw.finish();
  }

  void _putSegmentHeader(VP8BoolEncoder bw) {
    final quant = enc.quant;
    if (bw.putBitUniform(enc.numSegments > 1 ? 1 : 0) == 0) {
      return;
    }
    bw
      ..putBitUniform(enc.updateMap ? 1 : 0)
      ..putBitUniform(1) // the quantizer and filter values follow
      ..putBitUniform(1); // as absolute values, not deltas
    for (var s = 0; s < 4; s++) {
      bw.putSignedBits(quant.dqm[s].quant, 7);
    }
    for (var s = 0; s < 4; s++) {
      bw.putSignedBits(quant.dqm[s].fstrength, 6);
    }
    if (enc.updateMap) {
      for (var s = 0; s < 3; s++) {
        final proba = enc.proba.segments[s];
        if (bw.putBitUniform(proba != 255 ? 1 : 0) != 0) {
          bw.putBits(proba, 8);
        }
      }
    }
  }

  void _putFilterHeader(VP8BoolEncoder bw) {
    final quant = enc.quant;
    bw
      ..putBitUniform(quant.filterSimple ? 1 : 0)
      ..putBits(quant.filterLevel, 6)
      ..putBits(quant.filterSharpness, 3)
      // No per-mode filter deltas: the encoder never runs the filter itself,
      // so it has nothing to say about them.
      ..putBitUniform(0);
  }

  void _putQuant(VP8BoolEncoder bw) {
    final quant = enc.quant;
    bw
      ..putBits(quant.baseQuant, 7)
      ..putSignedBits(quant.dqY1Dc, 4)
      ..putSignedBits(quant.dqY2Dc, 4)
      ..putSignedBits(quant.dqY2Ac, 4)
      ..putSignedBits(quant.dqUvDc, 4)
      ..putSignedBits(quant.dqUvAc, 4);
  }

  /// Writes the segment, skip flag and intra modes of every macroblock.
  void _codeIntraModes(VP8BoolEncoder bw) {
    final it = VP8EncIterator(enc);
    final preds = enc.preds;
    final predsW = enc.predsW;
    do {
      if (enc.updateMap) {
        _putSegment(bw, enc.mbSegment[it.mbPos], enc.proba.segments);
      }
      if (enc.proba.useSkipProba) {
        bw.putBit(enc.mbSkip[it.mbPos], enc.proba.skipProba);
      }
      if (bw.putBit(it.mbType != 0 ? 1 : 0, 145) != 0) {
        _putI16Mode(bw, preds[it.predsPos]);
      } else {
        var p = it.predsPos;
        var topPred = p - predsW;
        for (var y = 0; y < 4; y++) {
          var left = preds[p - 1];
          for (var x = 0; x < 4; x++) {
            left = _putI4Mode(
                bw, preds[p + x], kBModesProba[preds[topPred + x]][left]);
          }
          topPred = p;
          p += predsW;
        }
      }
      _putUVMode(bw, it.uvMode);
    } while (it.next());
  }

  static void _putSegment(VP8BoolEncoder bw, int s, Uint8List p) {
    if (bw.putBit(s >= 2 ? 1 : 0, p[0]) != 0) {
      bw.putBit(s & 1, p[2]);
    } else {
      bw.putBit(s & 1, p[1]);
    }
  }

  static void _putI16Mode(VP8BoolEncoder bw, int mode) {
    if (bw.putBit(mode == tmPred || mode == hPred ? 1 : 0, 156) != 0) {
      bw.putBit(mode == tmPred ? 1 : 0, 128); // true motion or horizontal
    } else {
      bw.putBit(mode == vPred ? 1 : 0, 163); // vertical or DC
    }
  }

  static void _putUVMode(VP8BoolEncoder bw, int mode) {
    if (bw.putBit(mode != dcPred ? 1 : 0, 142) != 0) {
      if (bw.putBit(mode != vPred ? 1 : 0, 114) != 0) {
        bw.putBit(mode != hPred ? 1 : 0, 183); // otherwise true motion
      }
    }
  }

  /// Codes one 4x4 mode through the tree of RFC 6386 11.4, and returns it so
  /// it can serve as the left context of the next block.
  static int _putI4Mode(VP8BoolEncoder bw, int mode, List<int> prob) {
    if (bw.putBit(mode != bDcPred ? 1 : 0, prob[0]) != 0) {
      if (bw.putBit(mode != bTmPred ? 1 : 0, prob[1]) != 0) {
        if (bw.putBit(mode != bVePred ? 1 : 0, prob[2]) != 0) {
          if (bw.putBit(mode >= bLdPred ? 1 : 0, prob[3]) == 0) {
            if (bw.putBit(mode != bHePred ? 1 : 0, prob[4]) != 0) {
              bw.putBit(mode != bRdPred ? 1 : 0, prob[5]);
            }
          } else {
            if (bw.putBit(mode != bLdPred ? 1 : 0, prob[6]) != 0) {
              if (bw.putBit(mode != bVlPred ? 1 : 0, prob[7]) != 0) {
                bw.putBit(mode != bHdPred ? 1 : 0, prob[8]);
              }
            }
          }
        }
      }
    }
    return mode;
  }
}
