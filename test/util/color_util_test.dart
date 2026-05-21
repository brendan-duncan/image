import 'package:image/image.dart';
import 'package:test/test.dart';

void main() {
  group('Util', () {
    group('color_util', () {
      // Issue #779: imprecise sRGB<->XYZ matrix coefficients and truncation
      // (instead of rounding) made RGB->Lab->RGB conversions lossy.
      test('rgbToLab/labToRgb round trip is lossless', () {
        const colors = [
          [0, 0, 0],
          [255, 255, 255],
          [250, 250, 250],
          [128, 128, 128],
          [251, 0, 0],
          [0, 255, 0],
          [0, 0, 255],
          [37, 142, 200],
          [200, 100, 50],
        ];
        for (final c in colors) {
          final lab = rgbToLab(c[0], c[1], c[2]);
          final rgb = labToRgb(lab[0], lab[1], lab[2]);
          expect(rgb, equals(c), reason: '$c round-tripped through Lab');
        }
      });

      // A neutral gray should only affect the L* (luminance) component;
      // the a* and b* chroma components should stay near zero.
      test('rgbToLab keeps neutral grays neutral', () {
        for (final v in [32, 96, 160, 224, 250]) {
          final lab = rgbToLab(v, v, v);
          expect(lab[1].abs(), lessThan(0.001), reason: 'a* for gray $v');
          expect(lab[2].abs(), lessThan(0.001), reason: 'b* for gray $v');
        }
      });
    });
  });
}
