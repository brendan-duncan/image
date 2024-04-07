import '../../color/color_uint8.dart';
import '../../image/palette_uint8.dart';

class GifColorMap {
  int bitsPerPixel;
  int numColors;
  int? transparent;
  final PaletteUint8 _palette;

  GifColorMap(this.numColors)
      : _palette = PaletteUint8(numColors, 3),
        bitsPerPixel = _bitSize(numColors);

  GifColorMap.from(GifColorMap other)
      : bitsPerPixel = other.bitsPerPixel,
        numColors = other.numColors,
        transparent = other.transparent,
        _palette = PaletteUint8.from(other._palette);

  ColorUint8 color(int index) {
    final r = red(index);
    final g = green(index);
    final b = blue(index);
    final a = alpha(index);
    return ColorUint8.rgba(r, g, b, a);
  }

  void setColor(int index, int r, int g, int b) {
    _palette.setRgb(index, r, g, b);
  }

  int findColor(num r, num g, num b, num a) {
    num closestDistance = -1;
    var closestIndex = -1;
    for (var i = 0; i < numColors; ++i) {
      final pr = _palette.getRed(i);
      final pg = _palette.getGreen(i);
      final pb = _palette.getBlue(i);
      final pa = _palette.getAlpha(i);
      if (pr == r && pg == g && pb == b && pa == a) {
        return i;
      }
      final dr = r - pr;
      final dg = g - pg;
      final db = b - pb;
      final da = a - pa;
      final d2 = (dr * dr) + (dg * dg) + (db * db) + (da * da);
      if (closestIndex == -1) {
        closestIndex = i;
        closestDistance = d2;
      } else {
        if (d2 < closestDistance) {
          closestIndex = i;
          closestDistance = d2;
        }
      }
    }
    return closestIndex;
  }

  int red(int color) => _palette.getRed(color) as int;

  int green(int color) => _palette.getGreen(color) as int;

  int blue(int color) => _palette.getBlue(color) as int;

  int alpha(int color) => (color == transparent) ? 0 : 255;

  PaletteUint8 getPalette() {
    if (transparent == null) {
      return _palette;
    }
    final p = PaletteUint8(_palette.numColors, 4);
    final l = _palette.numColors;
    for (var i = 0; i < l; ++i) {
      p.setRgba(i, red(i), green(i), blue(i), alpha(i));
    }
    return p;
  }

  static int _bitSize(int n) {
    for (var i = 1; i <= 8; i++) {
      if ((1 << i) >= n) {
        return i;
      }
    }
    return 0;
  }
}
