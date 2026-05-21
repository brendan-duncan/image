import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Filter', () {
    test('sketch', () async {
      final bytes = File('test/_data/png/buck_24.png').readAsBytesSync();
      final img = decodePng(bytes)!;
      final i0 = img.clone();
      sketch(i0);
      File('$testOutputPath/filter/sketch.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));

      final mask = Command()
        ..createImage(width: img.width, height: img.height)
        ..fill(color: ColorRgb8(0, 0, 0))
        ..fillCircle(
          x: img.width ~/ 2,
          y: img.height ~/ 2,
          radius: 80,
          color: ColorRgb8(255, 255, 255),
        )
        ..gaussianBlur(radius: 20);

      await (Command()
            ..image(img)
            ..copy()
            ..sketch(mask: mask)
            ..writeToFile('$testOutputPath/filter/sketch_mask.png'))
          .execute();
    });

    test('sketch preserves dimensions', () {
      final src = checkerImage(64, 48);
      final result = sketch(src.clone());
      // dimensions must not change
      expect(result.width, equals(64));
      expect(result.height, equals(48));
    });

    test('sketch on a uniform black image produces uniform output', () {
      // On a uniform image all gradients are 0 → mag = 1 - 0 = 1 → each
      // channel is multiplied by 1 → output equals input.
      final src = solidImage(32, 32, ColorRgb8(0, 0, 0));
      final result = sketch(src.clone());
      final first = result.getPixel(0, 0);
      for (final p in result) {
        expect(p.r, equals(first.r), reason: 'r differs at ${p.x},${p.y}');
        expect(p.g, equals(first.g), reason: 'g differs at ${p.x},${p.y}');
        expect(p.b, equals(first.b), reason: 'b differs at ${p.x},${p.y}');
      }
    });

    test('sketch on a checker image produces non-uniform output', () {
      // A checkerboard has strong edges; the sketch output must not be flat.
      final src = checkerImage(64, 64);
      final result = sketch(src.clone());
      // Variance > 0 confirms the output is not uniform.
      expect(imageVariance(result), greaterThan(0));
    });

    test('sketch with amount 0 leaves image unchanged', () {
      final src = checkerImage(32, 32);
      // amount=0 → blend factor is 0 → output equals original
      testImageEquals(sketch(src.clone(), amount: 0), src);
    });
  });
}
