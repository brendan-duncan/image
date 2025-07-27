import '../../image.dart';

/// Draw a single character from [char] horizontally into [image] at position
/// [x],[y] with the given [color].
Image drawChar(Image image, String char,
    {required BitmapFont font,
    required int x,
    required int y,
    Color? color,
    BlendMode blend = BlendMode.alpha,
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
            mask: mask,
            maskChannel: maskChannel);
      } else {
        drawPixel(image, xi, yi, cIter.current,
            blend: blend, mask: mask, maskChannel: maskChannel);
      }
    }
  }

  return image;
}
