import 'dart:typed_data';

import '../../color/color.dart';
import '../../util/_internal.dart';
import '../decode_info.dart';
import 'png_frame.dart';

class PngColorType {
  static const grayscale = 0;
  static const rgb = 2;
  static const indexed = 3;
  static const grayscaleAlpha = 4;
  static const rgba = 6;

  static bool isValid(int? value) =>
      value == grayscale ||
      value == rgb ||
      value == indexed ||
      value == grayscaleAlpha ||
      value == rgba;

  const PngColorType(this.value);
  final int value;
}

enum PngFilterType { none, sub, up, average, paeth }

/// The intended physical pixel size of the image.
/// See <https://www.w3.org/TR/png-3/#11pHYs>.
class PngPhysicalPixelDimensions {
  static const double _inchesPerM = 39.3701;

  /// Unit is unknown.
  static const int unitUnknown = 0;

  /// Unit is the meter.
  static const int unitMeter = 1;

  /// Pixels per unit on the X axis.
  final int xPxPerUnit;

  /// Pixels per unit on the Y axis.
  final int yPxPerUnit;

  /// Unit specifier, either [unitUnknown] or [unitMeter].
  final int unitSpecifier;

  /// Constructs a dimension descriptor with the given values.
  const PngPhysicalPixelDimensions(
      {required this.xPxPerUnit,
      required this.yPxPerUnit,
      required this.unitSpecifier});

  /// Constructs a dimension descriptor specifying x and y resolution in dots
  /// per inch (DPI). If [yDpi] is unspecified, [xDpi] is used for both x and y
  /// axes.
  PngPhysicalPixelDimensions.dpi(int xDpi, [int? yDpi])
      : xPxPerUnit = (xDpi * _inchesPerM).round(),
        yPxPerUnit = ((yDpi ?? xDpi) * _inchesPerM).round(),
        unitSpecifier = unitMeter;

  @override
  int get hashCode => Object.hash(xPxPerUnit, yPxPerUnit, unitSpecifier);

  @override
  bool operator ==(Object other) =>
      other is PngPhysicalPixelDimensions &&
      other.xPxPerUnit == xPxPerUnit &&
      other.yPxPerUnit == yPxPerUnit &&
      other.unitSpecifier == unitSpecifier;
}

class PngInfo implements DecodeInfo {
  @override
  int width = 0;
  @override
  int height = 0;
  int bits = 0;
  int colorType = -1;
  int compressionMethod = 0;
  int filterMethod = 0;
  int interlaceMethod = 0;
  List<int?>? palette;
  List<int>? transparency;
  double? gamma;
  @override
  Color? backgroundColor;
  String iccpName = '';
  int iccpCompression = 0;
  Uint8List? iccpData;
  Map<String, String> textData = {};
  PngPhysicalPixelDimensions? pixelDimensions;

  // APNG extensions
  @override
  int numFrames = 1;
  int repeat = 0;
  final frames = <PngFrame>[];

  final _idat = <int>[];

  bool get isAnimated => frames.isNotEmpty;
}

@internal
class InternalPngInfo extends PngInfo {
  List<int> get idat => _idat;
}
