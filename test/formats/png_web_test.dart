// PNG decoding that has to hold on the web as well as on the VM.
//
// Kept apart from `png_test.dart` because that one reads files, and so cannot
// run in a browser. Everything here is synthetic, so this file runs under
//
//     dart test -p chrome test/formats/png_web_test.dart
//     dart test -p chrome -c dart2wasm test/formats/png_web_test.dart
//
// as well as in the normal suite.

import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

Image _pattern(int numChannels, Format format) {
  final image =
      Image(width: 23, height: 11, numChannels: numChannels, format: format);
  final max = image.maxChannelValue.toInt();
  for (final p in image) {
    // A non-smooth pattern so every filter predictor is exercised.
    p
      ..r = (p.x * 37 + p.y * 11) * 97 % (max + 1)
      ..g = (p.x * 13 + p.y * 29) * 89 % (max + 1)
      ..b = (p.x * 7 + p.y * 53) * 83 % (max + 1)
      ..a = (p.x * 3 + p.y * 17) * 79 % (max + 1);
  }
  return image;
}

void main() {
  group('Format', () {
    group('png (web)', () {
      final images = {
        'gray8': _pattern(1, Format.uint8),
        'grayAlpha8': _pattern(2, Format.uint8),
        'rgb8': _pattern(3, Format.uint8),
        'rgba8': _pattern(4, Format.uint8),
        'rgb16': _pattern(3, Format.uint16),
        'rgba16': _pattern(4, Format.uint16),
        'palette8': _pattern(3, Format.uint8)
            .convert(numChannels: 3, withPalette: true),
      };
      for (final entry in images.entries) {
        for (final filter in PngFilter.values) {
          test('round trip ${entry.key} ${filter.name}', () {
            final src = entry.value;
            final decoded = decodePng(encodePng(src, filter: filter))!;
            testImageEquals(decoded, src);
          });
        }
      }
    });
  });
}
