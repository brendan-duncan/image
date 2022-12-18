import '../color/color.dart';
import '../image/image.dart';

Image scaleRgba(Image src, Color s) {
  final num dr = s.r / s.maxChannelValue;
  final num dg = s.g / s.maxChannelValue;
  final num db = s.b / s.maxChannelValue;
  final num da = s.a / s.maxChannelValue;
  for (var p in src) {
    p.setColor(p.r * dr, p.g * dg, p.b * db, p.a * da);
  }
  return src;
}
