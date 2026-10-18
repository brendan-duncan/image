import '../color/channel.dart';
import '../color/color.dart';
import '../font/bitmap_font.dart';
import '../image/image.dart';
import 'blend_mode.dart';
import 'draw_pixel.dart';

/// Draw a single character from [char] horizontally into [image] at position
/// [x],[y] with the given [color].
///
/// If [linearBlend] is true, partly transparent and antialiased pixels are
/// blended as linear light, the colors taken as sRGB, which is slower but
/// keeps thin and soft edges from looking too dark.
Image drawChar(Image image, String char,
    {required BitmapFont font,
    required int x,
    required int y,
    Color? color,
    BlendMode blend = BlendMode.alpha,
    bool linearBlend = false,
    Image? mask,
    Channel maskChannel = Channel.luminance}) {
  final c = char.codeUnits[0];
  if (!font.characters.containsKey(c)) {
    return image;
  }

  final ch = font.characters[c]!;
  final x2 = x + ch.width;
  final y2 = y + ch.height;
  final cIter = ch.image.iterator..moveNext();

  for (var yi = y; yi < y2; ++yi) {
    for (var xi = x; xi < x2; ++xi, cIter.moveNext()) {
      final cp = cIter.current;
      if (color != null) {
        drawPixel(image, xi, yi, color,
            alpha: cp.aNormalized,
            blend: blend,
            linearBlend: linearBlend,
            mask: mask,
            maskChannel: maskChannel);
      } else {
        drawPixel(image, xi, yi, cIter.current,
            blend: blend,
            linearBlend: linearBlend,
            mask: mask,
            maskChannel: maskChannel);
      }
    }
  }

  return image;
}
