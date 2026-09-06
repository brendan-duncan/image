/// The knobs of the lossy encoder, with the defaults libwebp ships.
library;

import '../../util/_internal.dart';

/// Above this quality the chroma DC error is too small to be worth diffusing.
const errorDiffusionQuality = 98;

/// How much work the encoder puts into finding a good coding of each block.
///
/// The scale is libwebp's `-m`: 0 is fastest and 6 slowest, 4 is the default.
/// Rising values enable, in order, rate-distortion mode selection, a
/// coefficient trellis, and the trellis on every candidate rather than only on
/// the winner.
@internal
class VP8Config {
  VP8Config({
    this.quality = 75,
    this.method = 4,
    this.segments = 4,
    this.snsStrength = 50,
    this.filterStrength = 60,
    this.filterSharpness = 0,
    this.filterType = 1,
    this.alphaQuality = 100,
    this.alphaFiltering = 1,
    this.alphaCompression = true,
    this.exact = false,
    this.emulateJpegSize = false,
  });

  /// Between 0 and 100. Around 75 is visually close to a JPEG of the same
  /// setting.
  final double quality;

  /// Effort, 0 to 6.
  final int method;

  /// How many quantizer segments to split the picture into, 1 to 4.
  final int segments;

  /// Spatial noise shaping, 0 to 100: how much bit budget moves from flat
  /// areas to detailed ones.
  final int snsStrength;

  /// Deblocking filter strength, 0 to 100. This only reaches the decoder as a
  /// header value; the encoder never runs the filter itself.
  final int filterStrength;

  /// Deblocking filter sharpness, 0 to 7.
  final int filterSharpness;

  /// 0 for the simple filter, 1 for the strong one, which also filters chroma.
  final int filterType;

  /// Quality of the alpha plane, 0 to 100.
  ///
  /// Below 100 the plane is reduced to fewer distinct levels before coding,
  /// which shrinks it a great deal on soft-edged transparency at the cost of
  /// banding in the edge itself. At 100 it is coded exactly.
  final int alphaQuality;

  /// Predictive filtering of the alpha plane: 0 none, 1 fast, 2 best.
  final int alphaFiltering;

  /// Whether to compress the alpha plane losslessly rather than store it raw.
  final bool alphaCompression;

  /// Whether to keep the colour hidden under fully transparent pixels.
  final bool exact;

  /// Whether to aim for the file size libjpeg would produce at this quality.
  final bool emulateJpegSize;

  /// Rate-distortion effort implied by [method].
  int get rdOptLevel => method >= 6
      ? rdOptTrellisAll
      : method >= 5
          ? rdOptTrellis
          : method >= 3
              ? rdOptBasic
              : rdOptNone;

  static const rdOptNone = 0;
  static const rdOptBasic = 1;
  static const rdOptTrellis = 2;
  static const rdOptTrellisAll = 3;
}
