import '../image/image.dart';
import '../util/min_max.dart';

/// Solarize the colors of the [src] image - Started from invert.dart file.
Image solarize(Image src, {required int threshold, required String mode}) {
  /// threshold should be int from 1 to 254; mode should either 'shadow' or ' '
  /// mode ' ' is normal solarization, bright objetcs become black
  /// mode shadow will solarize the shadows like a Man Ray photograph
  final max = src.maxChannelValue;
  final trld = (max * (threshold / 255)).toInt();

  for (final frame in src.frames) {
    if (src.hasPalette) {
      final p = frame.palette!;
      final numColors = p.numColors;
      for (var i = 0; i < numColors; ++i) {
        if (mode == "") {
          if (p.getGreen(i) > trld) {
            final r = max - p.getRed(i);
            final g = max - p.getGreen(i);
            final b = max - p.getBlue(i);
            p.setRgb(i, r, g, b);
          } else {
            final r = p.getRed(i);
            final g = p.getGreen(i);
            final b = p.getBlue(i);
            p.setRgb(i, r, g, b);
          }
        } else {
          if (p.getGreen(i) < trld) {
            final r = max - p.getRed(i);
            final g = max - p.getGreen(i);
            final b = max - p.getBlue(i);
            p.setRgb(i, r, g, b);
          } else {
            final r = p.getRed(i);
            final g = p.getGreen(i);
            final b = p.getBlue(i);
            p.setRgb(i, r, g, b);
          }
        }
      }
    } else {
      if (max != 0.0) {
        for (final p in frame) {
          if (mode == "") {
            if (p.g > trld) {
              p
                ..r = max - p.r
                ..g = max - p.g
                ..b = max - p.b;
            } else {
              p
                ..r = p.r
                ..g = p.g
                ..b = p.b;
            }
          } else {
            if (p.g < trld) {
              p
                ..r = max - p.r
                ..g = max - p.g
                ..b = max - p.b;
            } else {
              p
                ..r = p.r
                ..g = p.g
                ..b = p.b;
            }
          }
        }
      }
    }
  }

  /// I used code from normalize here with the original
  /// max value and zero to improve contrast
  const num a = 0;
  final num b = max;

  final mM = minMax(src);
  final mn = mM[0];
  final mx = mM[1];

  if (mn == mx) {
    return src;
  }

  final fm = mn.toDouble();
  final fM = mx.toDouble();

  if (mn != a || mx != b) {
    for (var frame in src.frames) {
      for (final p in frame) {
        p
          ..r = (p.r - fm) / (fM - fm) * (b - a) + a
          ..g = (p.g - fm) / (fM - fm) * (b - a) + a
          ..b = (p.b - fm) / (fM - fm) * (b - a) + a
          ..a = (p.a - fm) / (fM - fm) * (b - a) + a;
      }
    }
  }

  return src;
}
