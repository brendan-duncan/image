import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Filter', () {
    test('vignette', () async {
      final img = (await decodePngFile('test/_data/png/buck_24.png'))!;

      final v1 = vignette(img.clone());
      await encodePngFile('$testOutputPath/filter/vignette.png', v1);

      final v2 = vignette(img.clone(), color: ColorRgb8(255, 255, 255));
      await encodePngFile('$testOutputPath/filter/vignette_2.png', v2);

      final v3 = vignette(
        img.clone().convert(numChannels: 4),
        color: ColorRgba8(255, 255, 255, 0),
        start: 0.65,
        end: 0.95,
        amount: 0.5,
      );
      await encodePngFile('$testOutputPath/filter/vignette_3.png', v3);
    });

    test('vignette preserves dimensions', () {
      final src = solidImage(64, 64, ColorRgb8(200, 200, 200));
      final result = vignette(src.clone());
      // dimensions must not change
      expect(result.width, equals(64));
      expect(result.height, equals(64));
    });

    test('vignette darkens corners more than the centre (black vignette)', () {
      // Use a solid mid-grey image so any darkening is clearly measurable.
      // Default vignette color is black (0,0,0).
      final src = solidImage(100, 100, ColorRgb8(200, 200, 200));
      final result = vignette(src.clone());
      // Centre pixel is inside the inner radius, so it should be brighter.
      final centre = result.getPixel(50, 50);
      // Corner pixel is at the maximum radial distance, so it should be darker.
      final corner = result.getPixel(0, 0);
      expect(corner.r, lessThan(centre.r),
          reason: 'corner should be darker than centre');
    });

    test('vignette with amount 0 leaves image unchanged', () {
      final src = solidImage(32, 32, ColorRgb8(100, 150, 200));
      // amount=0 → blend factor is 0 → output equals original
      testImageEquals(vignette(src.clone(), amount: 0), src);
    });

    test('vignette returns src (mutates in place)', () {
      final src = solidImage(32, 32, ColorRgb8(100, 150, 200));
      final result = vignette(src);
      expect(identical(result, src), isTrue);
    });
  });
}
