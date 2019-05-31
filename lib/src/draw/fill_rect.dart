import 'dart:math';

import '../color.dart';
import '../image.dart';
import '../internal/clamp.dart';

/// Fill a rectangle in the image [src] with the given [color] with the corners
/// [x1],[y1] and [x2],[y2].
Image fillRect(Image src, int x1, int y1, int x2, int y2, int color) {
  int _x0 = clamp(min(x1, x2), 0, src.width - 1);
  int _y0 = clamp(min(y1, y2), 0, src.height - 1);
  int _x1 = clamp(max(x1, x2), 0, src.width - 1);
  int _y1 = clamp(max(y1, y2), 0, src.height - 1);
  for (int sy = _y0; sy <= _y1; ++sy) {
    int pi = sy * src.width + _x0;
    for (int sx = _x0; sx <= _x1; ++sx, ++pi) {
      src[pi] = alphaBlendColors(src[pi], color);
    }
  }
  return src;
}
