import 'dart:math';

import '../color/channel.dart';
import '../color/color.dart';
import '../image/image.dart';
import '../util/math_util.dart';

/// Fill a rectangle in the image [src] with the given [color] with the corners
/// [x1],[y1] and [x2],[y2].
Image fillRect(Image src, { required int x1, required int y1, required int x2,
    required int y2, required Color color, Image? mask,
    Channel maskChannel = Channel.luminance }) {
  if (color.a == 0) {
    return src;
  }

  final _x0 = min(x1, x2).clamp(0, src.width - 1);
  final _y0 = min(y1, y2).clamp(0, src.height - 1);
  final _x1 = max(x1, x2).clamp(0, src.width - 1);
  final _y1 = max(y1, y2).clamp(0, src.height - 1);
  final _w = (_x1 - _x0) + 1;
  final _h = (_y1 - _y0) + 1;

  // If no blending is necessary, use a faster fill method.
  if (color.a == color.maxChannelValue && mask == null) {
    final iter = src.getRange(_x0, _y0, _w, _h);
    while (iter.moveNext()) {
      iter.current.set(color);
    }
  } else {
    final a = color.a / color.maxChannelValue;
    final iter = src.getRange(_x0, _y0, _w, _h);
    while (iter.moveNext()) {
      final p = iter.current;
      final m = mask?.getPixel(p.x, p.y).getChannelNormalized(maskChannel) ?? 1;
      p..r = mix(p.r, color.r, a * m)
       ..g = mix(p.g, color.g, a * m)
       ..b = mix(p.b, color.b, a * m)
       ..a = p.a * (1 - (color.a * m));
    }
  }

  return src;
}
