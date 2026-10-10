import 'dart:math';
import 'dart:typed_data';

import '../color/channel.dart';
import '../color/color.dart';
import '../image/image.dart';
import '../image/pixel.dart';
import '../util/color_util.dart';
import '../util/math_util.dart';

/// Fill the 4-connected shape containing [x],[y] in the image [src] with the
/// given [color].
Image fillFlood(Image src,
    {required int x,
    required int y,
    required Color color,
    num threshold = 0.0,
    bool compareAlpha = false,
    Image? mask,
    Channel maskChannel = Channel.luminance}) {
  if (color.a == 0 || !src.isBoundsSafe(x, y)) {
    return src;
  }

  final visited = Uint8List(src.width * src.height);
  final matches = _matcher(src, x, y, threshold, compareAlpha);

  Pixel? p;
  void mark(int x, int y) {
    if (mask != null) {
      final m = mask.getPixel(x, y).getChannelNormalized(maskChannel);
      if (m > 0) {
        p = src.getPixel(x, y, p);
        p!
          ..r = mix(p!.r, color.r, m)
          ..g = mix(p!.g, color.g, m)
          ..b = mix(p!.b, color.b, m)
          ..a = mix(p!.a, color.a, m);
      }
    } else {
      src.setPixel(x, y, color);
    }
    visited[y * src.width + x] = 1;
  }

  _fill4(src.width, src.height, x, y,
      (x, y) => visited[y * src.width + x] != 0 || !matches(x, y), mark);

  return src;
}

/// Create a mask describing the 4-connected shape containing [x],[y] in the
/// image [src].
Uint8List maskFlood(Image src, int x, int y,
    {num threshold = 0.0, bool compareAlpha = false, int fillValue = 255}) {
  final ret = Uint8List(src.width * src.height);
  if (!src.isBoundsSafe(x, y)) {
    return ret;
  }

  final visited = Uint8List(src.width * src.height);
  final matches = _matcher(src, x, y, threshold, compareAlpha);

  void mark(int x, int y) {
    ret[y * src.width + x] = fillValue;
    visited[y * src.width + x] = 1;
  }

  _fill4(src.width, src.height, x, y,
      (x, y) => visited[y * src.width + x] != 0 || !matches(x, y), mark);
  return ret;
}

// Returns a test of whether a pixel of [src] matches the color at [x],[y]
// before anything is filled.
bool Function(int x, int y) _matcher(
    Image src, int x, int y, num threshold, bool compareAlpha) {
  final seed = src.getPixel(x, y);
  final r = seed.r;
  final g = seed.g;
  final b = seed.b;
  final a = seed.a;
  if (threshold > 0) {
    final lab = rgbToLab(r, g, b);
    if (compareAlpha) {
      lab.add(a.toDouble());
    }
    return (x, y) => !_testPixelLabColorDistance(src, x, y, lab, threshold);
  }
  Pixel? p;
  if (compareAlpha) {
    return (x, y) {
      p = src.getPixel(x, y, p);
      return p!.r == r && p!.g == g && p!.b == b && p!.a == a;
    };
  }
  return (x, y) {
    p = src.getPixel(x, y, p);
    return p!.r == r && p!.g == g && p!.b == b;
  };
}

/// Compare colors from a 3 or 4 dimensional color space
num _colorDistance(List<num> c1, List<num> c2, bool compareAlpha) {
  final d1 = c1[0] - c2[0];
  final d2 = c1[1] - c2[1];
  final d3 = c1[2] - c2[2];
  if (compareAlpha) {
    final dA = c1[3] - c2[3];
    return sqrt(max(d1 * d1, (d1 - dA) * (d1 - dA)) +
        max(d2 * d2, (d2 - dA) * (d2 - dA)) +
        max(d3 * d3, (d3 - dA) * (d3 - dA)));
  } else {
    return sqrt(d1 * d1 + d2 * d2 + d3 * d3);
  }
}

bool _testPixelLabColorDistance(
    Image src, int x, int y, List<num> refColor, num threshold) {
  final pixel = src.getPixel(x, y);
  final compareAlpha = refColor.length > 3;
  final pixelColor = rgbToLab(pixel.r, pixel.g, pixel.b);
  if (compareAlpha) {
    pixelColor.add(pixel.a.toDouble());
  }
  return _colorDistance(pixelColor, refColor, compareAlpha) > threshold;
}

// A scanline fill: each span of a row is filled, and the spans it touches in
// the rows above and below are added to a stack, so large shapes can't
// overflow the call stack. [blocked] returns true for a pixel that can't be
// filled, and [mark] fills a pixel, which must make it blocked.
void _fill4(int width, int height, int x, int y,
    bool Function(int x, int y) blocked, void Function(int x, int y) mark) {
  final stack = <int>[x, y];
  while (stack.isNotEmpty) {
    final sy = stack.removeLast();
    final sx = stack.removeLast();
    if (blocked(sx, sy)) {
      continue;
    }
    var x1 = sx;
    while (x1 > 0 && !blocked(x1 - 1, sy)) {
      x1--;
    }
    var x2 = sx;
    while (x2 < width - 1 && !blocked(x2 + 1, sy)) {
      x2++;
    }
    for (var i = x1; i <= x2; ++i) {
      mark(i, sy);
    }
    for (final ny in [sy - 1, sy + 1]) {
      if (ny < 0 || ny >= height) {
        continue;
      }
      var inSpan = false;
      for (var i = x1; i <= x2; ++i) {
        if (blocked(i, ny)) {
          inSpan = false;
        } else if (!inSpan) {
          stack
            ..add(i)
            ..add(ny);
          inSpan = true;
        }
      }
    }
  }
}
