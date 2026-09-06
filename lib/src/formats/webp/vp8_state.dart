/// Frame-level state of the lossy encoder: everything that outlives one
/// macroblock.
library;

import 'dart:typed_data';

import '../../util/_internal.dart';
import 'vp8_config.dart';
import 'vp8_proba.dart';
import 'vp8_quant.dart';
import 'vp8_yuv.dart';

/// The buffers and decisions shared by every stage of one lossy frame.
@internal
class VP8EncState {
  VP8EncState(this.config, this.pic)
      : mbW = (pic.width + 15) >> 4,
        mbH = (pic.height + 15) >> 4,
        predsW = 4 * ((pic.width + 15) >> 4) + 1 {
    final mbs = mbW * mbH;
    mbType = Uint8List(mbs);
    mbUvMode = Uint8List(mbs);
    mbSkip = Uint8List(mbs);
    mbSegment = Uint8List(mbs);
    mbAlpha = Uint8List(mbs);
    preds = Uint8List(predsW * (4 * mbH + 1));
    nz = Int32List(mbW + 1);
    yTop = Uint8List(mbW * 16);
    uvTop = Uint8List(mbW * 16);
    // Error diffusion is only worth its state below the top of the quality
    // range; above it the quantizer is fine enough that there is no visible
    // banding to spread out.
    topDerr =
        config.quality <= errorDiffusionQuality ? Int8List(mbW * 4) : null;
    quant = VP8Quantizers(config.segments);

    // Partition #0 has to fit in 512k; this is how many bits of 4x4 modes a
    // macroblock may spend on average before that becomes a risk.
    mbHeaderLimit = 256 * 510 * 8 * 1024 ~/ mbs;
    // An upper bound of 16 bits per 4x4 block, modulated by a quadratic curve
    // on the partition limit (which is zero by default, hence the full value).
    maxI4HeaderBits = 256 * 16 * 16;

    resetBoundaryPredictions();
  }

  final VP8Config config;
  final VP8Yuv pic;

  /// Picture size in macroblocks.
  final int mbW;
  final int mbH;

  /// Stride of [preds], which carries one border column and row.
  final int predsW;

  /// Per-macroblock decisions.
  late final Uint8List mbType; // 0 = intra 4x4, 1 = intra 16x16
  late final Uint8List mbUvMode;
  late final Uint8List mbSkip;
  late final Uint8List mbSegment;
  late final Uint8List mbAlpha;

  /// Intra modes of every 4x4 block, with a border of `B_DC_PRED` around the
  /// picture so that neighbour lookups need no bounds checks.
  late final Uint8List preds;

  /// Index of the picture's top-left 4x4 block within [preds].
  int get predsOrigin => 1 + predsW;

  /// The non-zero pattern of each macroblock column, plus one border entry.
  late final Int32List nz;

  /// Reconstructed samples along the bottom edge of the previous row.
  late final Uint8List yTop;

  /// The same for chroma, eight U samples then eight V per macroblock.
  late final Uint8List uvTop;

  /// Chroma DC quantization error carried into the macroblock row below, as
  /// two values per channel per macroblock column: `[mbX * 4 + ch * 2 + i]`.
  ///
  /// Null above [errorDiffusionQuality], where the feature is off. Rounding a
  /// flat gradient's DC the same way in every block turns it into visible
  /// steps; spreading the leftover into the neighbours breaks the steps up,
  /// which costs nothing in bits and a good deal of banding.
  late final Int8List? topDerr;

  final proba = VP8EncProba();
  late final VP8Quantizers quant;

  /// Average susceptibility of the picture, and of its chroma alone.
  int alpha = 0;
  int uvAlpha = 0;

  /// Whether the segment map is coded per macroblock.
  bool updateMap = false;

  /// Cost of coding the segment map, in 1/256ths of a bit.
  int segmentSize = 0;

  int maxI4HeaderBits = 0;
  int mbHeaderLimit = 0;

  /// The bitstream profile, deduced from the filter settings.
  int get profile =>
      config.filterStrength > 0 ? (config.filterType == 1 ? 0 : 1) : 2;

  int get numSegments => quant.numSegments;

  void resetBoundaryPredictions() {
    // Only intra 4x4 reads these, and B_DC_PRED (0) is the neutral choice.
    final top = predsOrigin - predsW;
    for (var i = -1; i < 4 * mbW; i++) {
      preds[top + i] = 0;
    }
    for (var i = 0; i < 4 * mbH; i++) {
      preds[predsOrigin - 1 + i * predsW] = 0;
    }
    nz[0] = 0; // the border entry, constant
  }
}
