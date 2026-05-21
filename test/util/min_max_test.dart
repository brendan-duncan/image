import 'package:image/image.dart';
import 'package:test/test.dart';

void main() {
  group('Util', () {
    group('minMax', () {
      // Issue #657: when the min or max value was in the first pixel of a
      // multi-channel image, the remaining channels of that pixel were still
      // treated as the "first" sample and clobbered the result.
      test('extremes in the first pixel are not lost', () {
        final image = Image(width: 8, height: 8);
        for (final p in image) {
          p.setRgb(128, 128, 128);
        }
        // Put both the global min and max in the very first pixel.
        image.setPixel(0, 0, ColorRgb8(5, 250, 128));

        final mM = minMax(image);
        expect(mM[0], equals(5));
        expect(mM[1], equals(250));
      });

      test('max in the first pixel of a multi-channel image', () {
        final image = Image(width: 100, height: 100)
          ..setPixel(0, 0, ColorRgb8(100, 0, 0));

        final mM = minMax(image);
        expect(mM[0], equals(0));
        expect(mM[1], equals(100));
      });
    });
  });
}
