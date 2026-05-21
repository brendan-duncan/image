import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Filter', () {
    test('billboard', () async {
      final img = (await decodePngFile('test/_data/png/buck_24.png'))!;
      final i0 = img.clone();
      billboard(i0);
      await encodePngFile('$testOutputPath/filter/billboard.png', i0);

      final mask = Command()
        ..createImage(width: img.width, height: img.height)
        ..fill(color: ColorRgb8(0, 0, 0))
        ..fillCircle(
          x: img.width ~/ 2,
          y: img.height ~/ 2,
          radius: 50,
          color: ColorRgb8(255, 255, 255),
        )
        ..gaussianBlur(radius: 10);

      await (Command()
            ..image(img)
            ..copy()
            ..billboard(mask: mask)
            ..writeToFile('$testOutputPath/filter/billboard_mask.png'))
          .execute();
    });

    test('billboard preserves dimensions', () {
      final src = solidImage(64, 64, ColorRgb8(100, 150, 200));
      final result = billboard(src.clone());
      // dimensions must not change
      expect(result.width, equals(64));
      expect(result.height, equals(64));
    });

    test('billboard returns src (mutates in place)', () {
      final src = solidImage(32, 32, ColorRgb8(80, 80, 80));
      final result = billboard(src);
      expect(identical(result, src), isTrue);
    });

    test('billboard with amount 0 leaves image unchanged', () {
      final src = checkerImage(32, 32);
      // amount=0 → blend factor is 0 → output equals original
      testImageEquals(billboard(src.clone(), amount: 0), src);
    });

    test('billboard output pixel values are in valid range', () {
      // The filter mixes colours and applies a posterisation step; all channel
      // values must stay within [0, maxChannelValue].
      final src = checkerImage(64, 64);
      final result = billboard(src.clone());
      for (final p in result) {
        expect(p.r, inInclusiveRange(0, p.maxChannelValue),
            reason: 'r out of range at ${p.x},${p.y}');
        expect(p.g, inInclusiveRange(0, p.maxChannelValue),
            reason: 'g out of range at ${p.x},${p.y}');
        expect(p.b, inInclusiveRange(0, p.maxChannelValue),
            reason: 'b out of range at ${p.x},${p.y}');
      }
    });
  });
}
