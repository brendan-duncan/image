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

      final v3 = vignette(img.clone().convert(numChannels: 4),
          color: ColorRgba8(255, 255, 255, 0),
          start: 0.65,
          end: 0.95,
          amount: 0.5);
      await encodePngFile('$testOutputPath/filter/vignette_3.png', v3);
    });
  });
}
