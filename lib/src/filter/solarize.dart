import '../image/image.dart';
import '../util/min_max.dart';

enum SolarizeMode { highlights, shadows }

/// Solarize the colors of the [src] image.
/// {threshold} should be int from 1 to 254. If {mode} is
/// SolarizeMode.highlights, bright objects become black, otherwise it will
/// solarize shadows.
Image solarize(Image src,
    {required int threshold, SolarizeMode mode = SolarizeMode.highlights}) {
  final max = src.maxChannelValue;
  final thresholdRange = (max * (threshold / 255)).toInt();
  if (src.hasPalette) {
    src = src.convert(numChannels: src.numChannels);
  }
  for (final frame in src.frames) {
    if (src.hasPalette) {
      final p = frame.palette!;
      final numColors = p.numColors;
      for (var i = 0; i < numColors; ++i) {
        if (mode == SolarizeMode.highlights) {
          if (p.getGreen(i) > thresholdRange) {
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
          if (p.getGreen(i) < thresholdRange) {
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
          if (mode == SolarizeMode.highlights) {
            if (p.g > thresholdRange) {
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
            if (p.g < thresholdRange) {
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

  /// max value and zero are used to improve contrast
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
    for (final frame in src.frames) {
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
