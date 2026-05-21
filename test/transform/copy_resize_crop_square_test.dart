import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Transform', () {
    test('copyResizeCropSquare', () async {
      final i0 = await (Command()
            ..decodePngFile('test/_data/png/buck_24.png')
            ..copyResizeCropSquare(size: 64)
            ..writeToFile(
              '$testOutputPath/transform/copyResizeCropSquare.png',
            ))
          .getImage();
      expect(i0, isNotNull);
      expect(i0!.width, equals(64));
      expect(i0.height, equals(64));

      await (Command()
            ..createImage(width: 64, height: 64)
            ..fill(color: ColorRgb8(255, 255, 255))
            ..compositeImage(
              Command()
                ..decodePngFile('test/_data/png/buck_24.png')
                ..convert(numChannels: 4)
                ..copyResizeCropSquare(size: 64, radius: 20),
            )
            ..writeToFile(
              '$testOutputPath/transform/copyResizeCropSquare_rounded.png',
            ))
          .execute();

      await (Command()
            ..decodePngFile('test/_data/png/buck_24.png')
            ..convert(numChannels: 4)
            ..copyResizeCropSquare(size: 300, radius: 20)
            ..writeToFile(
              '$testOutputPath/transform/copyResizeCropSquare_rounded_alpha.png',
            ))
          .execute();
    });

    // Issue #600: non-nearest interpolation ignored the crop offset, so the
    // interpolated result was sampled from a corner instead of the center.
    test('copyResizeCropSquare centers the interpolated crop', () {
      // Tall image: top third red, middle third green, bottom third blue.
      final tall = Image(width: 100, height: 300);
      for (final p in tall) {
        p.setRgb(p.y < 100 ? 255 : 0, p.y >= 100 && p.y < 200 ? 255 : 0,
            p.y >= 200 ? 255 : 0);
      }
      for (final interp in [Interpolation.nearest, Interpolation.cubic]) {
        final c = copyResizeCropSquare(tall, size: 100, interpolation: interp)
            .getPixel(50, 50);
        expect(c.r, equals(0), reason: 'tall crop center, $interp');
        expect(c.g, equals(255), reason: 'tall crop center, $interp');
      }

      // Wide image: left third red, middle third green, right third blue.
      final wide = Image(width: 300, height: 100);
      for (final p in wide) {
        p.setRgb(p.x < 100 ? 255 : 0, p.x >= 100 && p.x < 200 ? 255 : 0,
            p.x >= 200 ? 255 : 0);
      }
      for (final interp in [Interpolation.nearest, Interpolation.cubic]) {
        final c = copyResizeCropSquare(wide, size: 100, interpolation: interp)
            .getPixel(50, 50);
        expect(c.r, equals(0), reason: 'wide crop center, $interp');
        expect(c.g, equals(255), reason: 'wide crop center, $interp');
      }
    });

    // A non-zero radius on a non-square source must still produce a square
    // output of the requested size.
    test('copyResizeCropSquare with a radius on a non-square image', () {
      for (final src in [
        Image(width: 120, height: 300),
        Image(width: 300, height: 120),
      ]) {
        for (final interp in [Interpolation.nearest, Interpolation.linear]) {
          final out = copyResizeCropSquare(src,
              size: 64, radius: 16, antialias: true, interpolation: interp);
          expect(out.width, equals(64));
          expect(out.height, equals(64));
        }
      }
    });
  });
}
