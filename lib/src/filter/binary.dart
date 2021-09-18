import '../image.dart';

Image binary(Image src, {int threshold = 75}) {
  final p = src.getBytes();

  for (var i = 0, len = p.length; i < len; i += 4) {
    if (p[i] <= threshold) {
      p[i] = 0;
      p[i + 1] = 0;
      p[i + 2] = 0;
    } else {
      p[i] = 255;
      p[i + 1] = 255;
      p[i + 2] = 255;
    }
  }
  return src;
}
