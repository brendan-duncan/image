// JPEG behaviour that has to hold on the web as well as on the VM.
//
// Kept apart from `jpeg_test.dart` because that one reads files, and so cannot
// run in a browser. Everything here is synthetic, so this file runs under
//
//     dart test -p chrome test/formats/jpeg_web_test.dart
//     dart test -p chrome -c dart2wasm test/formats/jpeg_web_test.dart
//
// as well as in the normal suite. The web build uses its own IDCT
// (`_jpeg_quantize_html.dart`) because dart2js shifts are 32-bit.

import 'package:image/image.dart';
import 'package:test/test.dart';

Image _gradient(int width, int height) {
  final image = Image(width: width, height: height);
  for (final p in image) {
    p
      ..r = p.x * 255 ~/ (width - 1)
      ..g = p.y * 255 ~/ (height - 1)
      ..b = 255 - p.x * 255 ~/ (width - 1);
  }
  return image;
}

void main() {
  group('Format', () {
    group('jpeg (web)', () {
      for (final chroma in JpegChroma.values) {
        test('round trip ${chroma.name}', () {
          // Odd dimensions exercise the MCU padding blocks.
          final src = _gradient(37, 29);
          final decoded = decodeJpg(encodeJpg(src, chroma: chroma))!;
          expect(decoded.width, equals(src.width));
          expect(decoded.height, equals(src.height));
          var maxDiff = 0;
          for (final p in src) {
            final q = decoded.getPixel(p.x, p.y);
            for (var c = 0; c < 3; ++c) {
              final d = (p[c] - q[c]).abs().toInt();
              if (d > maxDiff) {
                maxDiff = d;
              }
            }
          }
          expect(maxDiff, lessThan(chroma == JpegChroma.yuv444 ? 8 : 24));
        });
      }
    });
  });
}
