import '../color/color.dart';
import '../image/image.dart';

Image scaleRgba(Image src, Color s) {
  final dr = s.r / s.maxChannelValue;
  final dg = s.g / s.maxChannelValue;
  final db = s.b / s.maxChannelValue;
  final da = s.a / s.maxChannelValue;
  for (final frame in src.frames) {
    for (final p in frame) {
      p.setColor(p.r * dr, p.g * dg, p.b * db, p.a * da);
    }
  }
  return src;
}
