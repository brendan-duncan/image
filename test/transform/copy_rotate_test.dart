import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Transform', () {
    test('copyRotate', () {
      final img = decodePng(
        File('test/_data/png/buck_24.png').readAsBytesSync(),
      )!
        ..backgroundColor = ColorRgb8(255, 255, 255);
      for (var i = 0; i < 360; i += 45) {
        final i0 = copyRotate(img, angle: i);
        expect(i0.numChannels, equals(img.numChannels));
        File('$testOutputPath/transform/copyRotate_$i.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(encodePng(i0));
      }
    });

    // Rotating by 0 degrees returns an image equal to the source.
    test('angle 0 is identity', () {
      final src = quadrantImage(16, 16);
      testImageEquals(copyRotate(src, angle: 0), src);
    });

    // Rotating by 360 degrees is also identity.
    test('angle 360 is identity', () {
      final src = quadrantImage(16, 16);
      testImageEquals(copyRotate(src, angle: 360), src);
    });

    // For a 90-degree rotation, width and height are swapped.
    test('90-degree rotation swaps width and height', () {
      final src = Image(width: 20, height: 10);
      final r90 = copyRotate(src, angle: 90);
      expect(r90.width, equals(10));
      expect(r90.height, equals(20));
    });

    // For a 270-degree rotation, width and height are also swapped.
    test('270-degree rotation swaps width and height', () {
      final src = Image(width: 20, height: 10);
      final r270 = copyRotate(src, angle: 270);
      expect(r270.width, equals(10));
      expect(r270.height, equals(20));
    });

    // Rotating by 180 degrees preserves width and height.
    test('180-degree rotation preserves dimensions', () {
      final src = Image(width: 20, height: 10);
      final r180 = copyRotate(src, angle: 180);
      expect(r180.width, equals(20));
      expect(r180.height, equals(10));
    });

    // Rotating by 90 degrees four times returns an image equal to the source.
    test('four 90-degree rotations return to original', () {
      final src = quadrantImage(16, 16);
      var result = src;
      for (var i = 0; i < 4; i++) {
        result = copyRotate(result, angle: 90);
      }
      testImageEquals(result, src);
    });

    // Rotating by 90 then 270 degrees returns to the original.
    test('90 then 270 degrees returns to original', () {
      final src = quadrantImage(16, 16);
      final r90 = copyRotate(src, angle: 90);
      final back = copyRotate(r90, angle: 270);
      testImageEquals(back, src);
    });

    // Rotating by 180 twice is identity.
    test('two 180-degree rotations return to original', () {
      final src = quadrantImage(16, 16);
      testImageEquals(copyRotate(copyRotate(src, angle: 180), angle: 180), src);
    });

    // copyRotate does not mutate the source image.
    test('copyRotate does not mutate source', () {
      final src = quadrantImage(16, 16);
      final orig = src.clone();
      copyRotate(src, angle: 90);
      testImageEquals(src, orig);
    });

    // A 90-degree rotation moves a known corner pixel to the expected position.
    // _rotate90: dst(x,y) = src(y, h-1-x).
    // Solving for where src(0,0) lands: need y=0 and h-1-x=0 → x=h-1=15.
    // So src(0,0) (top-left, red) appears at dst(15,0) — the top-right corner.
    test('90-degree rotation moves top-left pixel to top-right', () {
      // TL=red, TR=green, BL=blue, BR=yellow, 16x16
      final src = quadrantImage(16, 16);
      final r90 = copyRotate(src, angle: 90);
      // src(0,0) red → dst(15,0): top-right corner of the 16x16 result.
      final p = r90.getPixel(15, 0);
      expect(p.r, equals(255), reason: 'red channel at top-right after 90°');
      expect(p.g, equals(0), reason: 'green channel at top-right after 90°');
      expect(p.b, equals(0), reason: 'blue channel at top-right after 90°');
    });
  });
}
